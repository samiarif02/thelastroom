-- profiles: owner-only RLS (FR-62). User B can't read or write user A's row; anon gets nothing;
-- a client can't set created_at or another user's user_id.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'a@example.test', true),
  ('bbbbbbbb-0000-4000-8000-00000000000b', 'b@example.test', true);

-- Become a signed-in user (guests from anonymous sign-in have the authenticated role too).
create function pg_temp.act_as(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true),
         set_config('role', 'authenticated', true);
$$;

-- A signs in and creates their profile, trying to backdate created_at.
select pg_temp.act_as('aaaaaaaa-0000-4000-8000-00000000000a');

select lives_ok(
  $$ insert into public.profiles (target_role, nerves_level, created_at)
     values ('general', 3, '2000-01-01') $$,
  'a user can create their own profile (user_id defaults to auth.uid())'
);

select results_eq(
  $$ select user_id, created_at = now() from public.profiles $$,
  $$ values ('aaaaaaaa-0000-4000-8000-00000000000a'::uuid, true) $$,
  'the owner sees exactly their row, and created_at is the server time, not the client value'
);

select isnt_empty(
  $$ update public.profiles set created_at = '2000-01-01', calm_mode = true returning 1 $$,
  'the owner can update their row ...'
);
select ok(
  (select created_at = now() and calm_mode from public.profiles),
  '... but created_at keeps the server value'
);

select throws_ok(
  $$ insert into public.profiles (user_id) values ('bbbbbbbb-0000-4000-8000-00000000000b') $$,
  '42501',
  null,
  'a user can''t insert a profile for another user'
);

select throws_ok(
  $$ update public.profiles set user_id = 'bbbbbbbb-0000-4000-8000-00000000000b' $$,
  '42501',
  null,
  'a user can''t move their row to another user''s id'
);

select throws_ok(
  $$ update public.profiles set nerves_level = 6 $$,
  '23514',
  null,
  'nerves_level is 1-5'
);

-- B signs in.
select pg_temp.act_as('bbbbbbbb-0000-4000-8000-00000000000b');

select is_empty(
  $$ select 1 from public.profiles $$,
  'user B can''t select user A''s profile'
);

select is_empty(
  $$ update public.profiles set target_role = 'hijacked' returning 1 $$,
  'user B''s update matches none of user A''s rows'
);

select throws_ok(
  $$ delete from public.profiles $$,
  '42501',
  null,
  'nobody can delete a profile through the API (it goes with the auth user)'
);

-- The anon role: no session at all.
reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  $$ select 1 from public.profiles $$,
  '42501',
  null,
  'anon can''t select profiles'
);

select throws_ok(
  $$ insert into public.profiles (user_id) values ('aaaaaaaa-0000-4000-8000-00000000000a') $$,
  '42501',
  null,
  'anon can''t insert profiles'
);

-- Back to the superuser to check what B's attempts actually did to A's row.
reset role;

select results_eq(
  $$ select target_role, calm_mode from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  $$ values ('general'::text, true) $$,
  'user A''s profile is untouched by user B'
);

select is(
  (select count(*)::int from public.profiles),
  1,
  'nothing else was written'
);

select * from finish();
rollback;
