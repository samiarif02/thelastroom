// The one call to Google's Gemini API: `models.generateContent` with a JSON response schema.
// https://ai.google.dev/api/generate-content and https://ai.google.dev/gemini-api/docs/structured-output

import {
  answerTranscript,
  OutputError,
  parseVerdict,
  RESPONSE_SCHEMA,
  type ScoreInput,
  type ScoreResult,
  systemInstruction,
} from './scoring.ts';

/** One model the function may grade with, and how long it gets. */
export interface GeminiModel {
  model: string;
  /** Gemini 3's thinking level: `minimal` keeps a verdict to a second or two. */
  thinkingLevel: 'minimal' | 'low';
  timeoutMs: number;
}

/**
 * The models that grade, tried in order: the next one only when the one before is overloaded,
 * fails or runs out of time. Measured live with the owner's key on 2026-11-02 (brief 36):
 * `gemini-3.8-flash` answered 503 "high demand" or took 30 s+ and doesn't allow minimal
 * thinking; `gemini-3.6-flash` with minimal thinking answered in ~1.7 s and
 * `gemini-3.1-flash-lite` in ~1.3–2.7 s. The two timeouts add up to under the app's 8 s wait.
 * ADR 0006 (amended).
 */
export const GEMINI_CHAIN: readonly GeminiModel[] = [
  { model: 'gemini-3.6-flash', thinkingLevel: 'minimal', timeoutMs: 14000 },
  { model: 'gemini-3.1-flash-lite', thinkingLevel: 'minimal', timeoutMs: 10000 },
];

/** The first model in [GEMINI_CHAIN]: what a verdict normally records as its grader. */
export const GEMINI_MODEL = GEMINI_CHAIN[0].model;

const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

/** How long one call waits when no model is given; the chain sets its own (above). */
export const GEMINI_TIMEOUT_MS = GEMINI_CHAIN[0].timeoutMs;

/** Room for five scores and five one-sentence bases, and nothing else. */
const MAX_OUTPUT_TOKENS = 1024;

/** Token counts for the usage log (never the text). */
export interface Usage {
  promptTokens: number;
  outputTokens: number;
}

export interface Verdict {
  result: ScoreResult;
  usage: Usage;
}

/** Gemini answered with an error status, blocked the prompt, or timed out. Answered with 502/504. */
export class UpstreamError extends Error {
  constructor(message: string, readonly timedOut = false) {
    super(message);
  }
}

type Fetch = typeof fetch;

/** The `generateContent` body: the panel's instructions, the transcript, deterministic JSON. */
export function requestBody(
  input: ScoreInput,
  thinkingLevel: GeminiModel['thinkingLevel'] = GEMINI_CHAIN[0].thinkingLevel,
): Record<string, unknown> {
  return {
    systemInstruction: { parts: [{ text: systemInstruction(input) }] },
    contents: [{ role: 'user', parts: [{ text: answerTranscript(input) }] }],
    generationConfig: {
      temperature: 0,
      responseMimeType: 'application/json',
      responseSchema: RESPONSE_SCHEMA,
      maxOutputTokens: MAX_OUTPUT_TOKENS,
      thinkingConfig: { thinkingLevel },
    },
  };
}

function count(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/**
 * Asks Gemini for the verdict. The key goes in the `x-goog-api-key` header, never in the URL, so
 * it can't end up in a request log.
 */
export async function scoreWithGemini(
  input: ScoreInput,
  apiKey: string,
  fetchImpl: Fetch = fetch,
  timeoutMs = GEMINI_TIMEOUT_MS,
  model: GeminiModel = GEMINI_CHAIN[0],
): Promise<Verdict> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  let response: Response;
  try {
    response = await fetchImpl(`${ENDPOINT}/${model.model}:generateContent`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(requestBody(input, model.thinkingLevel)),
      signal: controller.signal,
    });
  } catch (error) {
    if (controller.signal.aborted) throw new UpstreamError('gemini timed out', true);
    throw new UpstreamError(`gemini unreachable: ${error instanceof Error ? error.name : 'error'}`);
  } finally {
    clearTimeout(timer);
  }
  if (!response.ok) {
    // The body may echo the request; only the status is kept.
    await response.body?.cancel();
    throw new UpstreamError(`gemini answered ${response.status}`);
  }
  const data = (await response.json()) as Record<string, unknown>;
  const feedback = data.promptFeedback as Record<string, unknown> | undefined;
  if (feedback?.blockReason) throw new UpstreamError(`gemini blocked the prompt: ${String(feedback.blockReason)}`);
  const candidate = (data.candidates as Record<string, unknown>[] | undefined)?.[0];
  const finish = candidate?.finishReason;
  if (finish !== undefined && finish !== 'STOP') throw new OutputError(`gemini stopped: ${String(finish)}`);
  const parts = (candidate?.content as Record<string, unknown> | undefined)?.parts as
    | Record<string, unknown>[]
    | undefined;
  const raw = parts?.map((p) => (typeof p.text === 'string' ? p.text : '')).join('') ?? '';
  if (raw === '') throw new OutputError('gemini returned no text');
  const usage = data.usageMetadata as Record<string, unknown> | undefined;
  return {
    result: parseVerdict(raw, model.model),
    usage: { promptTokens: count(usage?.promptTokenCount), outputTokens: count(usage?.candidatesTokenCount) },
  };
}

/**
 * Grades with the first model in [chain] that answers: an overloaded, failing or slow model
 * hands over to the next. The last model's failure is the one thrown.
 */
export async function scoreWithFallback(
  input: ScoreInput,
  apiKey: string,
  fetchImpl: Fetch = fetch,
  chain: readonly GeminiModel[] = GEMINI_CHAIN,
): Promise<Verdict> {
  let last: unknown = new UpstreamError('no model to grade with');
  for (const model of chain) {
    try {
      return await scoreWithGemini(input, apiKey, fetchImpl, model.timeoutMs, model);
    } catch (error) {
      if (!(error instanceof UpstreamError) && !(error instanceof OutputError)) throw error;
      last = error;
    }
  }
  throw last;
}
