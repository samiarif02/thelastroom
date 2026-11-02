# Brief 35: One voice mission: speak, then build (worktree w2)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w2`, branch
`feat/35-voice-mission` from `origin/lead/wave-6`. Session: thelastroom-75. Read
`docs/briefs/wave-6.md` first. **PR green by Tue 3 Nov, 22:00.**

## Why

The reviewer: picking options teaches *what* a strong answer is, but a job-seeker also has to
*say* it, out loud, to a recruiter. From Chapter 2 on the player should speak. The owner chose
**one voice mission** for v1, and it's **the last mission in the game, mixing both**: spoken
answers *and* the multiple-choice beats players already know (owner, 2026-11-02). The rest of
Chapter 2 stays "coming soon".

## The mission: Mission 8, "Say It Out Loud" (Chapter 2 preview)

Unlocked by finishing Mission 7; on the tower as the first room of Chapter 2. A new content file
(`packages/content/.../m08_...dart`) with its `practises` line, scene, question, beats,
follow-up and lessons, written in Chapter 1's voice and validated like the others.

The flow, using the existing mission player wherever it can:

1. **The recruiter speaks.** Every interviewer line in this mission is read aloud by text to
   speech (`flutter_tts` on Android/iOS, the browser's speech synthesis on web), in sync with the
   typewriter subtitle. A mute toggle; the subtitles stay. If TTS isn't available, subtitles
   only, no error.
2. **Speak first.** After the question lands, the player answers **out loud** before seeing any
   options (this replaces "draft first" here): the recording step below.
3. **Then build it.** The usual three multiple-choice beats and the reason step, exactly as in
   Chapter 1.
4. **The follow-up is spoken too:** the interviewer pushes back, out loud, and the player
   answers out loud.
5. **The debrief** shows the built answer's score as today, plus "Your spoken answer": what the
   AI heard (the transcript) and its score with one sentence of basis per dimension, beside the
   version they built. That's the lesson: the gap between what you know and what you say.

## The recording step (the reviewer's exact asks)

- A large record button; a live level meter and elapsed time.
- **Silence:** after **5 seconds** below a level threshold while recording, the recording
  **pauses by itself** and says so ("Paused: you went quiet. Continue when you're ready").
- **Continue** resumes the *same* recording from where it paused (append, don't restart).
- **Delete** throws the whole take away (with a confirm) and returns to an empty recorder.
- **Done** submits. A cap (90 s) so nobody records an essay. Re-recording before Done is free.
- Microphone permission asked here, behind a one-line explainer; refused → a designed state
  that offers to skip the spoken part (the beats still play).
- Packages: `record` (amplitude stream for the silence check; web supported) and `flutter_tts`.
  Android `RECORD_AUDIO`, iOS `NSMicrophoneUsageDescription`. Say so in the PR.

## Scoring the spoken answer

- A new Edge Function `supabase/functions/score-voice/`: receives the audio (≤ 90 s, a size
  limit), asks Gemini (the same model and key as `score`; import its helpers from
  `../score/gemini.ts`, don't change them) to **transcribe and score the content** on the same
  four dimensions with one sentence of basis each. **Never accent, pronunciation or fluency
  style**: say so in the prompt and the UI ("We score what you said, not how you sound"). Same
  JWT, same 30-a-day quota (`claim_ai_score()`), temperature 0.
- **Privacy:** the audio is sent for scoring and **not stored** anywhere; only the transcript
  and scores go in `ai_scores` (owner-only RLS). Never the player's name.
- Offline / no backend / timeout: the debrief says the spoken part needs a connection and shows
  the built answer's offline score; the recording is never lost mid-mission (kept until the
  debrief).

## Owns

`features/voice/**` (new: recorder, silence detector, TTS service behind an interface so tests
fake it), the voice step's hook into `features/mission` (keep the change small and tell
thelastroom-de, who restyles mission screens), the Mission 8 content, `score-voice`, its pgTAP
test if a migration is needed, the permission lines in `android/` and `ios/`, the pubspec lines,
appended events (`voice_answer_recorded` with `seconds`, `paused_count`, `retakes`;
`voice_answer_scored` with `score_bucket`; never audio or text). Use today's tokens and
components only; adopt 33's look after it merges.

## Acceptance

- [ ] Mission 8 unlocks after Mission 7 and plays: spoken question → recorded answer → beats →
      spoken follow-up → debrief with transcript and AI score beside the built score.
- [ ] Silence for 5 s pauses; Continue appends; Delete clears; 90 s cap (unit tests on the
      silence detector with a fake amplitude stream; widget tests for every recorder state).
- [ ] Recruiter lines are spoken (fake TTS in tests); mute works; no TTS → subtitles only.
- [ ] `score-voice` Deno tests (mocked Gemini), and one live run with the owner's key
      (`supabase functions serve --env-file ../thelastroom/.env`), output in the PR.
- [ ] Offline, mic refused, quota spent: each a designed state, never an error.
- [ ] All gates (incl. the db job if you add a migration), CI green, `docs/status/35.md`
      current. Message thelastroom-w4-fe with the PR link.
