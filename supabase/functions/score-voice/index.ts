// `score-voice`: a senior recruiter (Gemini) listens to a voice mission's spoken answer and
// reply, transcribes them and grades what was said, never how it sounded (brief 35). Called by
// the app with the player's own Supabase JWT; uses the same Gemini key and the same 30-a-day
// quota as `score`. The audio is passed to Gemini and dropped: it is never stored or logged.
//
// Local:  supabase start && supabase functions serve score-voice --env-file .env
// Remote: supabase secrets set --env-file .env && supabase functions deploy score-voice

import { scoreVoiceWithFallback } from './gemini_voice.ts';
import { type Deps, handle, NotConfigured, Unauthorized } from './handler.ts';
import { storedTranscript, type VoiceInput, type VoiceResult } from './voice.ts';

// Set by the Supabase runtime; every database call runs as the player (their JWT), under RLS.
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

function rest(path: string, jwt: string, body: unknown, prefer?: string): Promise<Response> {
  return fetch(`${supabaseUrl}/rest/v1/${path}`, {
    method: 'POST',
    headers: {
      apikey: anonKey,
      authorization: `Bearer ${jwt}`,
      'content-type': 'application/json',
      ...(prefer ? { prefer } : {}),
    },
    body: JSON.stringify(body),
  });
}

const deps: Deps = {
  score(input: VoiceInput) {
    const key = Deno.env.get('GEMINI_API_KEY');
    if (!key) return Promise.reject(new NotConfigured());
    return scoreVoiceWithFallback(input, key);
  },

  async claimQuota(jwt: string) {
    const res = await rest('rpc/claim_ai_score', jwt, {});
    if (res.status === 401 || res.status === 403) {
      await res.body?.cancel();
      throw new Unauthorized();
    }
    if (!res.ok) {
      await res.body?.cancel();
      throw new Error(`claim_ai_score answered ${res.status}`);
    }
    return (await res.json()) === true;
  },

  async saveScore(jwt: string, input: VoiceInput, result: VoiceResult) {
    const d = result.dimensions;
    const res = await rest('ai_scores', jwt, {
      attempt_id: input.attemptId,
      mission_id: input.missionId,
      model: result.model,
      relevance_score: d.relevance.score,
      specificity_score: d.specificity.score,
      structure_score: d.structure.score,
      adaptability_score: d.adaptability.score,
      overall_score: result.overall.score,
      basis: {
        relevance: d.relevance.basis,
        specificity: d.specificity.basis,
        structure: d.structure.basis,
        adaptability: d.adaptability.basis,
        overall: result.overall.basis,
      },
      transcript: storedTranscript(result),
      points_made: result.pointsMade,
    }, 'return=minimal');
    await res.body?.cancel();
    if (!res.ok) throw new Error(`ai_scores insert answered ${res.status}`);
  },

  log(fields) {
    console.log(JSON.stringify({ fn: 'score-voice', ...fields }));
  },

  now: () => Date.now(),
};

Deno.serve((req) => handle(req, deps));
