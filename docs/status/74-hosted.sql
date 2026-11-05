-- Issue 74 for the hosted project (eeanpdlqxmatuidrhoht). Paste the whole file into the
-- Supabase SQL Editor and run it once (a second run stops at its first statement and changes
-- nothing: it is one transaction). It is exactly these two migrations, in order, inside one
-- transaction, plus the rows that record them as applied (so a later `supabase db push` skips
-- them):
--   supabase/migrations/20261105120000_verified_leaderboard.sql
--   supabase/migrations/20261105130000_ai_budget_and_clean_names.sql
-- Needs 20261104120000_leaderboard.sql applied first (it is, since PR #80).
--
-- Order: run this BEFORE redeploying the Edge Functions `score` and `score-voice`. The new
-- functions insert verdicts with the service role and score-voice claims 3 units through
-- claim_ai_score(p_units), which this file creates. (Old functions keep working after this file
-- runs, except that their verdict insert is refused, so the board doesn't move until the
-- redeploy; every player still gets their score.)

begin;

-- ===================================================== 20261105120000_verified_leaderboard.sql
-- Issue 74: the leaderboard ranks server-verified XP only.
--
-- Before this, two things were client-written: profiles.total_xp / week_xp / week_start /
-- streak_weeks (20261104120000_leaderboard.sql granted them to authenticated), and ai_scores
-- itself (the `score` functions inserted as the player, so a client could insert its own
-- overall_score = 100). A modified app could put any number on the board.
--
-- After it:
-- 1. ai_scores is written by the server only. The `score` and `score-voice` Edge Functions insert
--    with the service role, with user_id taken from the caller's verified JWT (never the body).
--    authenticated keeps select on its own rows; its insert grants and insert policy go.
-- 2. The leaderboard columns on profiles are server-only: the client grants on total_xp, week_xp,
--    week_start and streak_weeks are revoked (leaderboard_visible stays client-writable).
-- 3. private.recount_verified_xp(uid) recomputes them from ai_scores, fired by a trigger on
--    every ai_scores insert:
--      per mission, the BEST verified overall score counts once, as the engine's room XP for a
--      first clear (packages/engine/lib/src/progression.dart, missionXp):
--        xp = missionBaseXp (20) + best ÷ 2 (rounded down) + firstClearBonusXp (30)
--      so a mission is worth at most 100 and a replay only counts when it beats the best.
--      total_xp     = Σ over missions of that XP.
--      week_start   = the UTC Monday of the player's latest verified score (this week's, as
--                     soon as a score lands).
--      week_xp      = total_xp minus the total from the scores before week_start: verified XP
--                     gained that week.
--      streak_weeks = UTC weeks in a row, ending that week, with at least one verified score.
--    Reason XP and Recall XP stay on the device: they're computed from client-reported picks and
--    can't be verified by the server, so the board doesn't count them ("verified XP").
-- 4. A backfill replaces every reported number with the verified one.
--
-- public.leaderboard() is unchanged: it already ranks these columns, which are now the server's.
-- Its output (rank, display_name, tag, total_xp, week_xp, streak_weeks, is_me) is stable.
--
-- Not additive in one respect (docs/rules/migrations.md rule 4): an app build from before #74
-- still sends the XP columns in its leaderboard upsert, which is now refused (42501). That
-- upsert is its own outbox kind, retried with backoff; the profile and attempts sync untouched.
-- Tests: supabase/tests/verified_leaderboard.test.sql.

-- 1. ai_scores: server-written only.
drop policy "ai_scores: owner inserts own rows" on public.ai_scores;
revoke insert on table public.ai_scores from anon, authenticated;
revoke insert (
  attempt_id, mission_id, model,
  relevance_score, specificity_score, structure_score, adaptability_score, overall_score, basis,
  transcript, points_made
) on table public.ai_scores from authenticated;

-- 2. profiles: the board's numbers are server-only.
revoke insert (total_xp, week_xp, week_start, streak_weeks) on table public.profiles from authenticated;
revoke update (total_xp, week_xp, week_start, streak_weeks) on table public.profiles from authenticated;

-- 3. The recount. Security definer (it writes the columns no client may), search_path ''.
create function private.recount_verified_xp(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- packages/engine/lib/src/progression.dart: missionBaseXp, missionScoreXpDivisor,
  -- firstClearBonusXp. Change them there and here together.
  base_xp constant integer := 20;
  score_divisor constant integer := 2;
  first_clear_xp constant integer := 30;
  -- The UTC week of the player's latest verified score (this week, when a score just landed;
  -- an older one in the backfill). public.leaderboard() counts a stale week and streak as 0.
  anchor date;
  anchor_at timestamptz;
  total integer;
  before_week integer;
  streak integer;
begin
  if p_user is null then
    return;
  end if;
  -- One recount per player at a time: a second concurrent score waits, then sees the first.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user::text, 74));

  select coalesce(
    max(date_trunc('week', s.created_at at time zone 'utc'))::date,
    date_trunc('week', now() at time zone 'utc')::date
  )
  into anchor
  from public.ai_scores s
  where s.user_id = p_user;
  anchor_at := anchor::timestamp at time zone 'utc';

  select
    coalesce(sum(base_xp + best_all / score_divisor + first_clear_xp), 0)::integer,
    coalesce(sum(base_xp + best_before / score_divisor + first_clear_xp)
      filter (where best_before is not null), 0)::integer
  into total, before_week
  from (
    select
      max(s.overall_score)::integer as best_all,
      (max(s.overall_score) filter (where s.created_at < anchor_at))::integer as best_before
    from public.ai_scores s
    where s.user_id = p_user
    group by s.mission_id
  ) per_mission;

  -- Weeks in a row: consecutive UTC Mondays ending at the anchor week.
  select count(*)::integer into streak
  from (
    select w + (row_number() over (order by w desc))::integer * 7 as run
    from (
      select distinct date_trunc('week', s.created_at at time zone 'utc')::date as w
      from public.ai_scores s
      where s.user_id = p_user
    ) weeks
  ) runs
  where run = anchor + 7;

  insert into public.profiles (user_id, total_xp, week_xp, week_start, streak_weeks)
  values (p_user, total, total - before_week, anchor, streak)
  on conflict (user_id) do update set
    total_xp = excluded.total_xp,
    week_xp = excluded.week_xp,
    week_start = excluded.week_start,
    streak_weeks = excluded.streak_weeks;
end;
$$;

revoke all on function private.recount_verified_xp(uuid) from public, anon, authenticated;

create function private.on_ai_score_inserted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.recount_verified_xp(new.user_id);
  return null;
end;
$$;

revoke all on function private.on_ai_score_inserted() from public, anon, authenticated;

create trigger ai_scores_recount_verified_xp
  after insert on public.ai_scores
  for each row execute function private.on_ai_score_inserted();

-- The recount groups one player's scores by mission.
create index ai_scores_user_mission_idx on public.ai_scores (user_id, mission_id);

-- 4. Backfill: every player's board numbers become the verified ones (0 with no AI score).
do $$
declare
  player uuid;
begin
  for player in
    select user_id from public.profiles
    union
    select user_id from public.ai_scores
  loop
    perform private.recount_verified_xp(player);
  end loop;
end;
$$;

-- ================================================ 20261105130000_ai_budget_and_clean_names.sql
-- Issue 74, from the security audit of 2026-11-05.
--
-- 1. A global daily AI budget. claim_ai_score() counts 30 a day per player, but a player id is
--    free to mint (anonymous sign-in), so the per-player cap alone doesn't bound what the one
--    shared Gemini key spends. private.ai_score_budget counts units per UTC day across everyone,
--    checked in the same atomic claim: a built answer is 1 unit, a voice answer 3 (it sends
--    audio). The player's own 30 a day count units the same way (30 built answers, or 10 voice
--    ones), so one minted id can take at most 30 of the budget. Past the budget every claim is refused and the app shows its offline score, as for a
--    player's own spent quota. The real fix for minted ids is captcha on anonymous sign-in (an
--    owner step in the dashboard, docs/scale-and-security.md); this caps the damage.
--    public.claim_ai_score() keeps its signature (1 unit) for functions deployed before this;
--    public.claim_ai_score(p_units) is the new form (1-3 units).
-- 2. first_name is cleaned on the server: control, zero-width and bidirectional-override
--    characters are stripped before the row is written (a trigger, so an old app build's sync
--    still lands rather than being refused). It is shown to other players on the leaderboard.
--
-- RLS and a policy on the new table in this migration (docs/rules/migrations.md rule 1).
-- Tests: supabase/tests/ai_budget_and_names.test.sql.

-- 1. The budget.
create table private.ai_score_budget (
  day date primary key,
  used integer not null check (used >= 0)
);

comment on table private.ai_score_budget is 'AI units used per UTC day by all players; written only by private.claim_ai_units().';

alter table private.ai_score_budget enable row level security;

-- Never read or written by a client (the private schema isn't exposed either): only the
-- security-definer claim touches it.
create policy "ai_score_budget: no client access"
  on private.ai_score_budget for all to authenticated
  using (false)
  with check (false);

revoke all on table private.ai_score_budget from public, anon, authenticated;

-- Takes [p_units] of the caller's 30 daily units and of today's budget, atomically: true when
-- both had room (and counts them), false when either is spent (and counts neither).
-- 42501 with no signed-in user; 22023 for units outside 1-3.
create function private.claim_ai_units(p_units integer)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  daily_limit constant integer := 30;
  -- About 1,000 built answers and 700 voice answers a day; see docs/scale-and-security.md.
  global_daily_units constant integer := 3000;
  caller uuid := auth.uid();
  today date := (now() at time zone 'utc')::date;
  claimed integer;
begin
  if caller is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  if p_units is null or p_units not between 1 and 3 then
    raise exception 'units are 1-3' using errcode = '22023';
  end if;
  insert into public.ai_score_usage as u (user_id, day, used)
  values (caller, today, p_units)
  on conflict (user_id, day) do update
    set used = u.used + p_units
    where u.used + p_units <= daily_limit
  returning used into claimed;
  if claimed is null then
    return false;
  end if;
  insert into private.ai_score_budget as b (day, used)
  values (today, p_units)
  on conflict (day) do update
    set used = b.used + p_units
    where b.used + p_units <= global_daily_units
  returning used into claimed;
  if claimed is null then
    -- The day's budget is spent: give the player's units back.
    update public.ai_score_usage
    set used = used - p_units
    where user_id = caller and day = today;
    return false;
  end if;
  return true;
end;
$$;

revoke all on function private.claim_ai_units(integer) from public, anon, authenticated;

create or replace function public.claim_ai_score()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select private.claim_ai_units(1);
$$;

create function public.claim_ai_score(p_units integer)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select private.claim_ai_units(p_units);
$$;

revoke all on function public.claim_ai_score(integer) from public, anon;
grant execute on function public.claim_ai_score(integer) to authenticated;

-- 2. Clean names.
create function private.clean_first_name()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.first_name := nullif(
    btrim(regexp_replace(
      new.first_name,
      '[\u0001-\u001F\u007F-\u009F\u00AD\u061C\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]',
      '',
      'g'
    )),
    ''
  );
  return new;
end;
$$;

revoke all on function private.clean_first_name() from public;

create trigger profiles_clean_first_name
  before insert or update of first_name on public.profiles
  for each row execute function private.clean_first_name();

-- Names already stored are cleaned the same way.
update public.profiles
set first_name = first_name
where first_name ~ '[\u0001-\u001F\u007F-\u009F\u00AD\u061C\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]';

insert into supabase_migrations.schema_migrations (version, name)
values
  ('20261105120000', 'verified_leaderboard'),
  ('20261105130000', 'ai_budget_and_clean_names')
on conflict do nothing;

commit;
