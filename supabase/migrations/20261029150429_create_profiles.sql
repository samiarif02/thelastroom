-- profiles: one row per player (guest or linked), owned by that player (FR-62).
-- RLS + owner-only policies live here, in the migration that creates the table
-- (docs/rules/migrations.md rule 1). Guests from anonymous sign-in have the `authenticated`
-- role, so `to authenticated` covers them; the `anon` role (no session) gets nothing.

-- Server-controlled columns are set here, never trusted from the client (rule 6). The schema is
-- not exposed through the Data API, so this function can't be called as an RPC.
create schema if not exists private;

create function private.set_server_created_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
  else
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;

revoke all on function private.set_server_created_at() from public;

create table public.profiles (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  target_role text,
  nerves_level smallint check (nerves_level between 1 and 5),
  calm_mode boolean not null default false,
  interview_date date,
  -- D1: joining the Chapter 2 waitlist is this timestamp, not an email form.
  chapter_2_waitlist_at timestamptz
);

comment on table public.profiles is 'One row per player; owner-only RLS. Deleted with the auth user.';

alter table public.profiles enable row level security;

create policy "profiles: owner selects own row"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "profiles: owner inserts own row"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "profiles: owner updates own row"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- No delete policy: a profile goes when its auth user does (on delete cascade).

-- Least privilege on top of RLS: Supabase's default grants give every API role everything,
-- including TRUNCATE, which RLS does not filter.
revoke all on table public.profiles from anon, authenticated;
grant select, insert, update on table public.profiles to authenticated;

create trigger profiles_server_created_at
  before insert or update on public.profiles
  for each row execute function private.set_server_created_at();
