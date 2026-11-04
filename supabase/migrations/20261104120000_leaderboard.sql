-- Issue 72: the leaderboard. What each player reports, and the one way to read other players.
--
-- 1. profiles gets the numbers the board ranks, as the device's engine computes them (the same
--    totals "Your file" shows): total_xp, week_xp for the UTC week starting week_start (a
--    Monday), and streak_weeks (weeks in a row meeting the weekly goal). Plus
--    leaderboard_visible ("Show me on the leaderboard", on by default).
--    Columns on profiles rather than a new table: the row already syncs through the device's
--    profile outbox (offline play catches up the same way the first name does), it already has
--    owner-only RLS, and the board needs the first name from this row anyway. A second table
--    would be a second outbox kind, a second restore and a join, for the same one row per player.
-- 2. week_xp_at / total_xp_at: when the player reached their current score, the last tie-break
--    ("earliest to reach it"). Server time from a trigger; the client is never granted them.
-- 3. public.leaderboard(scope, limit): the only way anyone reads another player's row. Security
--    definer (it reads past the owner-only policies), so it returns only what the board shows:
--    a display name (the first name, or null), a 4-digit tag derived from the user id here on
--    the server (never the id), the XP figures, the streak, the rank and is_me. No user id, no
--    email, no other column. It leaves out players who switched the board off, except the
--    caller, and always returns the caller's row, even outside the top N.
--
-- Weeks are UTC (Monday 00:00 UTC to Sunday 23:59 UTC) so everyone shares one board. A week_xp
-- reported for an older week counts 0, and a streak older than last week counts 0.
--
-- Honest limit: XP is client-reported. The check constraints keep it sane, not true; a
-- server-side recount from mission_attempts is a later step (docs/completion.md).
--
-- Additive only (docs/rules/migrations.md rule 4); the column grants keep least privilege.
-- Tests: supabase/tests/leaderboard.test.sql.

alter table public.profiles
  add column leaderboard_visible boolean not null default true,
  add column total_xp integer not null default 0 check (total_xp >= 0),
  add column week_xp integer not null default 0 check (week_xp >= 0),
  add column week_start date check (week_start is null or extract(isodow from week_start) = 1),
  add column streak_weeks smallint not null default 0 check (streak_weeks >= 0),
  add column total_xp_at timestamptz not null default now(),
  add column week_xp_at timestamptz not null default now();

grant insert (leaderboard_visible, total_xp, week_xp, week_start, streak_weeks)
  on table public.profiles to authenticated;
grant update (leaderboard_visible, total_xp, week_xp, week_start, streak_weeks)
  on table public.profiles to authenticated;

-- When the current score was reached: moves only when the score does.
create function private.set_leaderboard_reached_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.total_xp_at := now();
    new.week_xp_at := now();
    return new;
  end if;
  if new.total_xp is distinct from old.total_xp then
    new.total_xp_at := now();
  else
    new.total_xp_at := old.total_xp_at;
  end if;
  if new.week_xp is distinct from old.week_xp or new.week_start is distinct from old.week_start then
    new.week_xp_at := now();
  else
    new.week_xp_at := old.week_xp_at;
  end if;
  return new;
end;
$$;

revoke all on function private.set_leaderboard_reached_at() from public;

create trigger profiles_leaderboard_reached_at
  before insert or update on public.profiles
  for each row execute function private.set_leaderboard_reached_at();

create index profiles_leaderboard_week_idx on public.profiles (week_start, week_xp desc);
create index profiles_leaderboard_all_idx on public.profiles (total_xp desc);

-- The board, best first: p_scope 'week' ranks this UTC week's XP, 'all' total XP. Ties go to the
-- longer weeks-in-a-row streak, then to whoever reached the score first. Players with no XP on
-- that board are left out, except the caller. p_limit is clamped to 1-100.
-- 42501 with no signed-in user; 22023 for an unknown scope.
create function public.leaderboard(p_scope text, p_limit integer default 50)
returns table (
  rank integer,
  display_name text,
  tag text,
  total_xp integer,
  week_xp integer,
  streak_weeks integer,
  is_me boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  caller uuid := auth.uid();
  monday date := date_trunc('week', now() at time zone 'utc')::date;
  top integer := least(greatest(coalesce(p_limit, 50), 1), 100);
begin
  if caller is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  if p_scope is null or p_scope not in ('week', 'all') then
    raise exception 'unknown leaderboard scope' using errcode = '22023';
  end if;
  return query
  with players as (
    select
      p.user_id = caller as mine,
      p.user_id as uid,
      nullif(regexp_replace(btrim(p.first_name), '[[:space:].!?,;:]+$', ''), '') as shown_name,
      p.total_xp as all_xp,
      case when p.week_start = monday then p.week_xp else 0 end as this_week_xp,
      case when p.week_start >= monday - 7 then p.streak_weeks::integer else 0 end as streak,
      p.total_xp_at as all_at,
      p.week_xp_at as week_at
    from public.profiles p
    where p.leaderboard_visible or p.user_id = caller
  ),
  scored as (
    select
      pl.*,
      case when p_scope = 'week' then pl.this_week_xp else pl.all_xp end as score,
      case when p_scope = 'week' then pl.week_at else pl.all_at end as reached_at
    from players pl
  ),
  ranked as (
    select
      s.*,
      row_number() over (
        order by s.score desc, s.streak desc, s.reached_at asc, s.uid
      )::integer as place
    from scored s
    where s.score > 0 or s.mine
  )
  select
    r.place,
    r.shown_name,
    lpad(((('x' || substr(md5(r.uid::text), 1, 7))::bit(28)::integer) % 10000)::text, 4, '0'),
    r.all_xp,
    r.this_week_xp,
    r.streak,
    r.mine
  from ranked r
  where r.place <= top or r.mine
  order by r.place;
end;
$$;

revoke all on function public.leaderboard(text, integer) from public, anon;
grant execute on function public.leaderboard(text, integer) to authenticated;
