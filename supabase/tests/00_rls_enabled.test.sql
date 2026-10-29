-- Schema-wide guard: no table in an API-exposed schema is ever without RLS, and the anon role
-- (no session) holds no privilege on any of them. check:rls is the same rule, statically.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

select is_empty(
  $$ select tablename from pg_tables where schemaname = 'public' and not rowsecurity $$,
  'every public table has row level security enabled'
);

select is_empty(
  $$ select c.relname
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r'
       and not exists (select 1 from pg_policy p where p.polrelid = c.oid) $$,
  'every public table has at least one policy'
);

select is_empty(
  $$ select table_name, privilege_type
     from information_schema.role_table_grants
     where grantee = 'anon' and table_schema = 'public' $$,
  'the anon role holds no table privilege in public'
);

select * from finish();
rollback;
