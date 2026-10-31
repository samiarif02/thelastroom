-- Brief 22 / ADR 0006: the AI recruiter's verdict on an attempt, and the daily quota that keeps
-- the Gemini key from being drained.
--
-- 1. ai_scores: one row per verdict, written by the `score` Edge Function *as the player* (their
--    JWT, so RLS applies exactly as for the app). Its own table, not columns on mission_attempts:
--    attempts are append-only (no update policy) and are often synced before the verdict comes
--    back, so columns there could never be filled reliably. attempt_id links the two when the
--    app knows it; it isn't a foreign key because the attempt may sync later, or never.
-- 2. ai_score_usage + claim_ai_score(): a per-user, per-UTC-day counter. Players can read their
--    own count but never write it; the only write path is the security-definer function, whose
--    limit lives here in SQL so a client can't raise it.
-- RLS and policies in the same migration (docs/rules/migrations.md); tests in
-- supabase/tests/ai_scores_rls.test.sql.

create table public.ai_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  attempt_id uuid,
  mission_id text not null check (mission_id ~ '^[a-z0-9]+(_[a-z0-9]+)*$'),
  -- The model that graded (e.g. gemini-3.8-flash), so a score can be traced to its judge.
  model text not null check (char_length(model) between 1 and 80),
  relevance_score smallint not null check (relevance_score between 0 and 100),
  specificity_score smallint not null check (specificity_score between 0 and 100),
  structure_score smallint not null check (structure_score between 0 and 100),
  adaptability_score smallint not null check (adaptability_score between 0 and 100),
  overall_score smallint not null check (overall_score between 0 and 100),
  -- One sentence of basis per number: {relevance, specificity, structure, adaptability, overall}.
  basis jsonb not null check (
    jsonb_typeof(basis) = 'object'
    and basis ?& array['relevance', 'specificity', 'structure', 'adaptability', 'overall']
  ),
  created_at timestamptz not null default now()
);

comment on table public.ai_scores is 'AI recruiter verdicts (brief 22). Append-only; owner-only RLS.';

create index ai_scores_user_created_idx on public.ai_scores (user_id, created_at);

alter table public.ai_scores enable row level security;

create policy "ai_scores: owner selects own rows"
  on public.ai_scores for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "ai_scores: owner inserts own rows"
  on public.ai_scores for insert to authenticated
  with check ((select auth.uid()) = user_id);

revoke all on table public.ai_scores from anon, authenticated;
grant select on table public.ai_scores to authenticated;
-- Never id, user_id (defaults to auth.uid()) or created_at (server time).
grant insert (
  attempt_id, mission_id, model,
  relevance_score, specificity_score, structure_score, adaptability_score, overall_score, basis
) on table public.ai_scores to authenticated;

create trigger ai_scores_server_created_at
  before insert on public.ai_scores
  for each row execute function private.set_server_created_at();

create table public.ai_score_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  used integer not null check (used >= 0),
  primary key (user_id, day)
);

comment on table public.ai_score_usage is 'AI scores used per player per UTC day; written only by claim_ai_score().';

alter table public.ai_score_usage enable row level security;

create policy "ai_score_usage: owner selects own rows"
  on public.ai_score_usage for select to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.ai_score_usage from anon, authenticated;
grant select on table public.ai_score_usage to authenticated;

-- Takes one of the caller's AI scores for today: true when one was left (and counts it), false
-- when the day's 30 are spent. 42501 when there's no signed-in user.
create function public.claim_ai_score()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  daily_limit constant integer := 30;
  caller uuid := auth.uid();
  claimed integer;
begin
  if caller is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  insert into public.ai_score_usage as u (user_id, day, used)
  values (caller, (now() at time zone 'utc')::date, 1)
  on conflict (user_id, day) do update
    set used = u.used + 1
    where u.used < daily_limit
  returning used into claimed;
  return claimed is not null;
end;
$$;

revoke all on function public.claim_ai_score() from public, anon;
grant execute on function public.claim_ai_score() to authenticated;
