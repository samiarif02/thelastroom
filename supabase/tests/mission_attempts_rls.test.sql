-- mission_attempts: owner-only, append-only RLS (FR-60, FR-62). Same attempt_id twice is one
-- row; user B can't read, write, update or delete user A's attempts; anon gets nothing; a client
-- can't set created_at or another user's user_id.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

-- The outbox's insert: idempotent on the device-generated attempt_id.
prepare sync_attempt(uuid) as
  insert into public.mission_attempts (
    attempt_id, mission_id, content_schema_version,
    relevance_score, specificity_score, structure_score, adaptability_score, total_score,
    hinted, flags, completed_at, created_at
  ) values (
    $1, 'mission_01', 1, 80, 60, 70, 50, 66, false, array['vague'], '2026-10-28 20:00+00', '2000-01-01'
  )
  on conflict (attempt_id) do nothing;

select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok(
  $$ execute sync_attempt('11111111-0000-4000-8000-000000000001') $$,
  'a user can sync their own attempt'
);

select lives_ok(
  $$ execute sync_attempt('11111111-0000-4000-8000-000000000001') $$,
  'syncing the same attempt_id again is not an error ...'
);

select results_eq(
  $$ select attempt_id, user_id, created_at = now(), completed_at = '2026-10-28 20:00+00'
     from public.mission_attempts $$,
  $$ values ('11111111-0000-4000-8000-000000000001'::uuid,
             'aaaaaaaa-0000-4000-8000-00000000000a'::uuid, true, true) $$,
  '... and leaves one row, owned by A, with the server''s created_at and the device''s completed_at'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, user_id, mission_id, content_schema_version, relevance_score,
       specificity_score, structure_score, adaptability_score, total_score, hinted, completed_at
     ) values (
       gen_random_uuid(), 'bbbbbbbb-0000-4000-8000-00000000000b', 'mission_01', 1, 0, 0, 0, 0, 0,
       false, now()
     ) $$,
  '42501',
  null,
  'a user can''t insert an attempt for another user'
);

select throws_ok(
  $$ update public.mission_attempts set total_score = 100 $$,
  '42501',
  null,
  'attempts are append-only: the owner can''t update one'
);

select throws_ok(
  $$ delete from public.mission_attempts $$,
  '42501',
  null,
  'attempts are append-only: the owner can''t delete one'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, flags, completed_at
     ) values (gen_random_uuid(), 'mission_01', 1, 0, 0, 0, 0, 0, false, array['shouting'], now()) $$,
  '23514',
  null,
  'flags must be the engine''s wire names'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, completed_at
     ) values (gen_random_uuid(), 'mission_01', 1, 101, 0, 0, 0, 0, false, now()) $$,
  '23514',
  null,
  'scores are 0-100'
);

-- B signs in.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select is_empty(
  $$ select 1 from public.mission_attempts $$,
  'user B can''t select user A''s attempts'
);

select lives_ok(
  $$ execute sync_attempt('11111111-0000-4000-8000-000000000001') $$,
  'user B replaying user A''s attempt_id is ignored, not an error'
);

select is_empty(
  $$ select 1 from public.mission_attempts $$,
  '... and B still sees nothing'
);

select throws_ok(
  $$ update public.mission_attempts set total_score = 0 $$,
  '42501',
  null,
  'user B can''t update user A''s attempts'
);

select throws_ok(
  $$ delete from public.mission_attempts $$,
  '42501',
  null,
  'user B can''t delete user A''s attempts'
);

-- The anon role: no session at all.
reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  $$ select 1 from public.mission_attempts $$,
  '42501',
  null,
  'anon can''t select attempts'
);

select throws_ok(
  $$ execute sync_attempt(gen_random_uuid()) $$,
  '42501',
  null,
  'anon can''t insert attempts'
);

reset role;

select results_eq(
  $$ select user_id, total_score from public.mission_attempts $$,
  $$ values ('aaaaaaaa-0000-4000-8000-00000000000a'::uuid, 66::smallint) $$,
  'one attempt in total, still user A''s and unchanged'
);

select * from finish();
rollback;
