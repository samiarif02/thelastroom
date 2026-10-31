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

/**
 * The model that grades. Gemini 3.8 Flash: Google's strongest Flash model, and fast enough for
 * the app's 8 s wait (`gemini-4-argon` reasons longer than the player should wait). ADR 0006.
 */
export const GEMINI_MODEL = 'gemini-3.8-flash';

const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

/** How long the function waits for Gemini; the app gives up at 8 s, so this leaves headroom. */
export const GEMINI_TIMEOUT_MS = 7000;

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
export function requestBody(input: ScoreInput): Record<string, unknown> {
  return {
    systemInstruction: { parts: [{ text: systemInstruction(input) }] },
    contents: [{ role: 'user', parts: [{ text: answerTranscript(input) }] }],
    generationConfig: {
      temperature: 0,
      responseMimeType: 'application/json',
      responseSchema: RESPONSE_SCHEMA,
      maxOutputTokens: MAX_OUTPUT_TOKENS,
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
): Promise<Verdict> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  let response: Response;
  try {
    response = await fetchImpl(`${ENDPOINT}/${GEMINI_MODEL}:generateContent`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(requestBody(input)),
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
    result: parseVerdict(raw, GEMINI_MODEL),
    usage: { promptTokens: count(usage?.promptTokenCount), outputTokens: count(usage?.candidatesTokenCount) },
  };
}
