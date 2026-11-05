-- Issue 74: the board ranks server-verified XP only. A client can't write an XP column or an AI
-- verdict; the server's recount credits each mission once, from its best verified score, with
-- the engine's room XP (20 + best ÷ 2 + 30, packages/engine/lib/src/progression.dart), so
-- replays can't farm; the week and the streak come from when the verdicts landed; a client's
-- own attempt log counts for nothing; hidden players stay hidden.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true),
  ('cccccccc-0000-4000-8000-00000000000c', 'c@example.test', true),
  ('dddddddd-0000-4000-8000-00000000000d', 'd@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

create function pg_temp.act_as_server() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true),
         set_config('role', 'service_role', true);
$$;

create function pg_temp.monday() returns date language sql as $$
  select date_trunc('week', now() at time zone 'utc')::date;
$$;

-- What the `score` functions insert (service role, user_id from the caller's verified JWT).
prepare verdict(uuid, text, smallint) as
  insert into public.ai_scores (
    user_id, mission_id, model,
    relevance_score, specificity_score, structure_score, adaptability_score, overall_score, basis
  ) values (
    $1, $2, 'gemini-3.8-flash', 50, 50, 50, 50, $3,
    '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}'
  );

-- A verdict that landed at a given time (the created_at trigger is off for these, below).
prepare verdict_at(uuid, text, smallint, timestamptz) as
  insert into public.ai_scores (
    user_id, mission_id, model,
    relevance_score, specificity_score, structure_score, adaptability_score, overall_score, basis,
    created_at
  ) values (
    $1, $2, 'gemini-3.8-flash', 50, 50, 50, 50, $3,
    '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}', $4
  );

create function pg_temp.board(uid uuid) returns table (total_xp int, week_xp int, week_start date, streak_weeks int)
language sql as $$
  select p.total_xp, p.week_xp, p.week_start, p.streak_weeks::int
  from public.profiles p where p.user_id = uid;
$$;

-- 1. A modified client.
select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select throws_ok(
  $$ insert into public.profiles (first_name, total_xp, week_xp, week_start, streak_weeks)
     values ('Cheat', 99999, 99999, date_trunc('week', now())::date, 99) $$,
  '42501', null,
  'a client can''t report its own XP, week or streak'
);

select lives_ok(
  $$ insert into public.profiles (first_name, leaderboard_visible) values ('Sami', true)
     on conflict (user_id) do update set leaderboard_visible = excluded.leaderboard_visible $$,
  'a client still sets its name and "Show me on the leaderboard"'
);

select throws_ok(
  $$ update public.profiles set week_xp = 99999, streak_weeks = 99 $$,
  '42501', null,
  'a client can''t raise its XP afterwards either'
);

select throws_ok(
  $$ insert into public.ai_scores (mission_id, model, relevance_score, specificity_score,
       structure_score, adaptability_score, overall_score, basis)
     values ('m01_the_opportunity', 'gemini-3.8-flash', 100, 100, 100, 100, 100,
       '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}') $$,
  '42501', null,
  'a client can''t insert a verdict for itself'
);

select throws_ok(
  $$ select private.recount_verified_xp('aaaaaaaa-0000-4000-8000-00000000000a') $$,
  '42501', null,
  'a client can''t call the recount'
);

select lives_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, completed_at
     ) values (gen_random_uuid(), 'm03_the_experience_gap', 2, 100, 100, 100, 100, 100, false, now()) $$,
  'a client still syncs its attempts (even a claimed 100) ...'
);

reset role;

select is(
  (select total_xp from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a')),
  0,
  '... which earn no board XP: nothing the server scored yet'
);

-- 2. The server's verdicts for A, all this week.
select pg_temp.act_as_server();
execute verdict('aaaaaaaa-0000-4000-8000-00000000000a', 'm01_the_opportunity', 60);
reset role;

select results_eq(
  $$ select * from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a') $$,
  $$ values (80, 80, pg_temp.monday(), 1) $$,
  'a verified 60 is the engine''s first-clear room XP: 20 + 30 + 30 = 80, this week, a 1-week streak'
);

select pg_temp.act_as_server();
execute verdict('aaaaaaaa-0000-4000-8000-00000000000a', 'm01_the_opportunity', 40);
reset role;

select is(
  (select total_xp from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a')),
  80,
  'a weaker replay adds nothing'
);

select pg_temp.act_as_server();
execute verdict('aaaaaaaa-0000-4000-8000-00000000000a', 'm01_the_opportunity', 91);
reset role;

select is(
  (select total_xp from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a')),
  95,
  'a better replay counts only the improvement (20 + 45 + 30 = 95)'
);

select pg_temp.act_as_server();
do $$
begin
  for i in 1..30 loop
    insert into public.ai_scores (
      user_id, mission_id, model,
      relevance_score, specificity_score, structure_score, adaptability_score, overall_score, basis
    ) values (
      'aaaaaaaa-0000-4000-8000-00000000000a', 'm01_the_opportunity', 'gemini-3.8-flash',
      100, 100, 100, 100, 100,
      '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}'
    );
  end loop;
end;
$$;
reset role;

select is(
  (select total_xp from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a')),
  100,
  '30 perfect replays of one mission earn its cap, 100, and no more'
);

select pg_temp.act_as_server();
execute verdict('aaaaaaaa-0000-4000-8000-00000000000a', 'm02_tell_me_about_yourself', 0);
reset role;

select results_eq(
  $$ select total_xp, week_xp from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a') $$,
  $$ values (150, 150) $$,
  'a second mission adds its own room XP (a verified 0 still earns 50)'
);

-- 3. B played over three weeks; C last scored three weeks ago; D is hidden.
alter table public.ai_scores disable trigger ai_scores_server_created_at;
execute verdict_at('bbbbbbbb-0000-4000-8000-00000000000b', 'm02_tell_me_about_yourself', 40,
  (pg_temp.monday() - 13)::timestamp at time zone 'utc');
execute verdict_at('bbbbbbbb-0000-4000-8000-00000000000b', 'm01_the_opportunity', 50,
  (pg_temp.monday() - 6)::timestamp at time zone 'utc');
execute verdict_at('cccccccc-0000-4000-8000-00000000000c', 'm01_the_opportunity', 100,
  (pg_temp.monday() - 20)::timestamp at time zone 'utc');
alter table public.ai_scores enable trigger ai_scores_server_created_at;

select pg_temp.act_as_server();
execute verdict('bbbbbbbb-0000-4000-8000-00000000000b', 'm01_the_opportunity', 70);
execute verdict('dddddddd-0000-4000-8000-00000000000d', 'm01_the_opportunity', 100);
execute verdict('dddddddd-0000-4000-8000-00000000000d', 'm02_tell_me_about_yourself', 100);
reset role;

select results_eq(
  $$ select * from pg_temp.board('bbbbbbbb-0000-4000-8000-00000000000b') $$,
  $$ values (155, 10, pg_temp.monday(), 3) $$,
  'B: 85 + 70 in all; this week gained 10 (m01 went 50 -> 70); scored three weeks running'
);

select results_eq(
  $$ select * from pg_temp.board('cccccccc-0000-4000-8000-00000000000c') $$,
  $$ values (100, 100, pg_temp.monday() - 21, 1) $$,
  'C: the week and streak are the week C last scored in (the board reads them as stale)'
);

select pg_temp.act_as('dddddddd-0000-4000-8000-00000000000d');
update public.profiles set leaderboard_visible = false;

-- 4. The board.
select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select results_eq(
  $$ select rank, total_xp, week_xp, streak_weeks, is_me from public.leaderboard('all') order by rank $$,
  $$ values (1, 155, 10, 3, false), (2, 150, 150, 1, true), (3, 100, 0, 0, false) $$,
  'all time ranks the verified totals; C''s old week and streak count 0; hidden D is left out'
);

select results_eq(
  $$ select rank, week_xp, is_me from public.leaderboard('week') order by rank $$,
  $$ values (1, 150, true), (2, 10, false) $$,
  'this week ranks verified XP gained this week'
);

select pg_temp.act_as('dddddddd-0000-4000-8000-00000000000d');

select results_eq(
  $$ select rank, total_xp, is_me from public.leaderboard('all') where is_me $$,
  $$ values (1, 200, true) $$,
  'a hidden player still sees their own verified rank'
);

-- 5. The backfill: a number reported before issue 74 is replaced by the verified one.
reset role;
update public.profiles set total_xp = 99999, week_xp = 99999, streak_weeks = 99
where user_id = 'aaaaaaaa-0000-4000-8000-00000000000a';
select private.recount_verified_xp('aaaaaaaa-0000-4000-8000-00000000000a');

select results_eq(
  $$ select total_xp, week_xp, streak_weeks from pg_temp.board('aaaaaaaa-0000-4000-8000-00000000000a') $$,
  $$ values (150, 150, 1) $$,
  'the recount replaces a reported number with the verified one'
);

select pg_temp.act_as('cccccccc-0000-4000-8000-00000000000c');
insert into public.profiles (first_name) values ('Late')
on conflict (user_id) do update set first_name = excluded.first_name;

select results_eq(
  $$ select total_xp, first_name from public.profiles $$,
  $$ values (100, 'Late'::text) $$,
  'a profile the server created first still takes the player''s own sync'
);

select * from finish();
rollback;
