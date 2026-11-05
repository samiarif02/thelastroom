// Unit tests for the `score-voice` function, with Gemini and the database faked: no key, no
// network. Run: deno test supabase/functions/score-voice (or the Docker line in local-review).

import { GEMINI_MODEL, UpstreamError } from '../score/gemini.ts';
import { scoreVoiceWithFallback, VOICE_CHAIN } from './gemini_voice.ts';
import { requestBody, scoreVoiceWithGemini, type VoiceVerdict } from './gemini_voice.ts';
import { type Deps, handle, NotConfigured, Unauthorized } from './handler.ts';
import {
  InputError,
  MAX_AUDIO_BYTES,
  MAX_BASIS,
  MAX_BODY_BYTES,
  MAX_TRANSCRIPT,
  OutputError,
  parseInput,
  parseVerdict,
  promptParts,
  responseSchema,
  storedTranscript,
  systemInstruction,
  type VoiceInput,
} from './voice.ts';

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

const SAMPLE_RATE = 16000;
const BYTES_PER_SAMPLE = 2;

/** A silent 16 kHz mono 16-bit WAV of [seconds], base64, as the app sends it. */
function wav(seconds: number): string {
  const data = Math.round(seconds * SAMPLE_RATE * BYTES_PER_SAMPLE);
  const bytes = new Uint8Array(44 + data);
  const view = new DataView(bytes.buffer);
  const ascii = (at: number, s: string) => [...s].forEach((c, i) => view.setUint8(at + i, c.charCodeAt(0)));
  ascii(0, 'RIFF');
  view.setUint32(4, 36 + data, true);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, SAMPLE_RATE, true);
  view.setUint32(28, SAMPLE_RATE * BYTES_PER_SAMPLE, true);
  view.setUint16(32, BYTES_PER_SAMPLE, true);
  view.setUint16(34, 16, true);
  ascii(36, 'data');
  view.setUint32(40, data, true);
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
}

const answerAudio = wav(2);
const replyAudio = wav(1);

const body = {
  mission_id: 'm08_team_conflict',
  hiring_for: 'Product Associate at Northstar Labs (entry level)',
  interviewer_role: 'Hiring Manager',
  question: 'Tell me about a time a plan changed under you.',
  listen_for: [
    { id: 'm08_names_change', text: 'Names what changed and when', dimension: 'relevance' },
    { id: 'm08_own_part', text: 'Says what they did, not the team', dimension: 'specificity' },
    { id: 'm08_result', text: 'Lands on a result with a number', dimension: 'structure' },
  ],
  follow_up_question: 'What would you do differently?',
  follow_up_listen_for: [
    { id: 'm08_owns_it', text: 'Names one thing they would change', dimension: 'adaptability' },
  ],
  answer_audio: answerAudio,
  reply_audio: replyAudio,
  mime_type: 'audio/wav',
  max_seconds: 90,
  attempt_id: '0b9a8c7d-1e2f-4a3b-8c4d-5e6f7a8b9c0d',
};

const verdictJson = {
  answer_transcript: 'The deadline moved up a week, so I re-planned the survey myself and we shipped on time.',
  reply_transcript: 'I would check the timeline with the client sooner.',
  points_made: ['m08_names_change', 'm08_own_part', 'm08_owns_it'],
  relevance: { score: 85, basis: 'It names the change and when it happened.' },
  specificity: { score: 70, basis: 'It says what the candidate did themselves.' },
  structure: { score: 45, basis: 'It ends without a measured result.' },
  adaptability: { score: 80, basis: 'The reply names one concrete change.' },
  overall: { score: 71, basis: 'A clear, owned answer that stops short of its result.' },
};

function geminiResponse(text: string): Response {
  return new Response(
    JSON.stringify({
      candidates: [{ content: { role: 'model', parts: [{ text }] }, finishReason: 'STOP' }],
      usageMetadata: { promptTokenCount: 2100, candidatesTokenCount: 230 },
    }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  );
}

// ---------------------------------------------------------------- input

Deno.test("parseInput accepts the app's request and measures the audio", () => {
  const input = parseInput(body);
  assertEquals(input.missionId, 'm08_team_conflict');
  assertEquals(input.listenFor.length, 3);
  assertEquals(input.followUpListenFor[0].dimension, 'adaptability');
  assertEquals(input.answer.bytes, 44 + 2 * SAMPLE_RATE * BYTES_PER_SAMPLE);
  assertEquals(input.answer.mimeType, 'audio/wav');
  assertEquals(input.attemptId, body.attempt_id);
});

Deno.test('parseInput rejects missing, malformed, oversized and over-long fields', () => {
  const bad: unknown[] = [
    null,
    { ...body, mission_id: 'Not An Id' },
    { ...body, listen_for: body.listen_for.slice(0, 2) },
    { ...body, follow_up_listen_for: [] },
    { ...body, listen_for: [{ ...body.listen_for[0], dimension: 'accent' }, ...body.listen_for.slice(1)] },
    { ...body, follow_up_listen_for: [body.listen_for[0]] },
    { ...body, mime_type: 'video/mp4' },
    { ...body, answer_audio: '' },
    { ...body, answer_audio: 'not base64!' },
    { ...body, answer_audio: btoa('RIFX'.padEnd(60, ' ')) },
    { ...body, max_seconds: 5 },
    { ...body, max_seconds: 10, answer_audio: wav(12) },
    { ...body, attempt_id: 'nope' },
  ];
  for (const b of bad) {
    let threw = false;
    try {
      parseInput(b);
    } catch (error) {
      threw = error instanceof InputError;
    }
    assert(threw, `accepted ${JSON.stringify(b).slice(0, 120)}`);
  }
});

Deno.test('parseInput caps the size of a clip', () => {
  const big = 'A'.repeat(Math.ceil((MAX_AUDIO_BYTES + 3) / 3) * 4);
  let threw = false;
  try {
    parseInput({ ...body, mime_type: 'audio/ogg', answer_audio: big });
  } catch (error) {
    threw = error instanceof InputError && error.message.includes('too large');
  }
  assert(threw, 'an oversized clip is refused');
});

Deno.test('the prompt scores content, never accent or how it sounds', () => {
  const input = parseInput(body);
  const system = systemInstruction(input);
  assert(system.startsWith('You are a senior recruiter hiring for: Product Associate'));
  assert(system.includes('NEVER score or mention accent, pronunciation'));
  assert(system.includes('ONE short sentence of basis'));
  assert(system.includes('Do not give advice'));
  const parts = promptParts(input);
  assert(parts.beforeAnswer.includes('- m08_own_part (specificity): Says what they did, not the team'));
  assert(parts.beforeReply.startsWith('Follow-up: What would you do differently?'));
});

Deno.test('the request is deterministic JSON, with both clips inline and the point ids as an enum', () => {
  const input = parseInput(body);
  const req = requestBody(input) as {
    contents: { parts: Record<string, unknown>[] }[];
    generationConfig: Record<string, unknown>;
  };
  assertEquals(req.generationConfig.temperature, 0);
  assertEquals(req.generationConfig.responseMimeType, 'application/json');
  const audio = req.contents[0].parts.filter((p) => 'inlineData' in p);
  assertEquals(audio.length, 2);
  assertEquals((audio[0].inlineData as Record<string, unknown>).data, answerAudio);
  const schema = responseSchema(input) as { properties: { points_made: { items: { enum: string[] } } } };
  assertEquals(schema.properties.points_made.items.enum, [
    'm08_names_change',
    'm08_own_part',
    'm08_result',
    'm08_owns_it',
  ]);
});

// ---------------------------------------------------------------- output

Deno.test('parseVerdict reads a well-formed verdict', () => {
  const input = parseInput(body);
  const result = parseVerdict(JSON.stringify(verdictJson), GEMINI_MODEL, input);
  assertEquals(result.pointsMade, ['m08_names_change', 'm08_own_part', 'm08_owns_it']);
  assertEquals(result.transcript.reply, verdictJson.reply_transcript);
  assertEquals(result.dimensions.structure.score, 45);
  assertEquals(result.overall.score, 71);
});

Deno.test('parseVerdict repairs: unknown and repeated ids, scores, bases, long transcripts', () => {
  const input = parseInput(body);
  const messy = {
    ...verdictJson,
    answer_transcript: '  I   re-planned\n it. ' + 'x'.repeat(MAX_TRANSCRIPT * 2),
    points_made: ['m08_owns_it', 'made_up', 'm08_names_change', 'm08_owns_it', 7],
    relevance: { score: 140, basis: 'Spot on. Also some advice.' },
    adaptability: { score: '-5', basis: 'y'.repeat(400) },
  };
  const result = parseVerdict('```json\n' + JSON.stringify(messy) + '\n```', GEMINI_MODEL, input);
  assertEquals(result.pointsMade, ['m08_names_change', 'm08_owns_it'], 'content order, known ids only');
  assertEquals(result.dimensions.relevance, { score: 100, basis: 'Spot on.' });
  assertEquals(result.dimensions.adaptability.score, 0);
  assertEquals(result.dimensions.adaptability.basis.length, MAX_BASIS);
  assertEquals(result.transcript.answer.length, MAX_TRANSCRIPT);
  assert(result.transcript.answer.startsWith('I re-planned it.'));
});

Deno.test("parseVerdict rejects what it can't repair", () => {
  const input = parseInput(body);
  const broken = [
    'not json',
    JSON.stringify({ ...verdictJson, points_made: undefined }),
    JSON.stringify({ ...verdictJson, answer_transcript: 3 }),
    JSON.stringify({ ...verdictJson, overall: undefined }),
    JSON.stringify({ ...verdictJson, structure: { score: 'high', basis: 'x.' } }),
  ];
  for (const raw of broken) {
    let threw = false;
    try {
      parseVerdict(raw, GEMINI_MODEL, input);
    } catch (error) {
      threw = error instanceof OutputError;
    }
    assert(threw, `accepted ${raw.slice(0, 60)}`);
  }
});

Deno.test('the stored transcript labels both parts, and an empty take stores none', () => {
  const input = parseInput(body);
  const result = parseVerdict(JSON.stringify(verdictJson), GEMINI_MODEL, input);
  assertEquals(
    storedTranscript(result),
    `Answer: ${verdictJson.answer_transcript}\nReply: ${verdictJson.reply_transcript}`,
  );
  const silent = parseVerdict(
    JSON.stringify({ ...verdictJson, answer_transcript: ' ', reply_transcript: '' }),
    GEMINI_MODEL,
    input,
  );
  assertEquals(storedTranscript(silent), null);
});

// ---------------------------------------------------------------- Gemini (mocked)

Deno.test('scoreVoiceWithGemini uses the score model, sends the key in a header, reads usage', async () => {
  let seenUrl = '';
  let seenKey: string | null = null;
  const fake = ((url: string, init: RequestInit) => {
    seenUrl = url;
    seenKey = new Headers(init.headers).get('x-goog-api-key');
    return Promise.resolve(geminiResponse(JSON.stringify(verdictJson)));
  }) as unknown as typeof fetch;
  const { result, usage } = await scoreVoiceWithGemini(parseInput(body), 'test-key', fake);
  assert(seenUrl.endsWith(`/models/${GEMINI_MODEL}:generateContent`));
  assert(!seenUrl.includes('test-key'), 'the key is not in the URL');
  assertEquals(seenKey, 'test-key');
  assertEquals(result.overall.score, 71);
  assertEquals(usage, { promptTokens: 2100, outputTokens: 230 });
});

Deno.test('scoreVoiceWithGemini: an error status, a block, a cut-off and a timeout are typed failures', async () => {
  const input = parseInput(body);
  const status = (() => Promise.resolve(new Response('{}', { status: 500 }))) as unknown as typeof fetch;
  await assertRejects(() => scoreVoiceWithGemini(input, 'k', status), UpstreamError);
  const blocked = (() =>
    Promise.resolve(
      new Response(JSON.stringify({ promptFeedback: { blockReason: 'SAFETY' } })),
    )) as unknown as typeof fetch;
  await assertRejects(() => scoreVoiceWithGemini(input, 'k', blocked), UpstreamError);
  const truncated = (() =>
    Promise.resolve(
      new Response(
        JSON.stringify({ candidates: [{ content: { parts: [{ text: '{' }] }, finishReason: 'MAX_TOKENS' }] }),
      ),
    )) as unknown as typeof fetch;
  await assertRejects(() => scoreVoiceWithGemini(input, 'k', truncated), OutputError);
  const hang = ((_url: string, init: RequestInit) =>
    new Promise((_resolve, reject) => {
      init.signal?.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')));
    })) as unknown as typeof fetch;
  const error = await assertRejects(() => scoreVoiceWithGemini(input, 'k', hang, 20), UpstreamError);
  assert((error as UpstreamError).timedOut, 'a timeout is marked as one');
});

// ---------------------------------------------------------------- handler

type FakeDeps = Deps & { logs: Record<string, unknown>[]; saved: VoiceInput[]; savedFor: string[] };

const CALLER = 'aaaaaaaa-0000-4000-8000-00000000000a';

function fakeDeps(overrides: Partial<Deps> = {}): FakeDeps {
  const deps: FakeDeps = {
    logs: [],
    saved: [],
    savedFor: [],
    callerId: () => Promise.resolve(CALLER),
    score: (input: VoiceInput): Promise<VoiceVerdict> =>
      Promise.resolve({
        result: parseVerdict(JSON.stringify(verdictJson), GEMINI_MODEL, input),
        usage: { promptTokens: 10, outputTokens: 5 },
      }),
    claimQuota: () => Promise.resolve(true),
    saveScore(userId, input) {
      deps.saved.push(input);
      deps.savedFor.push(userId);
      return Promise.resolve();
    },
    log: (fields: Record<string, unknown>) => deps.logs.push(fields),
    now: () => 0,
    ...overrides,
  };
  return deps;
}

function post(payload: unknown, auth = 'Bearer player.jwt', headers: Record<string, string> = {}): Request {
  return new Request('http://localhost/score-voice', {
    method: 'POST',
    headers: { authorization: auth, 'content-type': 'application/json', ...headers },
    body: typeof payload === 'string' ? payload : JSON.stringify(payload),
  });
}

Deno.test('handle: the player gets the transcript, the points and the scores; nothing audible is logged', async () => {
  const deps = fakeDeps();
  const res = await handle(post(body), deps);
  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.points_made, verdictJson.points_made);
  assertEquals(json.transcript.answer, verdictJson.answer_transcript);
  assertEquals(json.dimensions.relevance.basis, verdictJson.relevance.basis);
  assertEquals(deps.saved.length, 1);
  const line = JSON.stringify(deps.logs);
  assert(!line.includes('player.jwt'), 'no JWT in the log');
  assert(!line.includes('re-planned') && !line.includes(answerAudio.slice(60, 120)), 'no transcript or audio');
  const usage = deps.logs.find((l) => l.event === 'voice_score');
  assert(usage !== undefined, 'usage is logged');
  assertEquals(usage.points_made, 3);
});

Deno.test('handle: no JWT, a refused JWT, a bad body, a huge body and a spent quota never reach Gemini', async () => {
  let scored = 0;
  const counting = {
    score: (input: VoiceInput) => {
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
  assertEquals((await handle(post({ ...body, reply_audio: null }), fakeDeps(counting))).status, 400);
  const huge = await handle(
    post(body, undefined, { 'content-length': String(MAX_BODY_BYTES + 1) }),
    fakeDeps(counting),
  );
  assertEquals(huge.status, 413);
  const limited = await handle(post(body), fakeDeps({ ...counting, claimQuota: () => Promise.resolve(false) }));
  assertEquals(limited.status, 429);
  assertEquals((await limited.json()).error, 'daily_limit_reached');
  assertEquals(scored, 0, 'Gemini was never called');
});

Deno.test('handle: Gemini failing is a typed error the app falls back on (the self-check)', async () => {
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
    assertEquals(deps.saved.length, 0);
  }
});

Deno.test('handle: a failed save still returns the verdict', async () => {
  const deps = fakeDeps({ saveScore: () => Promise.reject(new Error('insert answered 500')) });
  const res = await handle(post(body), deps);
  assertEquals(res.status, 200);
  assert(deps.logs.some((l) => l.event === 'voice_score_not_saved'));
});

Deno.test("handle: saved for the JWT's user only; a bad JWT or made-up room never scores", async () => {
  const deps = fakeDeps();
  assertEquals((await handle(post({ ...body, user_id: 'bbbbbbbb-0000-4000-8000-00000000000b' }), deps)).status, 200);
  assertEquals(deps.savedFor, [CALLER]);
  const refused = fakeDeps({ callerId: () => Promise.reject(new Unauthorized()) });
  assertEquals((await handle(post(body), refused)).status, 401);
  assertEquals(refused.saved.length, 0);
  for (const missionId of ['m99_made_up', 'm01_the_opportunity']) {
    assertEquals((await handle(post({ ...body, mission_id: missionId }), fakeDeps())).status, 400, missionId);
  }
});

Deno.test('handle: a chunked body with no content-length is cut off at the cap', async () => {
  const chunk = new Uint8Array(1_000_000);
  let pulled = 0;
  const stream = new ReadableStream<Uint8Array>({
    pull(controller) {
      pulled++;
      controller.enqueue(chunk);
    },
  });
  const req = new Request('http://localhost/x', {
    method: 'POST',
    headers: { authorization: 'Bearer player.jwt' },
    body: stream,
  });
  assertEquals((await handle(req, fakeDeps())).status, 413);
  assert(pulled <= 14, `read ${pulled} MB`);
});

Deno.test('handle: an unexpected failure is a bare 500 with CORS', async () => {
  const res = await handle(post(body), fakeDeps({ claimQuota: () => Promise.reject(new Error('boom')) }));
  assertEquals(res.status, 500);
  assertEquals(await res.json(), { error: 'internal_error' });
  assertEquals(res.headers.get('access-control-allow-origin'), '*');
});

Deno.test('handle: CORS preflight and other methods', async () => {
  assertEquals((await handle(new Request('http://localhost/x', { method: 'OPTIONS' }), fakeDeps())).status, 204);
  assertEquals((await handle(new Request('http://localhost/x', { method: 'GET' }), fakeDeps())).status, 405);
});

Deno.test("scoreVoiceWithFallback: a busy model hands over; the chain fits the app's 30 s wait", async () => {
  const seen: string[] = [];
  const fake = ((url: string, init: RequestInit) => {
    seen.push(url.split('/models/')[1].split(':')[0]);
    const body = JSON.parse(String(init.body));
    assertEquals(body.generationConfig.thinkingConfig, { thinkingLevel: 'minimal' });
    return Promise.resolve(
      seen.length === 1 ? new Response('{}', { status: 429 }) : geminiResponse(JSON.stringify(verdictJson)),
    );
  }) as unknown as typeof fetch;
  const { result } = await scoreVoiceWithFallback(parseInput(body), 'k', fake);
  assertEquals(seen, VOICE_CHAIN.slice(0, 2).map((m) => m.model));
  assertEquals(result.model, VOICE_CHAIN[1].model);
  assert(VOICE_CHAIN.reduce((sum, m) => sum + m.timeoutMs, 0) < 30_000);
});
