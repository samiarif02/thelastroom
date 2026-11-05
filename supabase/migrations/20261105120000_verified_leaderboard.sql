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
