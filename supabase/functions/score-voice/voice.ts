// The voice score: what the app sends, what the model is asked, and what comes back (brief 35).
//
// Pure functions only (no network, no env), so every rule here is unit-tested with no API key.
// The model is a senior recruiter who listens to a spoken answer and its follow-up reply,
// transcribes them, says which of the mission's points were made, and grades the CONTENT: never
// accent, pronunciation or how the candidate sounds.

import { VOICE_MISSION_IDS } from '../score/missions.ts';

/** The four dimensions, in the order the dossier shows them. */
export const DIMENSIONS = ['relevance', 'specificity', 'structure', 'adaptability'] as const;
export type Dimension = (typeof DIMENSIONS)[number];

/** One thing a strong answer does, tied to the dimension it earns. */
export interface ListenFor {
  id: string;
  text: string;
  dimension: Dimension;
}

/** A recorded answer: the audio, base64 in the request, as bytes once parsed. */
export interface Clip {
  mimeType: string;
  /** Base64, as it goes to Gemini (`inlineData.data`). Never logged, never stored. */
  base64: string;
  bytes: number;
}

/** What the app sends. Never the player's name: the questions are content. */
export interface VoiceInput {
  missionId: string;
  hiringFor: string;
  interviewerRole: string;
  question: string;
  listenFor: ListenFor[];
  followUpQuestion: string;
  followUpListenFor: ListenFor[];
  answer: Clip;
  reply: Clip;
  /** The longest either clip may run (the mission's `maxSeconds`). */
  maxSeconds: number;
  attemptId: string | null;
}

export interface Graded {
  score: number;
  basis: string;
}

/** What the function returns to the app. */
export interface VoiceResult {
  model: string;
  transcript: { answer: string; reply: string };
  /** The ids of the listen-for points the answer and reply made, in content order. */
  pointsMade: string[];
  overall: Graded;
  dimensions: Record<Dimension, Graded>;
}

/** A request that can't be scored: answered with 400 (never echoing the input). */
export class InputError extends Error {}

/** The model answered with something unusable, even after repair. Answered with 502. */
export class OutputError extends Error {}

/** The audio types Gemini understands (https://ai.google.dev/gemini-api/docs/audio). */
export const AUDIO_TYPES = ['audio/wav', 'audio/mp3', 'audio/aiff', 'audio/aac', 'audio/ogg', 'audio/flac'];

/** One clip's cap: two minutes of 16 kHz mono 16-bit PCM is 3.84 MB, so this holds any take. */
export const MAX_AUDIO_BYTES = 4_000_000;

/** The whole request's cap, checked on `content-length` before anything is parsed. */
export const MAX_BODY_BYTES = 12_000_000;

/** The longest `maxSeconds` a mission may ask for, and the shortest. */
export const MAX_SECONDS = 180;
const MIN_SECONDS = 10;

/** A WAV's header may round its length; a take this much over the cap is still accepted. */
const SECONDS_TOLERANCE = 1;

/** Each transcript's cap: 90 s of fast speech is about 1,500 characters. Two fit `ai_scores`. */
export const MAX_TRANSCRIPT = 2900;

const MAX_TEXT = 600;
const MAX_ID = 80;
const ID_PATTERN = /^[a-z0-9]+(_[a-z0-9]+)*$/;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const BASE64_PATTERN = /^[A-Za-z0-9+/]+={0,2}$/;
const WAV_HEADER = 44;
const WAV_BYTE_RATE_AT = 28;

function text(value: unknown, field: string, max = MAX_TEXT): string {
  if (typeof value !== 'string' || value.trim() === '') throw new InputError(`${field} is required`);
  if (value.length > max) throw new InputError(`${field} is too long`);
  return value.trim();
}

function id(value: unknown, field: string): string {
  const v = text(value, field, MAX_ID);
  if (!ID_PATTERN.test(v)) throw new InputError(`${field} is not a content id`);
  return v;
}

/** A voice mission's id from the content: an invented room is never scored (issue 74). */
function voiceMission(value: unknown): string {
  const v = id(value, 'mission_id');
  if (!VOICE_MISSION_IDS.has(v)) throw new InputError('mission_id is not a voice mission');
  return v;
}

function points(value: unknown, field: string, min: number, max: number): ListenFor[] {
  if (!Array.isArray(value) || value.length < min || value.length > max) {
    throw new InputError(`${field} must hold ${min}-${max} points`);
  }
  return value.map((raw, i): ListenFor => {
    if (typeof raw !== 'object' || raw === null) throw new InputError(`${field}[${i}] must be an object`);
    const p = raw as Record<string, unknown>;
    const dimension = p.dimension;
    if (typeof dimension !== 'string' || !(DIMENSIONS as readonly string[]).includes(dimension)) {
      throw new InputError(`${field}[${i}].dimension is not a dimension`);
    }
    return {
      id: id(p.id, `${field}[${i}].id`),
      text: text(p.text, `${field}[${i}].text`),
      dimension: dimension as Dimension,
    };
  });
}

/** The decoded length of base64 [b64], without decoding it. */
function decodedLength(b64: string): number {
  const padding = b64.endsWith('==') ? 2 : b64.endsWith('=') ? 1 : 0;
  return (b64.length / 4) * 3 - padding;
}

/** The first [n] bytes of base64 [b64]. */
function head(b64: string, n: number): Uint8Array {
  const chars = Math.ceil(n / 3) * 4;
  const bin = atob(b64.slice(0, chars));
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

function clip(value: unknown, mimeType: string, field: string, maxSeconds: number): Clip {
  if (typeof value !== 'string' || value === '') throw new InputError(`${field} is required`);
  if (value.length % 4 !== 0 || !BASE64_PATTERN.test(value)) throw new InputError(`${field} is not base64`);
  const bytes = decodedLength(value);
  if (bytes > MAX_AUDIO_BYTES) throw new InputError(`${field} is too large`);
  if (mimeType === 'audio/wav') {
    if (bytes <= WAV_HEADER) throw new InputError(`${field} is empty`);
    const header = head(value, WAV_HEADER);
    const riff = String.fromCharCode(...header.slice(0, 4));
    const wave = String.fromCharCode(...header.slice(8, 12));
    if (riff !== 'RIFF' || wave !== 'WAVE') throw new InputError(`${field} is not a WAV file`);
    const byteRate = new DataView(header.buffer).getUint32(WAV_BYTE_RATE_AT, true);
    if (byteRate === 0) throw new InputError(`${field} has no byte rate`);
    if ((bytes - WAV_HEADER) / byteRate > maxSeconds + SECONDS_TOLERANCE) {
      throw new InputError(`${field} runs longer than the mission allows`);
    }
  }
  return { mimeType, base64: value, bytes };
}

/** Parses the request body. Anything unexpected is an [InputError], never a model call. */
export function parseInput(body: unknown): VoiceInput {
  if (typeof body !== 'object' || body === null) throw new InputError('body must be an object');
  const b = body as Record<string, unknown>;
  const maxSeconds = b.max_seconds;
  if (
    typeof maxSeconds !== 'number' || !Number.isInteger(maxSeconds) || maxSeconds < MIN_SECONDS ||
    maxSeconds > MAX_SECONDS
  ) {
    throw new InputError(`max_seconds must be ${MIN_SECONDS}-${MAX_SECONDS}`);
  }
  const mimeType = b.mime_type;
  if (typeof mimeType !== 'string' || !AUDIO_TYPES.includes(mimeType)) {
    throw new InputError('mime_type is not an audio type Gemini reads');
  }
  const listenFor = points(b.listen_for, 'listen_for', 3, 4);
  const followUpListenFor = points(b.follow_up_listen_for, 'follow_up_listen_for', 1, 3);
  const ids = [...listenFor, ...followUpListenFor].map((p) => p.id);
  if (new Set(ids).size !== ids.length) throw new InputError('point ids repeat');
  const attemptId = b.attempt_id;
  if (
    attemptId !== null && attemptId !== undefined && (typeof attemptId !== 'string' || !UUID_PATTERN.test(attemptId))
  ) {
    throw new InputError('attempt_id must be a uuid or null');
  }
  return {
    missionId: voiceMission(b.mission_id),
    hiringFor: text(b.hiring_for, 'hiring_for', 120),
    interviewerRole: text(b.interviewer_role, 'interviewer_role', 80),
    question: text(b.question, 'question'),
    listenFor,
    followUpQuestion: text(b.follow_up_question, 'follow_up_question'),
    followUpListenFor,
    answer: clip(b.answer_audio, mimeType, 'answer_audio', maxSeconds),
    reply: clip(b.reply_audio, mimeType, 'reply_audio', maxSeconds),
    maxSeconds,
    attemptId: typeof attemptId === 'string' ? attemptId.toLowerCase() : null,
  };
}

/** The panel's instructions. Stable text, so the same answer is graded the same way. */
export function systemInstruction(input: VoiceInput): string {
  return [
    `You are a senior recruiter hiring for: ${input.hiringFor}. You have interviewed hundreds of`,
    'graduates for this kind of role. A candidate answered one interview question out loud; the',
    `interviewer (${input.interviewerRole}) then asked one follow-up, which they also answered out`,
    'loud. You get both recordings.',
    '',
    'First, transcribe each recording faithfully: the words the candidate said, in order, with',
    'punctuation. Do not correct, improve or summarise them. If a recording has no speech, its',
    'transcript is an empty string.',
    '',
    'Then say which of the listed points the candidate made. A point counts only when its',
    'substance is clearly said; a vague gesture towards it does not count. Use only the ids given.',
    '',
    'Then grade four dimensions from 0 to 100, on what was SAID:',
    '- relevance: does the answer address the question actually asked?',
    "- specificity: concrete facts, the candidate's own part, numbers, instead of generalities?",
    '- structure: a clear opening, one piece of evidence, a deliberate close?',
    '- adaptability: does the reply to the follow-up answer it directly and honestly?',
    'Then an overall score from 0 to 100: your judgement of the whole answer, not an average.',
    '',
    'Score the content only. NEVER score or mention accent, pronunciation, fluency, pace, filler',
    'words, grammar, voice or how the candidate sounds: a non-native speaker who makes the points',
    'scores exactly as a native speaker who makes them.',
    '',
    'For every number give ONE short sentence of basis: why this score, citing what the answer said',
    'or failed to say. Do not give advice, tips or rewrites. Do not address the candidate.',
  ].join('\n');
}

function pointLines(list: ListenFor[]): string[] {
  return list.map((p) => `- ${p.id} (${p.dimension}): ${p.text}`);
}

/** The text that goes around the two recordings: the questions and the points to listen for. */
export function promptParts(input: VoiceInput): { beforeAnswer: string; beforeReply: string; after: string } {
  return {
    beforeAnswer: [
      `Question: ${input.question}`,
      '',
      'Points a strong answer to the question makes:',
      ...pointLines(input.listenFor),
      '',
      "The candidate's spoken answer:",
    ].join('\n'),
    beforeReply: [
      `Follow-up: ${input.followUpQuestion}`,
      '',
      'Points a strong reply to the follow-up makes:',
      ...pointLines(input.followUpListenFor),
      '',
      "The candidate's spoken reply:",
    ].join('\n'),
    after: 'Transcribe both recordings, list the points made, and grade the answer.',
  };
}

const graded = {
  type: 'OBJECT',
  properties: {
    score: { type: 'INTEGER', minimum: 0, maximum: 100 },
    basis: { type: 'STRING' },
  },
  required: ['score', 'basis'],
  propertyOrdering: ['score', 'basis'],
};

/** The JSON the model must return (Gemini's `responseSchema`), with the point ids as an enum. */
export function responseSchema(input: VoiceInput): Record<string, unknown> {
  const ids = [...input.listenFor, ...input.followUpListenFor].map((p) => p.id);
  const order = ['answer_transcript', 'reply_transcript', 'points_made', ...DIMENSIONS, 'overall'];
  return {
    type: 'OBJECT',
    properties: {
      answer_transcript: { type: 'STRING' },
      reply_transcript: { type: 'STRING' },
      points_made: { type: 'ARRAY', items: { type: 'STRING', enum: ids } },
      relevance: graded,
      specificity: graded,
      structure: graded,
      adaptability: graded,
      overall: graded,
    },
    required: order,
    propertyOrdering: order,
  };
}

/** A basis is one short sentence: longer text is cut at its first sentence, then capped. */
export const MAX_BASIS = 220;

function repairBasis(value: unknown, field: string): string {
  if (typeof value !== 'string') throw new OutputError(`${field}.basis is missing`);
  const flat = value.replace(/\s+/g, ' ').trim();
  if (flat === '') throw new OutputError(`${field}.basis is empty`);
  const sentence = flat.match(/^.*?[.!?](\s|$)/)?.[0].trim() ?? flat;
  return sentence.length <= MAX_BASIS ? sentence : `${sentence.slice(0, MAX_BASIS - 1).trimEnd()}…`;
}

function repairScore(value: unknown, field: string): number {
  const n = typeof value === 'string' ? Number(value) : value;
  if (typeof n !== 'number' || !Number.isFinite(n)) throw new OutputError(`${field}.score is not a number`);
  return Math.min(100, Math.max(0, Math.round(n)));
}

function repairGraded(value: unknown, field: string): Graded {
  if (typeof value !== 'object' || value === null) throw new OutputError(`${field} is missing`);
  const g = value as Record<string, unknown>;
  return { score: repairScore(g.score, field), basis: repairBasis(g.basis, field) };
}

function repairTranscript(value: unknown, field: string): string {
  if (typeof value !== 'string') throw new OutputError(`${field} is missing`);
  const flat = value.replace(/\s+/g, ' ').trim();
  return flat.length <= MAX_TRANSCRIPT ? flat : `${flat.slice(0, MAX_TRANSCRIPT - 1).trimEnd()}…`;
}

/**
 * Validates the model's JSON and repairs what can be repaired safely: scores clamped and rounded,
 * a basis cut to its first sentence, a transcript's whitespace flattened and capped, unknown or
 * repeated point ids dropped (the rest kept in content order). A missing field, a non-number
 * score or text that isn't JSON is an [OutputError].
 */
export function parseVerdict(raw: string, model: string, input: VoiceInput): VoiceResult {
  let json: unknown;
  try {
    json = JSON.parse(raw.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, ''));
  } catch {
    throw new OutputError('the model did not return JSON');
  }
  if (typeof json !== 'object' || json === null) throw new OutputError('the model returned no object');
  const v = json as Record<string, unknown>;
  if (!Array.isArray(v.points_made)) throw new OutputError('points_made is missing');
  const said = new Set(v.points_made.filter((p): p is string => typeof p === 'string'));
  const pointsMade = [...input.listenFor, ...input.followUpListenFor].map((p) => p.id).filter((p) => said.has(p));
  const dimensions = Object.fromEntries(
    DIMENSIONS.map((d) => [d, repairGraded(v[d], d)]),
  ) as Record<Dimension, Graded>;
  return {
    model,
    transcript: {
      answer: repairTranscript(v.answer_transcript, 'answer_transcript'),
      reply: repairTranscript(v.reply_transcript, 'reply_transcript'),
    },
    pointsMade,
    overall: repairGraded(v.overall, 'overall'),
    dimensions,
  };
}

/** The transcript as `ai_scores` keeps it: both parts, labelled, never the audio. */
export function storedTranscript(result: VoiceResult): string | null {
  const { answer, reply } = result.transcript;
  if (answer === '' && reply === '') return null;
  return `Answer: ${answer}\nReply: ${reply}`;
}
