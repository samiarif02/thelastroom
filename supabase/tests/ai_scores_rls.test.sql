-- Brief 22: the AI verdicts are the owner's alone, the quota counts per player per day and stops
-- at 30, and nobody can write the counter or anyone else's verdict.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

create function pg_temp.act_as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true),
         set_config('role', 'anon', true);
$$;

-- What the `score` function inserts, as the player.
prepare save_score(smallint) as
  insert into public.ai_scores (
    attempt_id, mission_id, model,
    relevance_score, specificity_score, structure_score, adaptability_score, overall_score, basis
  ) values (
    '0b9a8c7d-1e2f-4a3b-8c4d-5e6f7a8b9c0d', 'm01_the_opportunity', 'gemini-3.8-flash',
    82, 40, 70, 90, $1,
    '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}'
  );

select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok($$ execute save_score(68) $$, 'the owner saves a verdict');

select results_eq(
  $$ select user_id, overall_score from public.ai_scores $$,
  $$ values ('aaaaaaaa-0000-4000-8000-00000000000a'::uuid, 68::smallint) $$,
  'it is theirs, with user_id from their JWT'
);

select throws_ok($$ execute save_score(101) $$, '23514', null, 'a score is 0-100');

select throws_ok(
  $$ insert into public.ai_scores (mission_id, model, relevance_score, specificity_score,
       structure_score, adaptability_score, overall_score, basis)
     values ('m01_the_opportunity', 'gemini-3.8-flash', 1, 1, 1, 1, 1, '{"relevance":"a."}') $$,
  '23514', null, 'the basis has a sentence for every number'
);

select throws_ok(
  $$ insert into public.ai_scores (user_id, mission_id, model, relevance_score, specificity_score,
       structure_score, adaptability_score, overall_score, basis)
     values ('bbbbbbbb-0000-4000-8000-00000000000b', 'm01_the_opportunity', 'x', 1, 1, 1, 1, 1,
       '{"relevance":"a.","specificity":"b.","structure":"c.","adaptability":"d.","overall":"e."}') $$,
  '42501', null, 'a client can never write user_id'
);

select throws_ok($$ update public.ai_scores set overall_score = 100 $$, '42501', null, 'verdicts are append-only');

-- The quota: 30 a day, then refused.
select results_eq(
  $$ select bool_and(public.claim_ai_score()) from generate_series(1, 30) $$,
  $$ values (true) $$,
  'the first 30 scores of the day are granted'
);
select is(public.claim_ai_score(), false, 'the 31st is refused');
select results_eq(
  $$ select used from public.ai_score_usage $$,
  $$ values (30) $$,
  'the count stops at the limit'
);
select throws_ok(
  $$ update public.ai_score_usage set used = 0 $$,
  '42501', null, 'a player cannot reset their own counter'
);

select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select is(public.claim_ai_score(), true, 'another player has their own quota');
select is_empty($$ select 1 from public.ai_scores $$, 'B sees none of A''s verdicts');
select results_eq(
  $$ select count(*)::int from public.ai_score_usage $$,
  $$ values (1) $$,
  'B sees only their own usage row'
);

select pg_temp.act_as_anon();
select throws_ok($$ select public.claim_ai_score() $$, '42501', null, 'anon cannot take a score');

select * from finish();
rollback;
