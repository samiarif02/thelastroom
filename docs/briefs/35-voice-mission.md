# Brief 35: Voice missions: the player that speaks and listens (worktree w2)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w2`, branch
`feat/35-voice-missions` from `origin/lead/wave-6`. Session: thelastroom-75. Read
`docs/briefs/wave-6.md` first. **PR green by Tue 3 Nov, 22:00.**

## Why

The reviewer: picking options teaches *what* a strong answer is, but a job-seeker also has to
*say* it, out loud, to a recruiter. The owner (2026-11-02): **Chapter 2 is all voice; Chapter 3
mixes voice and multiple-choice missions.** You build the voice mission player and its scoring;
briefs 37 and 38 write the missions against the contract, in parallel.

## The contract (on `lead/wave-6`)

`Mission.answerMode` (`choices` | `voice`) and `Mission.voice` (`VoicePrompt`: 3–4
`ListenFor` points, each tied to a `Dimension`; a spoken `followUp` with 1–3 points of its own;
a `lessonId`; `maxSeconds`, 90 by default). A voice mission has no beats or option follow-ups;
`validateContent` checks all of it. Ask thelastroom-w4-fe before changing a signature.

## The voice mission, as the player meets it

1. **The recruiter speaks.** Every interviewer line (scene, question, follow-up) is read aloud
   by text to speech (`flutter_tts` on Android/iOS, the browser's speech synthesis on web), in
   step with the typewriter subtitle. A mute toggle; subtitles always on. No TTS → subtitles
   only, no error.
2. **The player answers out loud** (the recorder below).
3. **The follow-up**: the interviewer pushes back out loud; the player answers out loud.
4. **The debrief**: the four scores with one sentence of basis each, the transcript ("What we
   heard"), which `listenFor` points were made and which were missed, and the one lesson. Same
   dossier look as Chapter 1.

## The recorder (the reviewer's exact asks)

- A large record button, a live level meter, elapsed time.
- **Silence:** **5 seconds** below a level threshold while recording → the recording **pauses
  by itself** and says so ("Paused: you went quiet. Continue when you're ready").
- **Continue** resumes the *same* take from where it paused (append, don't restart).
- **Delete** throws the take away (confirm first) and returns to an empty recorder.
- **Done** submits; the cap is `voice.maxSeconds`.
- Microphone permission is asked here, behind a one-line explainer. Refused → a designed state
  that offers the self-check (below) instead.
- Packages: `record` (the amplitude stream for the silence check; web supported) and
  `flutter_tts`. Android `RECORD_AUDIO`, iOS `NSMicrophoneUsageDescription`. Say so in the PR.

## Scoring

- **Online:** a new Edge Function `supabase/functions/score-voice/` receives the audio (≤
  `maxSeconds`, a size cap) with the mission's `listenFor` points, and asks Gemini (the same
  model and key as `score`; import its helpers from `../score/gemini.ts`, don't change them) to
  transcribe it and score the **content**: which points were made, the four dimensions 0–100,
  one sentence of basis each. **Never accent, pronunciation or how it sounds**: in the prompt
  and on screen ("We score what you said, not how you sound"). Same JWT, the same 30-a-day quota
  (`claim_ai_score()`), temperature 0.
- **Offline / no backend / timeout (zero setup must still work):** a **self-check**: the player
  listens back to their take and ticks which `listenFor` points they made. A pure engine
  function (`packages/engine`, new file, tested) turns the ticks into a `MissionScore` by the
  points' dimensions, labelled "Self-check". The room lights either way.
- **Privacy:** the audio is sent for scoring and **not stored**; only the transcript and scores
  go in `ai_scores` (owner-only RLS). Never the player's name. Recordings on the device are
  deleted after the debrief.
- **Progress:** a voice attempt is stored and synced like a choices attempt (a local
  `voice_attempts` table or an extension of `attempts`, plus a migration with pgTAP if the
  server needs new columns). It counts for the tower, XP, the weekly goal and Your file.

## Owns

`features/voice/**` (new: recorder, silence detector, TTS service behind an interface so tests
fake it, the voice debrief), the routing of a voice mission to it (one branch where a mission
starts; tell thelastroom-de), the engine's self-check scorer, `score-voice`, the voice attempt
store and its migration, permission lines in `android/` and `ios/`, the pubspec lines, appended
events (`voice_answer_recorded`: `mission_id`, `seconds`, `paused_count`, `retakes`;
`voice_answer_scored`: `mission_id`, `score_bucket`, `source`; never audio or text). Use today's
tokens and components; adopt 33's look after it merges. Test with a small voice mission fixture
in your tests until 37's content lands.

## Acceptance

- [ ] A voice mission plays end to end: spoken lines → recorded answer → spoken follow-up →
      recorded reply → debrief with transcript, points made/missed, scores and basis.
- [ ] Silence for 5 s pauses; Continue appends; Delete clears; the cap stops it (unit tests on
      the silence detector with a fake amplitude stream; widget tests for every recorder state).
- [ ] Offline: the self-check scores it and the room lights. Mic refused, quota spent, timeout:
      each a designed state, never an error.
- [ ] `score-voice` Deno tests (mocked Gemini) and one live run with the owner's key
      (`supabase functions serve --env-file ../thelastroom/.env`; the CLI reads it, you don't),
      output in the PR.
- [ ] All gates (incl. the db job), CI green, `docs/status/35.md` current. Message
      thelastroom-w4-fe with the PR link.
