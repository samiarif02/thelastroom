// The `score` function's request handling, with its outside world injected (Gemini, the
// database, the clock for timing, the log), so the tests run it end to end with no network.

import { UpstreamError, type Usage, type Verdict } from './gemini.ts';
import { InputError, MAX_BODY_BYTES, OutputError, parseInput, type ScoreInput, type ScoreResult } from './scoring.ts';

/** What the handler needs from outside. */
export interface Deps {
  /** Grades the answer (Gemini in production, a fake in tests). */
  score(input: ScoreInput): Promise<Verdict>;
  /**
   * The user id the auth server says [jwt] belongs to (a signed, unexpired, unrevoked session);
   * rejects with [Unauthorized] otherwise. The only source of the id a verdict is stored under:
   * never the request body (issue 74).
   */
  callerId(jwt: string): Promise<string>;
  /**
   * Takes one of the caller's daily scores, as the caller (their JWT). Resolves `true` when one
   * was left, `false` when the day's quota is spent; rejects with [Unauthorized] for a bad JWT.
   */
  claimQuota(jwt: string): Promise<boolean>;
  /**
   * Stores the verdict for [userId] with the service role: only the server writes `ai_scores`,
   * and the leaderboard counts only those (issue 74). Failures are logged, never returned.
   */
  saveScore(userId: string, input: ScoreInput, result: ScoreResult): Promise<void>;
  /** One structured log line. Never the key, the JWT or any answer text. */
  log(fields: Record<string, unknown>): void;
  now(): number;
}

/** The JWT was missing or the database refused it. */
export class Unauthorized extends Error {}

/** A request without an API key configured: the server isn't set up for AI scoring. */
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

/** The app reads `error` as a code; it never shows it to the player. */
function fail(status: number, error: string): Response {
  return reply(status, { error });
}

function bearer(req: Request): string | null {
  const header = req.headers.get('authorization') ?? '';
  const match = header.match(/^Bearer\s+(\S+)$/i);
  return match ? match[1] : null;
}

/**
 * The function's response for [req]. Anything unexpected is a logged 500 with a bare code (and
 * the CORS headers, so the web build reads it), never a stack or a message.
 */
export async function handle(req: Request, deps: Deps): Promise<Response> {
  try {
    return await route(req, deps);
  } catch (error) {
    deps.log({ event: 'ai_score_failed', reason: 'internal', detail: error instanceof Error ? error.name : 'error' });
    return fail(500, 'internal_error');
  }
}

async function route(req: Request, deps: Deps): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method !== 'POST') return fail(405, 'method_not_allowed');

  const jwt = bearer(req);
  if (jwt === null) return fail(401, 'unauthorized');

  if (Number(req.headers.get('content-length') ?? '0') > MAX_BODY_BYTES) {
    await req.body?.cancel();
    return fail(413, 'too_large');
  }

  let input: ScoreInput;
  try {
    const raw = await req.text();
    if (raw.length > MAX_BODY_BYTES) return fail(413, 'too_large');
    input = parseInput(JSON.parse(raw));
  } catch (error) {
    if (error instanceof InputError || error instanceof SyntaxError) {
      return fail(400, 'invalid_request');
    }
    throw error;
  }

  let userId: string;
  try {
    userId = await deps.callerId(jwt);
    if (!(await deps.claimQuota(jwt))) {
      deps.log({ event: 'ai_score_rate_limited', mission: input.missionId });
      return fail(429, 'daily_limit_reached');
    }
  } catch (error) {
    if (error instanceof Unauthorized) return fail(401, 'unauthorized');
    throw error;
  }

  const started = deps.now();
  let verdict: Verdict;
  try {
    verdict = await deps.score(input);
  } catch (error) {
    const ms = deps.now() - started;
    if (error instanceof NotConfigured) {
      deps.log({ event: 'ai_score_failed', reason: 'not_configured', mission: input.missionId });
      return fail(503, 'not_configured');
    }
    if (error instanceof UpstreamError) {
      deps.log({
        event: 'ai_score_failed',
        reason: error.timedOut ? 'timeout' : 'upstream',
        detail: error.message,
        ms,
        mission: input.missionId,
      });
      return fail(error.timedOut ? 504 : 502, error.timedOut ? 'timeout' : 'upstream_error');
    }
    if (error instanceof OutputError) {
      deps.log({ event: 'ai_score_failed', reason: 'bad_output', detail: error.message, ms, mission: input.missionId });
      return fail(502, 'bad_output');
    }
    throw error;
  }

  logUsage(deps, input, verdict.usage, deps.now() - started, verdict.result.model);
  try {
    await deps.saveScore(userId, input, verdict.result);
  } catch (error) {
    deps.log({
      event: 'ai_score_not_saved',
      detail: error instanceof Error ? error.message : 'error',
      mission: input.missionId,
    });
  }
  return reply(200, verdict.result);
}

function logUsage(deps: Deps, input: ScoreInput, usage: Usage, ms: number, model: string): void {
  deps.log({
    event: 'ai_score',
    model,
    mission: input.missionId,
    prompt_tokens: usage.promptTokens,
    output_tokens: usage.outputTokens,
    ms,
  });
}
