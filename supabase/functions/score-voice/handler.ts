// The `score-voice` function's request handling, with its outside world injected (Gemini, the
// database, the clock, the log), so the tests run it end to end with no network. It mirrors
// `score`'s handler: the same JWT rule, the same daily quota, the same error codes.

import { UpstreamError, type Usage } from '../score/gemini.ts';
import type { VoiceVerdict } from './gemini_voice.ts';
import { InputError, MAX_BODY_BYTES, OutputError, parseInput, type VoiceInput, type VoiceResult } from './voice.ts';

export interface Deps {
  /** Transcribes and grades (Gemini in production, a fake in tests). */
  score(input: VoiceInput): Promise<VoiceVerdict>;
  /** Takes one of the caller's daily AI scores, as the caller; `false` when they're spent. */
  claimQuota(jwt: string): Promise<boolean>;
  /** Stores the verdict and transcript as the caller (owner-only RLS). Never the audio. */
  saveScore(jwt: string, input: VoiceInput, result: VoiceResult): Promise<void>;
  /** One structured log line. Never the key, the JWT, the audio or any transcript. */
  log(fields: Record<string, unknown>): void;
  now(): number;
}

export class Unauthorized extends Error {}
export class NotConfigured extends Error {}

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, apikey, content-type, x-client-info',
  'access-control-allow-methods': 'POST, OPTIONS',
};

function reply(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'content-type': 'application/json' },
  });
}

function fail(status: number, error: string): Response {
  return reply(status, { error });
}

function bearer(req: Request): string | null {
  const header = req.headers.get('authorization') ?? '';
  const match = header.match(/^Bearer\s+(\S+)$/i);
  return match ? match[1] : null;
}

/** The app's view of the result: snake_case, like every other row it reads. */
function wire(result: VoiceResult): Record<string, unknown> {
  return {
    model: result.model,
    transcript: result.transcript,
    points_made: result.pointsMade,
    overall: result.overall,
    dimensions: result.dimensions,
  };
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method !== 'POST') return fail(405, 'method_not_allowed');

  const jwt = bearer(req);
  if (jwt === null) return fail(401, 'unauthorized');

  const length = Number(req.headers.get('content-length') ?? '0');
  if (length > MAX_BODY_BYTES) {
    await req.body?.cancel();
    return fail(413, 'too_large');
  }

  let input: VoiceInput;
  try {
    const raw = await req.text();
    if (raw.length > MAX_BODY_BYTES) return fail(413, 'too_large');
    input = parseInput(JSON.parse(raw));
  } catch (error) {
    if (error instanceof InputError || error instanceof SyntaxError) return fail(400, 'invalid_request');
    throw error;
  }

  try {
    if (!(await deps.claimQuota(jwt))) {
      deps.log({ event: 'ai_score_rate_limited', mission: input.missionId });
      return fail(429, 'daily_limit_reached');
    }
  } catch (error) {
    if (error instanceof Unauthorized) return fail(401, 'unauthorized');
    throw error;
  }

  const started = deps.now();
  let verdict: VoiceVerdict;
  try {
    verdict = await deps.score(input);
  } catch (error) {
    const ms = deps.now() - started;
    if (error instanceof NotConfigured) {
      deps.log({ event: 'voice_score_failed', reason: 'not_configured', mission: input.missionId });
      return fail(503, 'not_configured');
    }
    if (error instanceof UpstreamError) {
      deps.log({
        event: 'voice_score_failed',
        reason: error.timedOut ? 'timeout' : 'upstream',
        detail: error.message,
        ms,
        mission: input.missionId,
      });
      return fail(error.timedOut ? 504 : 502, error.timedOut ? 'timeout' : 'upstream_error');
    }
    if (error instanceof OutputError) {
      deps.log({
        event: 'voice_score_failed',
        reason: 'bad_output',
        detail: error.message,
        ms,
        mission: input.missionId,
      });
      return fail(502, 'bad_output');
    }
    throw error;
  }

  logUsage(deps, input, verdict.usage, deps.now() - started, verdict.result);
  try {
    await deps.saveScore(jwt, input, verdict.result);
  } catch (error) {
    deps.log({
      event: 'voice_score_not_saved',
      detail: error instanceof Error ? error.message : 'error',
      mission: input.missionId,
    });
  }
  return reply(200, wire(verdict.result));
}

function logUsage(deps: Deps, input: VoiceInput, usage: Usage, ms: number, result: VoiceResult): void {
  deps.log({
    event: 'voice_score',
    model: result.model,
    mission: input.missionId,
    audio_bytes: input.answer.bytes + input.reply.bytes,
    points_made: result.pointsMade.length,
    prompt_tokens: usage.promptTokens,
    output_tokens: usage.outputTokens,
    ms,
  });
}
