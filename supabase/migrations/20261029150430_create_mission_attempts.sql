-- mission_attempts: every completed attempt, synced from the device's outbox (FR-60, FR-62).
-- Append-only: owners select and insert their own rows; there is no update or delete policy.
--
-- attempt_id is generated on the device, so a retried sync is idempotent: the outbox inserts
-- with `on conflict (attempt_id) do nothing` (supabase-dart: upsert with ignoreDuplicates), which
-- needs no update policy (docs/rules/migrations.md rule 5).

create table public.mission_attempts (
  attempt_id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  mission_id text not null check (mission_id <> ''),
  content_schema_version integer not null check (content_schema_version >= 1),
  -- The engine's four dimensions and the weighted total, each normalised to 0-100.
  relevance_score smallint not null check (relevance_score between 0 and 100),
  specificity_score smallint not null check (specificity_score between 0 and 100),
  structure_score smallint not null check (structure_score between 0 and 100),
  adaptability_score smallint not null check (adaptability_score between 0 and 100),
  total_score smallint not null check (total_score between 0 and 100),
  hinted boolean not null,
  -- The engine's closed Flag enum (wire names). A new flag ships as a new migration first.
  flags text[] not null default '{}' check (
    flags <@ array['vague', 'we_not_i', 'generic', 'blame', 'off_question', 'rambling', 'memorized']
  ),
  -- When the player finished, by the device's clock (attempts can sync days later).
  completed_at timestamptz not null,
  -- When the server received it. Set by trigger; a client value is overwritten.
  created_at timestamptz not null default now()
);

comment on table public.mission_attempts is 'Append-only attempt log; owner-only RLS; upsert on attempt_id.';

-- Restore on a fresh install reads one user's attempts in order (FR-61).
create index mission_attempts_user_completed_idx
  on public.mission_attempts (user_id, completed_at);

alter table public.mission_attempts enable row level security;

create policy "mission_attempts: owner selects own rows"
  on public.mission_attempts for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "mission_attempts: owner inserts own rows"
  on public.mission_attempts for insert to authenticated
  with check ((select auth.uid()) = user_id);

revoke all on table public.mission_attempts from anon, authenticated;
grant select, insert on table public.mission_attempts to authenticated;

create trigger mission_attempts_server_created_at
  before insert on public.mission_attempts
  for each row execute function private.set_server_created_at();
