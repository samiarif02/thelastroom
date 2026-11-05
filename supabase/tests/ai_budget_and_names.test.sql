-- Issue 74 (security audit 2026-11-05): the AI quota counts units (a voice answer is 3), a
-- global daily budget caps all players together and gives a refused claim back, no client can
-- reach the budget, and first names are cleaned of invisible and direction-changing characters.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true),
  ('cccccccc-0000-4000-8000-00000000000c', 'c@example.test', true),
  ('dddddddd-0000-4000-8000-00000000000d', 'd@example.test', true);

create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

-- A: voice answers, 3 units each.
select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select results_eq(
  $$ select bool_and(public.claim_ai_score(3)) from generate_series(1, 10) $$,
  $$ values (true) $$,
  'ten voice answers fit in a player''s 30 units'
);
select is(public.claim_ai_score(3), false, 'the eleventh is refused');
select is(public.claim_ai_score(), false, 'and so is a built answer: the day''s 30 units are spent');

-- B: the units are checked.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select throws_ok($$ select public.claim_ai_score(0) $$, '22023', null, 'no claim of 0 units');
select throws_ok($$ select public.claim_ai_score(-30) $$, '22023', null, 'no negative claim to refill a budget');
select throws_ok($$ select public.claim_ai_score(4) $$, '22023', null, 'no claim above 3 units');
select throws_ok(
  $$ select used from private.ai_score_budget $$,
  '42501', null,
  'a client can''t read the budget'
);

-- The budget, nearly spent.
reset role;
update private.ai_score_budget set used = 2999 where day = (now() at time zone 'utc')::date;

select pg_temp.act_as('cccccccc-0000-4000-8000-00000000000c');
select is(public.claim_ai_score(3), false, 'a voice answer past the day''s budget is refused ...');
select results_eq(
  $$ select coalesce(sum(used), 0)::int from public.ai_score_usage $$,
  $$ values (0) $$,
  '... and the player''s units are given back'
);
select is(public.claim_ai_score(), true, 'a built answer still fits the last unit');

select pg_temp.act_as('dddddddd-0000-4000-8000-00000000000d');
select is(public.claim_ai_score(), false, 'then the budget is spent for everyone');

-- Names.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');
insert into public.profiles (first_name) values (E'  Sa\u202Emi\u200B\u0007 ');

select results_eq(
  $$ select first_name from public.profiles $$,
  $$ values ('Sami'::text) $$,
  'a first name is stored without control, zero-width or direction-override characters'
);

update public.profiles set first_name = E'\u200B\u2066';

select results_eq(
  $$ select first_name from public.profiles $$,
  $$ values (null::text) $$,
  'a name of nothing visible is no name'
);

select * from finish();
rollback;
