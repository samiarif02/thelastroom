-- Issue 72: the leaderboard. A player writes only their own XP columns (never another's, never
-- the server's reached-at times); public.leaderboard() ranks this UTC week or all time, hides
-- players who switched it off (except to themselves), always returns the caller, exposes no
-- user id or email, and is closed to anon.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true),
  ('cccccccc-0000-4000-8000-00000000000c', 'c@example.test', true),
  ('dddddddd-0000-4000-8000-00000000000d', 'd@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

-- This UTC week's Monday, as the app sends it.
create function pg_temp.monday() returns date language sql as $$
  select date_trunc('week', now() at time zone 'utc')::date;
$$;

-- The app's profile upsert, with the leaderboard columns (user_id isn't sent).
prepare upsert_board(text, boolean, int, int, date, int) as
  insert into public.profiles (
    first_name, onboarded, leaderboard_visible, total_xp, week_xp, week_start, streak_weeks
  ) values ($1, true, $2, $3, $4, $5, $6)
  on conflict (user_id) do update set
    first_name = excluded.first_name, leaderboard_visible = excluded.leaderboard_visible,
    total_xp = excluded.total_xp, week_xp = excluded.week_xp,
    week_start = excluded.week_start, streak_weeks = excluded.streak_weeks;

-- A: Sami, 900 in all, 120 this week, 2 weeks in a row.
select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok(
  $$ execute upsert_board('Sami', true, 900, 120, pg_temp.monday(), 2) $$,
  'the owner reports their XP, week and streak'
);

select throws_ok(
  $$ update public.profiles set total_xp_at = '2000-01-01' $$,
  '42501', null,
  'a client can''t write when the score was reached (server time)'
);

select throws_ok(
  $$ update public.profiles set total_xp = -1 $$,
  '23514', null,
  'total XP is never negative'
);

select throws_ok(
  $$ update public.profiles set week_start = pg_temp.monday() + 1 $$,
  '23514', null,
  'a week starts on a Monday'
);

-- B: Ali, the same 120 this week but 3 weeks in a row; 300 in all.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select lives_ok(
  $$ execute upsert_board('Ali.', true, 300, 120, pg_temp.monday(), 3) $$,
  'a second player reports theirs'
);

select is_empty(
  $$ update public.profiles set total_xp = 99999
     where user_id = 'aaaaaaaa-0000-4000-8000-00000000000a' returning 1 $$,
  'user B can''t touch user A''s XP'
);

select is_empty(
  $$ select total_xp from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  'user B can''t read user A''s row directly'
);

-- C: hidden from the board, with the most XP of all.
select pg_temp.act_as('cccccccc-0000-4000-8000-00000000000c');
execute upsert_board('Hidden', false, 5000, 500, pg_temp.monday(), 1);

-- D: no first name, and last played a month ago (a stale week and streak).
select pg_temp.act_as('dddddddd-0000-4000-8000-00000000000d');
execute upsert_board(null, true, 100, 50, pg_temp.monday() - 28, 4);

-- What B sees.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select results_eq(
  $$ select rank, display_name, week_xp, streak_weeks, is_me
     from public.leaderboard('week') order by rank $$,
  $$ values (1, 'Ali'::text, 120, 3, true), (2, 'Sami'::text, 120, 2, false) $$,
  'this week: a tie goes to the longer streak; the hidden player and a stale week are left out'
);

select results_eq(
  $$ select rank, display_name, total_xp, week_xp, streak_weeks, is_me
     from public.leaderboard('all') order by rank $$,
  $$ values (1, 'Sami'::text, 900, 120, 2, false), (2, 'Ali'::text, 300, 120, 3, true),
            (3, null::text, 100, 0, 0, false) $$,
  'all time: total XP; an old week counts 0 and an old streak 0; no first name is null'
);

select is_empty(
  $$ select 1 from public.leaderboard('all') where tag !~ '^[0-9]{4}$' $$,
  'every tag is 4 digits'
);

select is(
  (select count(distinct tag)::int from public.leaderboard('all')),
  3,
  'each player has their own tag here'
);

select is(
  (select tag from public.leaderboard('all') where display_name = 'Sami'),
  lpad(((('x' || substr(md5('aaaaaaaa-0000-4000-8000-00000000000a'), 1, 7))::bit(28)::int) % 10000)::text, 4, '0'),
  'the tag is derived from the user id, the same every time'
);

select is_empty(
  $$ select 1 from public.leaderboard('all') l
     where l::text ~ '@|[0-9a-f]{8}-[0-9a-f]{4}-' $$,
  'no email and no user id appear in any row'
);

select is(
  (select proargnames from pg_proc where oid = 'public.leaderboard(text, integer)'::regprocedure),
  array['p_scope', 'p_limit', 'rank', 'display_name', 'tag', 'total_xp', 'week_xp',
        'streak_weeks', 'is_me']::text[],
  'the board returns exactly rank, display_name, tag, total_xp, week_xp, streak_weeks, is_me'
);

select ok(
  (select not ('uuid'::regtype::oid = any(proallargtypes))
   from pg_proc where oid = 'public.leaderboard(text, integer)'::regprocedure),
  'no column of the board is a uuid'
);

select throws_ok(
  $$ select * from public.leaderboard('month') $$,
  '22023', null,
  'an unknown scope is refused'
);

-- D is third of three all time: with a top 1, D still gets their own row.
select pg_temp.act_as('dddddddd-0000-4000-8000-00000000000d');

select results_eq(
  $$ select rank, is_me from public.leaderboard('all', 1) order by rank $$,
  $$ values (1, false), (3, true) $$,
  'the caller''s row comes back even outside the top N'
);

select results_eq(
  $$ select rank, week_xp, is_me from public.leaderboard('week') where is_me $$,
  $$ values (3, 0, true) $$,
  'a caller with no XP this week still sees their own row, last'
);

-- C, hidden, still sees the board and their own place on it.
select pg_temp.act_as('cccccccc-0000-4000-8000-00000000000c');

select results_eq(
  $$ select rank, display_name, is_me from public.leaderboard('week') order by rank $$,
  $$ values (1, 'Hidden'::text, true), (2, 'Ali'::text, false), (3, 'Sami'::text, false) $$,
  'a hidden player sees the board and their own rank'
);

-- A switches the board off: B no longer sees A.
select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');
update public.profiles set leaderboard_visible = false;
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select results_eq(
  $$ select display_name from public.leaderboard('all') order by rank $$,
  $$ values ('Ali'::text), (null::text) $$,
  'switching it off hides the player from everyone else'
);

-- anon: no session.
reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  $$ select * from public.leaderboard('week') $$,
  '42501', null,
  'anon can''t call the board'
);

reset role;

select ok(
  (select total_xp_at = now() and week_xp_at = now() and total_xp = 900
   from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000a'),
  'the reached-at times are the server''s, and B''s attempt left A''s XP alone'
);

select * from finish();
rollback;
