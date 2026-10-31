-- Brief 08: what the device syncs, and least privilege per column.
--
-- 1. profiles gets what onboarding asks (brief 13) and the two play settings. The first name is
--    personal data: owner-only RLS (unchanged) is what keeps it private, and the app never puts
--    it in an analytics event or a log line.
-- 2. mission_attempts gets the picks. The restore on a fresh install (FR-61) recomputes each
--    score with the engine from these, so a restored attempt is scored exactly like the
--    original. Nullable: rows synced before this migration have none, and are not restored.
-- 3. Column-level grants replace the table-wide insert/update grants: a client can write only
--    its own content columns, never user_id (it defaults to auth.uid()) or created_at (server
--    time). RLS still applies on top. Additive only (docs/rules/migrations.md rule 4).

alter table public.profiles
  add column first_name text check (first_name is null or char_length(first_name) between 1 and 40),
  -- The app's Experience enum, by Dart name. A new case ships as a new migration first.
  add column experience text check (
    experience in ('student', 'freshGraduate', 'earlyCareer', 'switchingCareers')
  ),
  add column weekly_goal smallint check (weekly_goal between 1 and 7),
  add column auto_advance boolean not null default true,
  add column onboarded boolean not null default false;

alter table public.mission_attempts
  add column attempt_number integer check (attempt_number >= 1),
  add column seed integer,
  add column beat_option_ids text[] check (cardinality(beat_option_ids) between 1 and 8),
  add column follow_up_id text check (follow_up_id <> ''),
  add column reply_option_id text check (reply_option_id <> '');

revoke insert, update on table public.profiles from authenticated;
grant insert (
  target_role, nerves_level, calm_mode, interview_date, chapter_2_waitlist_at,
  first_name, experience, weekly_goal, auto_advance, onboarded
) on table public.profiles to authenticated;
grant update (
  target_role, nerves_level, calm_mode, interview_date, chapter_2_waitlist_at,
  first_name, experience, weekly_goal, auto_advance, onboarded
) on table public.profiles to authenticated;

revoke insert on table public.mission_attempts from authenticated;
grant insert (
  attempt_id, mission_id, content_schema_version,
  relevance_score, specificity_score, structure_score, adaptability_score, total_score,
  hinted, flags, completed_at,
  attempt_number, seed, beat_option_ids, follow_up_id, reply_option_id
) on table public.mission_attempts to authenticated;
