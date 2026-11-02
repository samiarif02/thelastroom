-- Brief 30's column: the owner syncs how each beat was played; the check holds its shape;
-- another user can't read it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, flags, completed_at,
       attempt_number, seed, beat_option_ids, follow_up_id, reply_option_id, beat_plays
     ) values (
       '33333333-0000-4000-8000-000000000003', 'mission_01', 2, 80, 60, 70, 50, 66, false,
       '{}', '2026-11-02 09:00+00', 1, 42, array['o1', 'e1', 'l1'], 'f1', 'r1',
       '[{"reason_id": "o_r1", "decided_us": 3200000},
         {"reason_id": null, "decided_us": 900000},
         {"reason_id": "l_r2", "decided_us": null}]'
     ) $$,
  'an attempt syncs with how each beat was played'
);

select results_eq(
  $$ select jsonb_array_length(beat_plays) from public.mission_attempts $$,
  $$ values (3) $$,
  'the owner reads it back'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, completed_at, beat_plays
     ) values (gen_random_uuid(), 'mission_01', 2, 0, 0, 0, 0, 0, false, now(), '{"a": 1}') $$,
  '23514', null,
  'beat_plays is a list, one entry per beat'
);

select throws_ok(
  $$ insert into public.mission_attempts (
       attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
       structure_score, adaptability_score, total_score, hinted, completed_at, beat_plays
     ) values (gen_random_uuid(), 'mission_01', 2, 0, 0, 0, 0, 0, false, now(), '[]') $$,
  '23514', null,
  'an attempt with beat_plays has at least one beat'
);

select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select is_empty(
  $$ select beat_plays from public.mission_attempts $$,
  'another user reads none of it'
);

select * from finish();
rollback;
