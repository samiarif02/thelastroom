-- Brief 30: how each beat was played, so a restored attempt scores exactly like the original.
--
-- Since wave 5 a beat's points depend on the reason given ("why that line?") and on how fast it
-- was picked (a guess scores 0). The picks alone (beat_option_ids) can't reproduce that, so a
-- fresh install restored a different score from the one the player saw. beat_plays carries,
-- per beat in beat order, the reason id (null where none was asked) and the time to decide in
-- microseconds (null where not measured): {"reason_id": text|null, "decided_us": int|null}.
--
-- Nullable: rows synced before this migration have none and restore at full credit, as before.
-- Additive only (docs/rules/migrations.md rule 4); the column grant keeps least privilege.

alter table public.mission_attempts
  add column beat_plays jsonb check (
    beat_plays is null
    or (jsonb_typeof(beat_plays) = 'array' and jsonb_array_length(beat_plays) between 1 and 8)
  );

grant insert (beat_plays) on table public.mission_attempts to authenticated;
