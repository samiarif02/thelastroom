// `score`: a senior recruiter (Gemini) grades the answer a player built in a mission (brief 22,
// ADR 0006). Called by the app with the player's own Supabase JWT; holds the only Gemini key.
//
// Local:  supabase start && supabase functions serve score --env-file .env
// Remote: supabase secrets set --env-file .env && supabase functions deploy score

import { scoreWithGemini } from './gemini.ts';
import { type Deps, handle, NotConfigured, Unauthorized } from './handler.ts';
import type { ScoreInput, ScoreResult } from './scoring.ts';

// Set by the Supabase runtime; the anon key is public, and every database call below runs as
// the player (their JWT), so RLS applies exactly as it does to the app.
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
  score(input: ScoreInput) {
    const key = Deno.env.get('GEMINI_API_KEY');
    if (!key) return Promise.reject(new NotConfigured());
    return scoreWithGemini(input, key);
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

  async saveScore(jwt: string, input: ScoreInput, result: ScoreResult) {
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
    }, 'return=minimal');
    await res.body?.cancel();
    if (!res.ok) throw new Error(`ai_scores insert answered ${res.status}`);
  },

  log(fields) {
    console.log(JSON.stringify({ fn: 'score', ...fields }));
  },

  now: () => Date.now(),
};

Deno.serve((req) => handle(req, deps));
