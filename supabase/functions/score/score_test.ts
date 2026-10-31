// Unit tests for the `score` function, with Gemini and the database faked: no key, no network.
// Run: deno test supabase/functions/score (or via Docker: see docs/status/22.md).

import { GEMINI_MODEL, requestBody, scoreWithGemini, UpstreamError, type Verdict } from './gemini.ts';
import { type Deps, handle, NotConfigured, Unauthorized } from './handler.ts';
import {
  answerTranscript,
  InputError,
  MAX_BASIS,
  OutputError,
  parseInput,
  parseVerdict,
  type ScoreInput,
  systemInstruction,
} from './scoring.ts';

function assert(condition: unknown, message = 'assertion failed'): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown, message = ''): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\nexpected ${e}\n  actual ${a}`);
}

async function assertRejects(fn: () => Promise<unknown>, type: new (...args: never[]) => Error): Promise<Error> {
  try {
    await fn();
  } catch (error) {
    assert(error instanceof type, `expected ${type.name}, got ${String(error)}`);
    return error;
  }
  throw new Error(`expected ${type.name}, nothing was thrown`);
}

const body = {
  mission_id: 'm01_the_opportunity',
  hiring_for: 'Product Associate (entry level)',
  interviewer_role: 'Recruiter',
  question: 'So, what made you apply for this role?',
  beats: [
    {
      kind: 'open',
      line: 'I like finding out why people get stuck.',
      reason: 'It answers what she asked.',
      guessed: false,
    },
    { kind: 'evidence', line: 'I interviewed twelve students.', reason: null, guessed: true },
    { kind: 'land', line: 'That is the work I want to do.', reason: 'It ties back to the job.', guessed: false },
  ],
  follow_up_question: 'What was your part?',
  reply: 'I ran all twelve interviews.',
  attempt_id: '0b9a8c7d-1e2f-4a3b-8c4d-5e6f7a8b9c0d',
};

const verdictJson = {
  relevance: { score: 82, basis: 'It answers why this role, not why any job.' },
  specificity: { score: 40, basis: 'The evidence was guessed, so no concrete fact counts.' },
  structure: { score: 70, basis: 'It opens and closes clearly around a weak middle.' },
  adaptability: { score: 90, basis: "The reply names the candidate's own part directly." },
  overall: { score: 68, basis: 'A relevant answer let down by unearned evidence.' },
};

function geminiResponse(text: string, extra: Record<string, unknown> = {}): Response {
  return new Response(
    JSON.stringify({
      candidates: [{ content: { role: 'model', parts: [{ text }] }, finishReason: 'STOP' }],
      usageMetadata: { promptTokenCount: 512, candidatesTokenCount: 140, totalTokenCount: 652 },
      ...extra,
    }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  );
}

// ---------------------------------------------------------------- input

Deno.test("parseInput accepts the app's request", () => {
  const input = parseInput(body);
  assertEquals(input.missionId, 'm01_the_opportunity');
  assertEquals(input.beats.length, 3);
  assertEquals(input.beats[1].reason, null);
  assertEquals(input.beats[1].guessed, true);
  assertEquals(input.attemptId, body.attempt_id);
});

Deno.test('parseInput rejects missing, malformed and oversized fields', () => {
  const bad: unknown[] = [
    null,
    'text',
    { ...body, mission_id: 'Not An Id' },
    { ...body, beats: [] },
    { ...body, beats: [...body.beats, body.beats[0]] },
    { ...body, beats: [{ ...body.beats[0], guessed: 'no' }] },
    { ...body, question: '' },
    { ...body, reply: 'x'.repeat(601) },
    { ...body, attempt_id: 'not-a-uuid' },
  ];
  for (const b of bad) {
    let threw = false;
    try {
      parseInput(b);
    } catch (error) {
      threw = error instanceof InputError;
    }
    assert(threw, `accepted ${JSON.stringify(b).slice(0, 80)}`);
  }
});

Deno.test('the prompt is a senior recruiter: graded, with a basis, never advice', () => {
  const input = parseInput(body);
  const system = systemInstruction(input);
  assert(system.startsWith('You are a senior recruiter hiring for: Product Associate (entry level).'));
  assert(system.includes('ONE short sentence of basis'));
  assert(system.includes('Do not give advice'));
  const transcript = answerTranscript(input);
  assert(transcript.includes('EVIDENCE [GUESSED]'), 'guessed beats are marked');
  assert(transcript.includes('Reason given: It answers what she asked.'));
  assert(!transcript.includes('Reason given: null'));
});

Deno.test('the request is deterministic JSON with the schema', () => {
  const req = requestBody(parseInput(body)) as { generationConfig: Record<string, unknown> };
  assertEquals(req.generationConfig.temperature, 0);
  assertEquals(req.generationConfig.responseMimeType, 'application/json');
  assert(req.generationConfig.responseSchema !== undefined);
});

// ---------------------------------------------------------------- output

Deno.test('parseVerdict reads a well-formed verdict', () => {
  const result = parseVerdict(JSON.stringify(verdictJson), GEMINI_MODEL);
  assertEquals(result.overall, verdictJson.overall);
  assertEquals(result.dimensions.specificity.score, 40);
  assertEquals(result.model, GEMINI_MODEL);
});

Deno.test('parseVerdict repairs: clamps, rounds, cuts a basis to one sentence, strips a fence', () => {
  const messy = {
    ...verdictJson,
    relevance: { score: 140, basis: 'Spot on. Also, here is some advice you did not ask for.' },
    structure: { score: 69.6, basis: '  Clear\n opening.  ' },
    adaptability: { score: '-5', basis: 'x'.repeat(400) },
  };
  const result = parseVerdict('```json\n' + JSON.stringify(messy) + '\n```', GEMINI_MODEL);
  assertEquals(result.dimensions.relevance, { score: 100, basis: 'Spot on.' });
  assertEquals(result.dimensions.structure, { score: 70, basis: 'Clear opening.' });
  assertEquals(result.dimensions.adaptability.score, 0);
  assertEquals(result.dimensions.adaptability.basis.length, MAX_BASIS);
});

Deno.test("parseVerdict rejects what it can't repair", () => {
  const broken = [
    'not json',
    '[]',
    JSON.stringify({ ...verdictJson, overall: undefined }),
    JSON.stringify({ ...verdictJson, structure: { score: 'high', basis: 'x.' } }),
    JSON.stringify({ ...verdictJson, relevance: { score: 50, basis: '   ' } }),
  ];
  for (const raw of broken) {
    let threw = false;
    try {
      parseVerdict(raw, GEMINI_MODEL);
    } catch (error) {
      threw = error instanceof OutputError;
    }
    assert(threw, `accepted ${raw.slice(0, 60)}`);
  }
});

// ---------------------------------------------------------------- Gemini (mocked)

Deno.test('scoreWithGemini sends the key in a header, never the URL, and reads usage', async () => {
  let seenUrl = '';
  let seenKey: string | null = null;
  const fake = ((url: string, init: RequestInit) => {
    seenUrl = url;
    seenKey = new Headers(init.headers).get('x-goog-api-key');
    return Promise.resolve(geminiResponse(JSON.stringify(verdictJson)));
  }) as unknown as typeof fetch;
  const { result, usage } = await scoreWithGemini(parseInput(body), 'test-key', fake);
  assert(seenUrl.endsWith(`/models/${GEMINI_MODEL}:generateContent`));
  assert(!seenUrl.includes('test-key'), 'the key is not in the URL');
  assertEquals(seenKey, 'test-key');
  assertEquals(result.overall.score, 68);
  assertEquals(usage, { promptTokens: 512, outputTokens: 140 });
});

Deno.test('scoreWithGemini: an error status, a block, a cut-off and a timeout are typed failures', async () => {
  const status = (() => Promise.resolve(new Response('{"error":{}}', { status: 429 }))) as unknown as typeof fetch;
  await assertRejects(() => scoreWithGemini(parseInput(body), 'k', status), UpstreamError);

  const blocked = (() =>
    Promise.resolve(
      new Response(JSON.stringify({ promptFeedback: { blockReason: 'SAFETY' } })),
    )) as unknown as typeof fetch;
  await assertRejects(() => scoreWithGemini(parseInput(body), 'k', blocked), UpstreamError);

  const truncated = (() =>
    Promise.resolve(
      new Response(JSON.stringify({
        candidates: [{ content: { parts: [{ text: '{"relev' }] }, finishReason: 'MAX_TOKENS' }],
      })),
    )) as unknown as typeof fetch;
  await assertRejects(() => scoreWithGemini(parseInput(body), 'k', truncated), OutputError);

  const hang = ((_url: string, init: RequestInit) =>
    new Promise((_resolve, reject) => {
      init.signal?.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')));
    })) as unknown as typeof fetch;
  const error = await assertRejects(() => scoreWithGemini(parseInput(body), 'k', hang, 20), UpstreamError);
  assert((error as UpstreamError).timedOut, 'a timeout is marked as one');
});

// ---------------------------------------------------------------- handler

function fakeDeps(overrides: Partial<Deps> = {}): Deps & { logs: Record<string, unknown>[]; saved: number } {
  const logs: Record<string, unknown>[] = [];
  const deps = {
    logs,
    saved: 0,
    score: (): Promise<Verdict> =>
      Promise.resolve({
        result: parseVerdict(JSON.stringify(verdictJson), GEMINI_MODEL),
        usage: { promptTokens: 10, outputTokens: 5 },
      }),
    claimQuota: () => Promise.resolve(true),
    saveScore() {
      deps.saved++;
      return Promise.resolve();
    },
    log: (fields: Record<string, unknown>) => logs.push(fields),
    now: () => 0,
    ...overrides,
  };
  return deps;
}

function post(payload: unknown, auth = 'Bearer player.jwt'): Request {
  return new Request('http://localhost/score', {
    method: 'POST',
    headers: { authorization: auth, 'content-type': 'application/json' },
    body: typeof payload === 'string' ? payload : JSON.stringify(payload),
  });
}

Deno.test('handle: a signed-in player gets the verdict; it is saved and its usage logged', async () => {
  const deps = fakeDeps();
  const res = await handle(post(body), deps);
  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.overall.score, 68);
  assertEquals(json.dimensions.relevance.basis, verdictJson.relevance.basis);
  assertEquals(deps.saved, 1);
  const usage = deps.logs.find((l) => l.event === 'ai_score');
  assert(usage !== undefined, 'usage is logged');
  assertEquals(usage.prompt_tokens, 10);
  const line = JSON.stringify(deps.logs);
  assert(!line.includes('player.jwt') && !line.includes('twelve'), 'no JWT or answer text in the log');
});

Deno.test('handle: no JWT, a refused JWT, a bad body and a spent quota are refused before Gemini', async () => {
  let scored = 0;
  const counting = {
    score: (input: ScoreInput) => {
      scored++;
      return fakeDeps().score(input);
    },
  };
  assertEquals((await handle(post(body, ''), fakeDeps(counting))).status, 401);
  assertEquals(
    (await handle(post(body), fakeDeps({ ...counting, claimQuota: () => Promise.reject(new Unauthorized()) }))).status,
    401,
  );
  assertEquals((await handle(post('{not json'), fakeDeps(counting))).status, 400);
  assertEquals((await handle(post({ ...body, beats: [] }), fakeDeps(counting))).status, 400);
  const limited = await handle(post(body), fakeDeps({ ...counting, claimQuota: () => Promise.resolve(false) }));
  assertEquals(limited.status, 429);
  assertEquals((await limited.json()).error, 'daily_limit_reached');
  assertEquals(scored, 0, 'Gemini was never called');
});

Deno.test('handle: Gemini failing is a typed error the app can fall back on', async () => {
  const cases: [Error, number, string][] = [
    [new UpstreamError('down'), 502, 'upstream_error'],
    [new UpstreamError('slow', true), 504, 'timeout'],
    [new OutputError('junk'), 502, 'bad_output'],
    [new NotConfigured(), 503, 'not_configured'],
  ];
  for (const [error, status, code] of cases) {
    const deps = fakeDeps({ score: () => Promise.reject(error) });
    const res = await handle(post(body), deps);
    assertEquals(res.status, status, code);
    assertEquals((await res.json()).error, code);
    assertEquals(deps.saved, 0);
  }
});

Deno.test('handle: a failed save still returns the verdict', async () => {
  const deps = fakeDeps({ saveScore: () => Promise.reject(new Error('insert answered 500')) });
  const res = await handle(post(body), deps);
  assertEquals(res.status, 200);
  assert(deps.logs.some((l) => l.event === 'ai_score_not_saved'));
});

Deno.test('handle: CORS preflight and other methods', async () => {
  assertEquals((await handle(new Request('http://localhost/score', { method: 'OPTIONS' }), fakeDeps())).status, 204);
  assertEquals((await handle(new Request('http://localhost/score', { method: 'GET' }), fakeDeps())).status, 405);
});

Deno.test('InputError and OutputError stay distinct', () => {
  assert(!(new InputError('x') instanceof OutputError));
});
