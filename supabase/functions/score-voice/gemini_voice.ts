// The one call to Gemini for a spoken answer: `models.generateContent` with the two recordings as
// inline audio and a JSON response schema. The model, the error type and the usage shape are the
// `score` function's (../score/gemini.ts), so both functions grade with the same judge.
// https://ai.google.dev/gemini-api/docs/audio and https://ai.google.dev/gemini-api/docs/structured-output

import { GEMINI_CHAIN, type GeminiModel, UpstreamError, type Usage } from '../score/gemini.ts';
import { OutputError, parseVerdict, promptParts, responseSchema, systemInstruction, type VoiceInput } from './voice.ts';
import type { VoiceResult } from './voice.ts';

const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * The voice chain: `score`'s models, in its order and with minimal thinking (the first live run
 * showed a thinking model timing out on the owner's key, brief 36), each given longer because it
 * listens to up to two 90 s takes. The total stays under the app's 30 s wait.
 */
export const VOICE_CHAIN: readonly GeminiModel[] = GEMINI_CHAIN.map((m, i) => ({
  ...m,
  timeoutMs: [11_000, 9_000, 7_000][i] ?? 7_000,
}));

/** How long one call waits when no model is given. */
export const VOICE_GEMINI_TIMEOUT_MS = VOICE_CHAIN[0].timeoutMs;

/** Two transcripts of up to ~1,500 characters, the point ids, five scores and five sentences. */
const MAX_OUTPUT_TOKENS = 4096;

export interface VoiceVerdict {
  result: VoiceResult;
  usage: Usage;
}

type Fetch = typeof fetch;

/** The `generateContent` body: instructions, the questions and points around the two clips. */
export function requestBody(
  input: VoiceInput,
  thinkingLevel: GeminiModel['thinkingLevel'] = VOICE_CHAIN[0].thinkingLevel,
): Record<string, unknown> {
  const parts = promptParts(input);
  return {
    systemInstruction: { parts: [{ text: systemInstruction(input) }] },
    contents: [{
      role: 'user',
      parts: [
        { text: parts.beforeAnswer },
        { inlineData: { mimeType: input.answer.mimeType, data: input.answer.base64 } },
        { text: parts.beforeReply },
        { inlineData: { mimeType: input.reply.mimeType, data: input.reply.base64 } },
        { text: parts.after },
      ],
    }],
    generationConfig: {
      temperature: 0,
      responseMimeType: 'application/json',
      responseSchema: responseSchema(input),
      maxOutputTokens: MAX_OUTPUT_TOKENS,
      thinkingConfig: { thinkingLevel },
    },
  };
}

function count(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/** Asks Gemini to transcribe and grade. The key goes in a header, never in the URL. */
export async function scoreVoiceWithGemini(
  input: VoiceInput,
  apiKey: string,
  fetchImpl: Fetch = fetch,
  timeoutMs = VOICE_GEMINI_TIMEOUT_MS,
  model: GeminiModel = VOICE_CHAIN[0],
): Promise<VoiceVerdict> {
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
    // The body may echo the request (the audio); only the status is kept.
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
    result: parseVerdict(raw, model.model, input),
    usage: { promptTokens: count(usage?.promptTokenCount), outputTokens: count(usage?.candidatesTokenCount) },
  };
}

/** Grades with the first model in [chain] that answers; the last failure is the one thrown. */
export async function scoreVoiceWithFallback(
  input: VoiceInput,
  apiKey: string,
  fetchImpl: Fetch = fetch,
  chain: readonly GeminiModel[] = VOICE_CHAIN,
): Promise<VoiceVerdict> {
  let last: unknown = new UpstreamError('no model to grade with');
  for (const model of chain) {
    try {
      return await scoreVoiceWithGemini(input, apiKey, fetchImpl, model.timeoutMs, model);
    } catch (error) {
      if (!(error instanceof UpstreamError) && !(error instanceof OutputError)) throw error;
      last = error;
    }
  }
  throw last;
}
