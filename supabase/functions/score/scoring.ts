// The AI score: what the app sends, what the model is asked, and what comes back.
//
// Pure functions only (no network, no env), so every rule here is unit-tested with no API key.
// The model is a senior recruiter grading the answer the player built: a score and its basis,
// never advice (brief 22: "not a coach").

/** The four dimensions, in the order the dossier shows them. */
export const DIMENSIONS = ['relevance', 'specificity', 'structure', 'adaptability'] as const;
export type Dimension = (typeof DIMENSIONS)[number];

/** One beat of the answer, as the player played it. */
export interface BeatInput {
  /** `open`, `evidence` or `land`. */
  kind: string;
  /** The line the player picked. */
  line: string;
  /** The principle they gave when asked "why that line?", if the beat asked. */
  reason: string | null;
  /** Picked before the options could have been read. */
  guessed: boolean;
}

/** What the app sends. Never the player's name: the lines are the practice candidate's. */
export interface ScoreInput {
  missionId: string;
  /** The job the panel is hiring for. */
  hiringFor: string;
  /** The interviewer's role ("Recruiter"). */
  interviewerRole: string;
  question: string;
  beats: BeatInput[];
  followUpQuestion: string;
  reply: string;
  /** The attempt the score belongs to, when the app knows it. */
  attemptId: string | null;
}

/** One graded number and why. */
export interface Graded {
  score: number;
  basis: string;
}

/** What the function returns to the app. */
export interface ScoreResult {
  model: string;
  overall: Graded;
  dimensions: Record<Dimension, Graded>;
}

/** A request that can't be scored: answered with 400 and this message (never the input). */
export class InputError extends Error {}

/** The model answered with something unusable, even after repair. Answered with 502. */
export class OutputError extends Error {}

const MAX_TEXT = 600;
const MAX_BEATS = 3;
const MAX_ID = 80;
const ID_PATTERN = /^[a-z0-9]+(_[a-z0-9]+)*$/;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function text(value: unknown, field: string, max = MAX_TEXT): string {
  if (typeof value !== 'string' || value.trim() === '') throw new InputError(`${field} is required`);
  if (value.length > max) throw new InputError(`${field} is too long`);
  return value.trim();
}

/** Parses the request body. Anything unexpected is an [InputError], never a model call. */
export function parseInput(body: unknown): ScoreInput {
  if (typeof body !== 'object' || body === null) throw new InputError('body must be an object');
  const b = body as Record<string, unknown>;
  const missionId = text(b.mission_id, 'mission_id', MAX_ID);
  if (!ID_PATTERN.test(missionId)) throw new InputError('mission_id is not a content id');
  if (!Array.isArray(b.beats) || b.beats.length === 0 || b.beats.length > MAX_BEATS) {
    throw new InputError(`beats must hold 1-${MAX_BEATS} beats`);
  }
  const beats = b.beats.map((raw, i): BeatInput => {
    if (typeof raw !== 'object' || raw === null) throw new InputError(`beats[${i}] must be an object`);
    const beat = raw as Record<string, unknown>;
    const reason = beat.reason;
    if (reason !== null && reason !== undefined && typeof reason !== 'string') {
      throw new InputError(`beats[${i}].reason must be text or null`);
    }
    if (typeof beat.guessed !== 'boolean') throw new InputError(`beats[${i}].guessed must be a boolean`);
    return {
      kind: text(beat.kind, `beats[${i}].kind`, MAX_ID),
      line: text(beat.line, `beats[${i}].line`),
      reason: typeof reason === 'string' && reason.trim() !== '' ? text(reason, `beats[${i}].reason`) : null,
      guessed: beat.guessed,
    };
  });
  const attemptId = b.attempt_id;
  if (
    attemptId !== null && attemptId !== undefined && (typeof attemptId !== 'string' || !UUID_PATTERN.test(attemptId))
  ) {
    throw new InputError('attempt_id must be a uuid or null');
  }
  return {
    missionId,
    hiringFor: text(b.hiring_for, 'hiring_for', 120),
    interviewerRole: text(b.interviewer_role, 'interviewer_role', 80),
    question: text(b.question, 'question'),
    beats,
    followUpQuestion: text(b.follow_up_question, 'follow_up_question'),
    reply: text(b.reply, 'reply'),
    attemptId: typeof attemptId === 'string' ? attemptId.toLowerCase() : null,
  };
}

/** The panel's instructions. Stable text, so the same answer is graded the same way. */
export function systemInstruction(input: ScoreInput): string {
  return [
    `You are a senior recruiter hiring for: ${input.hiringFor}. You have interviewed hundreds of`,
    'graduates for this kind of role. A candidate answered one interview question; the interviewer',
    `(${input.interviewerRole}) then asked one follow-up. Grade the answer as you would in a real`,
    'hiring decision.',
    '',
    'Grade four dimensions from 0 to 100:',
    '- relevance: does the answer address the question actually asked?',
    "- specificity: concrete facts, the candidate's own part, numbers, instead of generalities?",
    '- structure: a clear opening, one piece of evidence, a deliberate close?',
    '- adaptability: does the reply to the follow-up answer it directly and honestly?',
    'Then an overall score from 0 to 100: your judgement of the whole answer, not an average.',
    '',
    'Each answer line was picked from options, and after each pick the candidate gave the reason',
    'for choosing it. Weigh the reasoning: a strong line chosen for the wrong reason is luck, not',
    'skill. A line marked GUESSED was picked faster than anyone could read the options; treat it',
    'as contributing nothing.',
    '',
    'For every number give ONE short sentence of basis: why this score, citing what the answer did',
    'or failed to do. Do not give advice, tips or rewrites. Do not address the candidate. Judge',
    'content only, never accent, grammar polish or style.',
  ].join('\n');
}

/** The answer as the panel reads it. */
export function answerTranscript(input: ScoreInput): string {
  const beats = input.beats.map((b) => {
    const why = b.reason === null ? '' : `\n   Reason given: ${b.reason}`;
    const guess = b.guessed ? ' [GUESSED]' : '';
    return `- ${b.kind.toUpperCase()}${guess}: "${b.line}"${why}`;
  });
  return [
    `Question: ${input.question}`,
    '',
    "The candidate's answer, beat by beat:",
    ...beats,
    '',
    `Follow-up: ${input.followUpQuestion}`,
    `Reply: "${input.reply}"`,
  ].join('\n');
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

/** The JSON the model must return (Gemini's `responseSchema`, an OpenAPI subset). */
export const RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    relevance: graded,
    specificity: graded,
    structure: graded,
    adaptability: graded,
    overall: graded,
  },
  required: [...DIMENSIONS, 'overall'],
  propertyOrdering: [...DIMENSIONS, 'overall'],
};

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

/**
 * Validates the model's JSON and repairs what can be repaired safely: a score out of range is
 * clamped, a decimal rounded, a multi-sentence basis cut to its first sentence. A missing field,
 * a non-number score or text that isn't JSON is an [OutputError].
 */
export function parseVerdict(raw: string, model: string): ScoreResult {
  let json: unknown;
  try {
    // A model may wrap JSON in a fence despite the MIME type; strip it before parsing.
    json = JSON.parse(raw.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, ''));
  } catch {
    throw new OutputError('the model did not return JSON');
  }
  if (typeof json !== 'object' || json === null) throw new OutputError('the model returned no object');
  const v = json as Record<string, unknown>;
  const dimensions = Object.fromEntries(
    DIMENSIONS.map((d) => [d, repairGraded(v[d], d)]),
  ) as Record<Dimension, Graded>;
  return { model, overall: repairGraded(v.overall, 'overall'), dimensions };
}
