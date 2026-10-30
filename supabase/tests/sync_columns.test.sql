-- Brief 08's columns: what the device syncs. The owner writes and reads them (an upsert, as the
-- app sends it); another user and anon see none of them, the first name included; the checks
-- hold the closed sets; the client can never write user_id.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

-- The app's profile upsert (supabase-dart upsert onConflict user_id; user_id isn't sent).
prepare upsert_profile(text, int) as
  insert into public.profiles (
    first_name, experience, target_role, nerves_level, calm_mode, weekly_goal, auto_advance,
    onboarded, chapter_2_waitlist_at
  ) values ($1, 'freshGraduate', 'product', $2, true, 3, false, true, '2026-10-31 09:00+00')
  on conflict (user_id) do update set
    first_name = excluded.first_name, experience = excluded.experience,
    target_role = excluded.target_role, nerves_level = excluded.nerves_level,
    calm_mode = excluded.calm_mode, weekly_goal = excluded.weekly_goal,
    auto_advance = excluded.auto_advance, onboarded = excluded.onboarded,
    chapter_2_waitlist_at = excluded.chapter_2_waitlist_at;

select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok($$ execute upsert_profile('Sami', 4) $$, 'the owner creates their synced profile');
select lives_ok($$ execute upsert_profile('Sami', 5) $$, 'the same upsert again updates it ...');

select results_eq(
  $$ select user_id, first_name, experience, nerves_level, weekly_goal, auto_advance, onboarded
     from public.profiles $$,
  $$ values ('aaaaaaaa-0000-4000-8000-00000000000a'::uuid, 'Sami'::text, 'freshGraduate'::text,
             5::smallint, 3::smallint, false, true) $$,
  '... one row, owned by A, with the latest values'
);

select throws_ok(
  $$ update public.profiles set experience = 'wizard' $$,
  '23514', null,
  'experience is one of the app''s Experience names'
);

select throws_ok(
  $$ update public.profiles set first_name = repeat('x', 41) $$,
  '23514', null,
  'a first name is at most 40 characters'
);

select throws_ok(
  $$ update public.profiles set weekly_goal = 8 $$,
  '23514', null,
  'the weekly goal is 1-7 sessions'
);

-- The attempt with its picks, as the outbox sends it.
select lives_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, flags, completed_at,
       attempt_number, seed, beat_option_ids, follow_up_id, reply_option_id
     ) values (
       '22222222-0000-4000-8000-000000000002', 'mission_01', 1, 80, 60, 70, 50, 66, false,
       '{}', '2026-10-31 09:00+00', 1, 42, array['o1', 'e1', 'l1'], 'f1', 'r1'
     ) on conflict (attempt_id) do nothing $$,
  'an attempt syncs with its picks'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, completed_at, beat_option_ids
     ) values (gen_random_uuid(), 'mission_01', 1, 0, 0, 0, 0, 0, false, now(), '{}') $$,
  '23514', null,
  'an attempt has at least one beat pick'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, user_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, completed_at
     ) values (gen_random_uuid(), 'aaaaaaaa-0000-4000-8000-00000000000a', 'mission_01', 1, 0, 0,
               0, 0, 0, false, now()) $$,
  '42501', null,
  'a client can''t write user_id, even its own (it defaults to auth.uid())'
);

-- B signs in.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select is_empty(
  $$ select first_name from public.profiles $$,
  'user B can''t read user A''s first name'
);

select is_empty(
  $$ select beat_option_ids from public.mission_attempts $$,
  'user B can''t read user A''s picks'
);

-- anon: no session.
reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  $$ select first_name from public.profiles $$,
  '42501', null,
  'anon can''t read any profile'
);

reset role;

select is(
  (select count(*)::int from public.profiles),
  1,
  'one profile in all'
);

select * from finish();
rollback;
