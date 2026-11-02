-- Brief 35: a voice attempt syncs with the points it made and no picks; the check holds the
-- shape; the AI's transcript is stored with its verdict; another user reads none of it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

-- What the app's outbox sends for a voice attempt: no picks, the points made.
prepare voice_attempt(jsonb) as
  insert into public.mission_attempts (
    attempt_id, mission_id, content_schema_version, relevance_score, specificity_score,
    structure_score, adaptability_score, total_score, hinted, flags, completed_at,
    attempt_number, seed, voice_answer
  ) values (
    gen_random_uuid(), 'm08_voice', 2, 50, 100, 0, 100, 63, true, '{}', now(), 1, 0, $1
  );

select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok(
  $$ execute voice_attempt('{"made": ["m08_a", "m08_c"], "source": "ai", "seconds": 41}') $$,
  'a voice attempt syncs with the points it made and no picks'
);

select lives_ok(
  $$ execute voice_attempt('{"made": [], "source": "self_check", "seconds": 0}') $$,
  'a self-check with nothing ticked is still an attempt'
);

select results_eq(
  $$ select voice_answer ->> 'source' from public.mission_attempts order by voice_answer ->> 'source' $$,
  $$ values ('ai'), ('self_check') $$,
  'the owner reads both back'
);

select throws_ok(
  $$ execute voice_attempt('{"made": ["a"], "source": "guess", "seconds": 3}') $$,
  '23514', null,
  'the source is the AI or the self-check'
);

select throws_ok(
  $$ execute voice_attempt('{"made": "a", "source": "ai", "seconds": 3}') $$,
  '23514', null,
  'made is a list of point ids'
);

-- What the `score-voice` function inserts, as the player.
select lives_ok(
  $$ insert into public.ai_scores (
       mission_id, model, relevance_score, specificity_score, structure_score,
       adaptability_score, overall_score, basis, transcript, points_made
     ) values (
       'm08_voice', 'gemini-3.8-flash', 70, 60, 50, 80, 64,
       '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}',
       'Answer: I led the survey. Reply: I would ask first.', array['m08_a', 'm08_c']
     ) $$,
  'a voice verdict is stored with its transcript, never the audio'
);

select throws_ok(
  $$ insert into public.ai_scores (
       mission_id, model, relevance_score, specificity_score, structure_score,
       adaptability_score, overall_score, basis, transcript
     ) values (
       'm08_voice', 'x', 1, 1, 1, 1, 1,
       '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}',
       repeat('x', 6001)
     ) $$,
  '23514', null,
  'a transcript is capped'
);

select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select is_empty(
  $$ select voice_answer from public.mission_attempts $$,
  'another user reads no voice attempt'
);

select is_empty(
  $$ select transcript from public.ai_scores $$,
  'another user reads no transcript'
);

select * from finish();
rollback;
