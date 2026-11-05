// `score`: a senior recruiter (Gemini) grades the answer a player built in a mission (brief 22,
// ADR 0006). Called by the app with the player's own Supabase JWT; holds the only Gemini key.
//
// Local:  supabase start && supabase functions serve score --env-file .env
// Remote: supabase secrets set --env-file .env && supabase functions deploy score

import { scoreWithFallback } from './gemini.ts';
import { type Deps, handle, NotConfigured, Unauthorized } from './handler.ts';
import type { ScoreInput, ScoreResult } from './scoring.ts';

// Set by the Supabase runtime. The anon key is public: the quota is claimed as the player (their
// JWT, under RLS). The service role key never leaves this function: only it may insert
// ai_scores (issue 74), for the user id the auth server read from the player's JWT.
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

function rest(path: string, bearer: string, body: unknown, prefer?: string, apikey = anonKey): Promise<Response> {
  return fetch(`${supabaseUrl}/rest/v1/${path}`, {
    method: 'POST',
    headers: {
      apikey,
      authorization: `Bearer ${bearer}`,
      'content-type': 'application/json',
      ...(prefer ? { prefer } : {}),
    },
    body: JSON.stringify(body),
  });
}

/** Writes as the server: the service role, which bypasses RLS. Only ever for a verified id. */
function asServer(path: string, body: unknown): Promise<Response> {
  if (!serviceKey) return Promise.reject(new Error('no service role key'));
  return rest(path, serviceKey, body, 'return=minimal', serviceKey);
}

const deps: Deps = {
  async callerId(jwt: string) {
    // The auth server checks the signature, the expiry and that the session still exists.
    const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { apikey: anonKey, authorization: `Bearer ${jwt}` },
    });
    if (res.status >= 400 && res.status < 500) {
      await res.body?.cancel();
      throw new Unauthorized();
    }
    if (!res.ok) {
      await res.body?.cancel();
      throw new Error(`auth user answered ${res.status}`);
    }
    const user = (await res.json()) as { id?: unknown };
    if (typeof user.id !== 'string' || user.id === '') throw new Unauthorized();
    return user.id;
  },

  score(input: ScoreInput) {
    const key = Deno.env.get('GEMINI_API_KEY');
    if (!key) return Promise.reject(new NotConfigured());
    return scoreWithFallback(input, key);
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

  async saveScore(userId: string, input: ScoreInput, result: ScoreResult) {
    const d = result.dimensions;
    const res = await asServer('ai_scores', {
      user_id: userId,
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
    });
    await res.body?.cancel();
    if (!res.ok) throw new Error(`ai_scores insert answered ${res.status}`);
  },

  log(fields) {
    console.log(JSON.stringify({ fn: 'score', ...fields }));
  },

  now: () => Date.now(),
};

Deno.serve((req) => handle(req, deps));
