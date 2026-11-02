-- Brief 35: voice missions. A spoken answer syncs like a built one, and the AI's verdict on it
-- keeps what it heard.
--
-- 1. mission_attempts.voice_answer: a voice attempt has no picks (beat_option_ids, follow_up_id
--    and reply_option_id stay null). Instead it carries which of the mission's listen-for points
--    the answer made and who judged it: {"made": [point ids], "source": "ai" | "self_check",
--    "seconds": whole seconds spoken}. The app's engine rescores a restored attempt from
--    `made`, exactly as the device scored it (ADR 0006: progress stays on the engine).
-- 2. ai_scores.transcript and points_made: what the `score-voice` function heard and which points
--    it found. The audio itself is never stored, anywhere; only this text and the scores.
--    Owner-only RLS (unchanged) keeps the transcript private; it is never logged.
--
-- Additive only (docs/rules/migrations.md rule 4): nullable columns, so rows from before stay
-- valid; the column grants keep least privilege. Tests: supabase/tests/voice_answers.test.sql.
alter table public.mission_attempts
  add column voice_answer jsonb check (
    voice_answer is null
    or (
      jsonb_typeof(voice_answer) = 'object'
      and jsonb_typeof(voice_answer -> 'made') = 'array'
      and jsonb_array_length(voice_answer -> 'made') <= 7
      and voice_answer ->> 'source' in ('ai', 'self_check')
      and jsonb_typeof(voice_answer -> 'seconds') = 'number'
    )
  );

grant insert (voice_answer) on table public.mission_attempts to authenticated;

alter table public.ai_scores
  add column transcript text check (transcript is null or char_length(transcript) between 1 and 6000),
  add column points_made text[] check (points_made is null or cardinality(points_made) <= 7);

grant insert (transcript, points_made) on table public.ai_scores to authenticated;
