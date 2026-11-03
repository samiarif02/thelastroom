# Status 51: on-device QA (realme RMX3085), live AI scoring, Chapter 1 finish

Worktree `../thelastroom-w17`, at `origin/main` 5fde7e2 (Daylight redesign, doors, first-time
tips); the fixes are on branch `fix/52-phone-qa` (see "Fixed" at the end). Device `LFCQ8HKNAUDIFUPR`
(Android 13, 1080 × 2400 px). The owner's real progress is on it: never uninstall or clear.

## Progress log

- Read AGENTS.md, status 46/48/49-tips, scoring-eval, secrets rule, ADR 0005.
- `supabase start` launched in w17 (project_id `thelastroom`, API 54321).
- **BUG-1 (P0, found before any build): release APKs have no `android.permission.INTERNET`.**
  `apps/mobile/android/app/src/main/AndroidManifest.xml` only declares POST_NOTIFICATIONS,
  RECEIVE_BOOT_COMPLETED and RECORD_AUDIO; INTERNET is only in `src/debug` and `src/profile`
  (Flutter's template), and no plugin merges it in. `aapt dump permissions` on w15's
  `app-release.apk` and `dumpsys package` on the phone's installed build both confirm it is
  missing. Effect: every network call from a release build fails at the socket (EACCES), so AI
  scoring (`score`), voice scoring (`score-voice`), sync, sign-in and the waitlist can never work
  on an installed APK, even with `env/*.json` set. The offline fallback hides it (ADR 0005), so
  it looks like "no backend". Fix: add
  `<uses-permission android:name="android.permission.INTERNET"/>` to `src/main`'s manifest.
- Local backend up: `supabase start` (12 containers, all 6 migrations applied), `supabase
  functions serve --env-file /Users/mac/WebstormProjects/thelastroom/.env` detached as PID
  65744 (log: scratchpad `functions.log`; lists `score` and `score-voice`), `adb reverse
  tcp:54321 tcp:54321`. Define file `scratchpad/phone-local.json` (URL + LOCAL anon key only).
- Built `flutter build apk --release --dart-define-from-file=…/phone-local.json` at 5fde7e2
  **plus the local INTERNET line** (uncommitted, in w17's working tree). Signer SHA-256
  `09063e19…441f60` matches the installed build; `adb install -r` kept the owner's data (384 XP,
  4 of 21 rooms, room 5 half-played). Guest sign-in landed in local `auth.users` (anonymous) and
  the outbox synced 6 attempts.
- **AI scoring works on the phone.** Room 5 (resumed, then played with the strongest lines):
  debrief chip "Scored by AI · Senior recruiter", overall 90 (95/85/90/90). functions.log:
  `{"fn":"score","event":"ai_score","model":"gemini-3.5-flash-lite","mission":"m05_something_went_wrong","prompt_tokens":639,"output_tokens":215,"ms":1897}`;
  row in `public.ai_scores` (model gemini-3.5-flash-lite, 90). Screenshot `qa-debrief-ai-room5.png`.
- Room 5 debrief on the phone: Daylight ground, dossier slide + stamps + wax seal, "+92 XP",
  trust at the end, "Why these scores" with the AI's sentence per dimension, "What cost you",
  "Your reasoning", "Back to the tower". "How we scored this" sheet: "Who scored it: An AI
  senior recruiter (Google Gemini)…", "Recruiter 90 · Game 85". Tower after: "Room 5 is lit.",
  5 of 21, door 6 ajar with its play cue, door 7 closed, floors 2/3 locked doors.
- **BUG-2 (P2, resume):** room 5 was half-played by the owner before this session. "Continue"
  showed the *open* beat's cards again; I locked line C, and the open beat's why step never
  came (straight to evidence, trust pips 3 → 2). The debrief then credits the open beat with a
  reason I never picked this session ("You said: Labelling each STAR step…", "Not why it
  works"), so "What cost you" blames it. Likely the saved attempt already had beat 0 locked +
  reasoned, but the player re-showed beat 0's cards; `controller.lock` then rejected the tap
  (option not in `beatOptions`), `_askWhy` saw no pending why and reacted to the OLD beat 0.
  Suspect `features/mission/mission_player.dart` `_resumeScene` / `_beatShown` vs
  `mission_controller.dart` `resume()`. Screens `qa-03-room5-resume.png`, `qa-04-room5.png`,
  `qa-06-room5-after-lock.png`, `qa-17-debrief-reasoning.png`. Repro attempt in room 6 below.
- **BUG-3 (P3, copy):** the first_result tip says "Your weakest skill is underlined in red.
  Tap 'How we scored this' to see why." but with no lesson (`DebriefFacts.markedDimensionIndex`
  null) the pen stays capped and nothing is underlined (`qa-tip-first-result.png`). Copy in
  `features/tips/tips.dart:43` should not promise the underline when there is none.
- Minor copy: the recall_due tip says "I left you a note in Recall. Two minutes." while the card
  above says "15 notes are waiting · About 8 minutes" (`qa-tip-recall-due.png`).
- Room 6 (The follow-up trap), played fresh with the strongest lines + sound reasons, the
  evidence beat built in order (900 rows → 300 duplicates → counted every row → half, not a
  third; decoy left out): **AI 85** (90/85/80/90), "Nothing to mark". functions.log:
  `{"fn":"score","event":"ai_score","model":"gemini-3.5-flash-lite","mission":"m06_the_follow_up_trap","prompt_tokens":633,"output_tokens":232,"ms":2058}`.
- Leave + resume, tried twice in room 6 to reproduce BUG-2: back button on the feedback sheet
  after beat 0 → "Leave the interview?" → Leave → tower "Continue room 6" → Continue: resumed at
  the evidence (built) beat, correct. X during the land beat's why step → Leave → Continue:
  resumed on the same why step, correct. So BUG-2 did NOT reproduce; it may need a save from
  an older build or another moment (e.g. during the guess call-out or the beat-0 reaction).
  Recorded as seen once.
- Minor layout: on the built beat with all 5 fragments, the "Lock it in" dock sits down on the
  gesture-nav area (`qa-build-dock-under-nav.png`); still tappable.
- Floor sheets (locked): floor 2 "Under pressure · locked, opens when you finish room 7", who
  you meet, what you practise, "Out loud", rooms 8.. locked (`qa-45-floor2-sheet-locked.png`);
  floor 3 "The final round", "Both" (`qa-46-floor3-sheet.png`). Pass.
- Room 7 (First round review): own-words draft **skipped** (it's the owner's words, not mine);
  timer left to run out on the open beat: the line empties to "0", nothing forced
  (`qa-52-timer-expired.png`); strongest lines + sound reasons, evidence built in order
  (timed → hunting → checklist → tested; team decoy left out). **AI 82** (90/75/85/80), "Nothing
  to mark". functions.log:
  `{"fn":"score","event":"ai_score","model":"gemini-3.5-flash-lite","mission":"m07_first_round_review","prompt_tokens":621,"output_tokens":236,"ms":1911}`.
- Epilogue "Later, in the corridor" (Priya, Marcus, Priya; `qa-64-epilogue.png`) → floor
  cleared screen (read from the UI tree, the screenshot was missed because my tap went through
  to its button): "Floor 1 cleared · 7 of 7 rooms lit", "You got through the door.", "Skill
  earned: Evidence Builder · Earned in room 7, with no hints.", Rooms lit 7/7, Total XP 674,
  This week 1/3, "Floor 2 is open: Under pressure · Seven rooms. You answer out loud.", "Read
  your floor 1 report", "Take the lift to floor 2" → Chapter 1 report: first try room 1 = 39,
  review room 7 = 98 (engine), radar, 67→100 / 25→92 / 33→100 / 33→100 (`qa-65-ch1-report.png`).
- **Chapter 1 complete on the owner's phone.** Rooms played this session: 5 (AI 90, engine 85),
  6 (AI 85), 7 (AI 82; engine 98 in the report).
- Built beats with a why prompt (room 7 evidence): after "Lock it in" the screen shows "Why tell
  it like that?" and the three reason cards with the feedback sheet already saying "That's the
  principle." though no reason was picked (built beats ask no why), then auto-advances
  (`qa-60.png`). Confusing; P3 (`mission_player.dart`, the built beat's reaction reuses the why
  layout).
- Minor: the report's top bar kicker reads "Sami." (the stored name's typed full stop is
  stripped in her lines, not here). `features/progress/` report top bar.
- Tower after the chapter (`qa-67-tower-floor2-open.png`, `qa-68-tower-doors-floor2.png`): 674
  XP, "Up next · room 8 of 21 · Team conflict · Out loud · Timed", floor 1 7/7 all checked,
  **floor 2 open "0 of 7" with door 8 ajar (Lena looking out, play cue)**, rooms 9–14 closed,
  floor 3 locked. Skills: Evidence Builder earned. Floor 2 sheet now "Floor 2 · open … Room 8,
  Team conflict, up next" (`qa-69-floor2-sheet-open.png`). I did NOT press "Take the lift to
  floor 2" (it opens room 8, a voice room).
- **BUG-4 (P2, Your file):** a room scored by the AI shows "Latest" from the AI and "Best" from
  the engine, so one try reads "Best 85 · 1 try" next to a latest of 90 (room 5) and "Best 98 ·
  1 try" next to 85 (room 6): the best is lower than the only try, or the two disagree. Steps:
  play a room with the backend on → Skills tab → Rooms. `features/progress/progress_screen.dart`
  ~l.656–661 (`latest = ai?.score.overall.score ?? line.latest!.total`, `best = line.best`
  engine-only). Pick one source per card (or label both). `qa-72-file-floor1.png`.
- Your file: hero 674 XP, "1 of 3 sessions this week", 7 of 21 rooms lit, average 67, since
  room 1 +59; skills medals (Clear Introductions next · room 3, Evidence Builder earned, the
  other two locked); radar; rooms grouped by floor (floor 1 cards with latest/best/tries and
  an AI or Offline tag, floor 2 cards locked, floor 3 folded into one sand card); room 5's card
  opens the stored dossier with "AI score" and the AI's overall line (`qa-73-past-result-room5.png`).
  "How you play": calm mode switched **on** for the airplane test (switched back after).
- Recall Room: "note 1 of 5 · Box 1 of 3", Priya's welcome, taped note, picks; answered the
  first note right ("Right. This note moves up a box.") and left with X (`qa-76/78`). Minor:
  at rest the pinned week card covers the third pick (C) until you scroll (`qa-76-recall.png`).
- Settings: Sound, Reminders ("Next: tomorrow at 13:54, from the Recall Room"), "Send a test
  reminder" → the notification arrived at once: "Recall Room · 14 traps are waiting in the
  Recall Room." (`qa-81-notification-shade.png`); "First-time tips · Show tips again" is there
  and was NOT pressed.
- Replays (they only add tries; the owner's earlier half-played rooms 2 and 3 were waiting
  in the resume store, and I continued both): calm mode on → no timer line in the room
  (`qa-82-room2-resume.png`, compare `qa-04-room5.png`). Room 2 resumed at the open beat, why
  step asked normally this time; strongest lines: **AI 92** (95/90/90/95), functions.log
  `{"fn":"score","event":"ai_score","model":"gemini-3.5-flash-lite","mission":"m02_tell_me_about_yourself","prompt_tokens":640,"output_tokens":232,"ms":2008}`.
- **Airplane mode during a result (room 3 replay)**: `cmd connectivity airplane-mode enable`
  AND `adb reverse --remove tcp:54321` (the reverse rides USB, so airplane mode alone would
  not cut the local backend), then locked the reply: debrief at 4 s with the "Offline score"
  chip, engine 98 (100/92/100/100), seal and stamps, no crash (pid unchanged); "How we scored
  this" says "The AI recruiter wasn't reachable, so this is the game's own score…"
  (`qa-87a-airplane-4s.png`, `qa-88-offline-debrief.png`). Airplane off and the reverse put back
  afterwards. Note: ~10 s after airplane mode went on, the realme opened its quick-settings
  shade by itself (OS behaviour, not the app).
- Your file after: room 2 latest 92 (AI) / best 95 · 2 tries, room 3 98 / 98 · 2 tries
  (offline), room 4 untouched at 24. Calm mode switched back **off**. Room 4's past result shows
  the red pen underlining Specificity and "Say what you do" in the margin
  (`qa-91-past-result-room4-pen.png`). Tower at the end: 810 XP, Clear Introductions earned too
  (from the room 3 replay), "Next one in floor 2" (`qa-92-final-tower.png`).
- Cold start (force-stop + launch) goes straight to the tower: the title only shows on the
  very first launch (`TitleGate`, by design), so "title → tower" can't be re-run on the
  owner's file without clearing data (not done).
- Voice readiness (no voice room opened): functions.log lists
  `http://127.0.0.1:54321/functions/v1/score-voice`; OPTIONS answers 204; the APK on the phone
  has RECORD_AUDIO (not granted yet: the recorder asks) and INTERNET. Without the backend the
  voice room falls back to the self-check (`voice_controller.dart`).

## Feature table (phone, release build, local backend)

| Feature | Result | Evidence |
| --- | --- | --- |
| Title → tower | n/a on this file (first launch only); cold start → tower pass | `qa-89-cold-1.png` |
| Weekly ring + XP | pass (ring counts days: 1/3; XP 384 → 810) | `qa-02-tower.png`, `qa-92-final-tower.png` |
| Floor sheets (2 and 3) | pass (locked and open states) | `qa-45`, `qa-46`, `qa-69` |
| Door states | pass (checked, ajar + cue + interviewer, closed, locked) | `qa-23`, `qa-68` |
| Tower tip (tower_door) | not shown (already seen by the owner); recall_due tip shown and dismissed | `qa-tip-recall-due.png` |
| Answer cards, lock-in | pass | `qa-04`, `qa-05` |
| Built beats | pass (dock overlaps the gesture bar at 5 fragments, still tappable) | `qa-33d`, `qa-59` |
| Timed beat | pass (runs out to "0", nothing forced) | `qa-51`, `qa-52` |
| Calm mode | pass (no timer line with it on) | `qa-82-room2-resume.png` |
| Why step (never stuck) | pass in rooms 2, 3, 6, 7; skipped once on room 5's resume (BUG-2) | `qa-why-step.png` |
| Feedback sheet | pass | `qa-09-feedback.png` |
| Debrief: dossier slide, stamps, seal, Daylight ground | pass | `qa-14b`, `qa-87a` |
| Debrief: pen | pass where there's a lesson (room 4); none when nothing to mark | `qa-91` |
| "How we scored this" | pass (AI and offline wording, Recruiter vs Game) | `qa-21` |
| XP, line that cost the most, reasoning | pass | `qa-17`, `qa-19`, `qa-20` |
| First result tip | shown once; copy promises an underline that isn't there (BUG-3) | `qa-tip-first-result.png` |
| Room 7 epilogue | pass | `qa-64-epilogue.png` |
| Floor-cleared reward | pass (content read from the UI tree; still missed) | status log above |
| Chapter 1 report | pass | `qa-65`, `qa-66` |
| Your file: past results, floor groups, medals | pass; latest vs best mixes AI and engine (BUG-4) | `qa-72`, `qa-73` |
| Recall Room | pass (note answered, moves up a box) | `qa-76`, `qa-78` |
| Settings: reminders, test reminder | pass (notification arrived) | `qa-79`, `qa-81` |
| Settings: "Show tips again" present | pass (not pressed) | `qa-79-settings.png` |
| Leave mid-room + resume, back button | pass (twice in room 6) | `qa-30`, `qa-32`, `qa-37` |
| Airplane mode on a result | pass (offline score, no crash) | `qa-87a`, `qa-88` |
| AI scoring live | pass (rooms 5, 6, 7, 2: 90, 85, 82, 92) | functions.log lines above |
| Voice readiness | pass (score-voice served, RECORD_AUDIO + INTERNET in the APK) | above |

## Bugs

1. **BUG-1 P0** release manifest has no INTERNET permission: every installed APK is offline
   only, AI scoring and Chapter 2 voice scoring can never run. `apps/mobile/android/app/src/main/AndroidManifest.xml`.
   Fixed locally (uncommitted) for this build only; needs a real commit/PR from the lead.
2. **BUG-2 P2** (seen once, not reproduced) room 5's resumed attempt skipped the open beat's
   why and kept an old reason. `mission_player.dart` `_resumeScene` / `mission_controller.dart`
   `resume()`.
3. **BUG-3 P3** first_result tip promises a red underline when there is none.
   `features/tips/tips.dart:43`.
4. **BUG-4 P2** Your file: "Latest" is the AI score, "Best" the engine's.
   `features/progress/progress_screen.dart` ~656–661.
5. Minor: built-beat dock over the gesture bar; built beat shows the reason cards with "That's
   the principle." though none was picked; Recall week card hides pick C at rest; recall_due tip
   says "Two minutes" next to "About 8 minutes"; the reminder says "traps" where the Recall Room
   says "notes"; the report's kicker shows "Sami." with the typed full stop.

## State left behind

- Supabase local stack running in w17 (12 containers, project `thelastroom`). Stop:
  `cd ../thelastroom-w17 && supabase stop`.
- `supabase functions serve` PID 65744 (log in the w4 session scratchpad `functions.log`).
  Stop: `kill 65744`.
- `adb -s LFCQ8HKNAUDIFUPR reverse tcp:54321 tcp:54321` active (dies when USB drops; re-run it).
- Phone build: 5fde7e2 + the local INTERNET line, `--dart-define-from-file` scratchpad
  `phone-local.json` (local URL + local anon key). Same signer as before (09063e19…441f60).
  Live AI only works while the phone is on USB to this Mac with Supabase + functions running;
  otherwise every room (and voice) falls back to the offline score / self-check.
- App left on the tower, floor 2 door ajar. voice_mic tip never triggered (no voice room opened,
  "Show tips again" not pressed). Calm mode off, airplane mode off.
- w17 working tree: `AndroidManifest.xml` modified (INTERNET), this status file untracked.

## Fixed (branch `fix/52-phone-qa`)

- **BUG-1 (P0)** `android.permission.INTERNET` is declared in `src/main`'s manifest (its own
  commit), and `check:standards` has a new check, `android-release-permissions`, that fails when
  the main manifest lacks it (a commented-out line doesn't count). Release APKs used to fall back
  to offline scoring silently: AI scoring, voice scoring, sync and sign-in never worked in a
  release build.
- **BUG-2 (P2)** not reproduced from code; the evidence points away from the resume itself. The
  screenshots show trust at 3 pips right after "Continue" (`qa-04`), which is trust 50: the
  resumed attempt had **no** lines yet (any open line with a reason gives 42–62, and every
  "Labelling…" pick gives 42 or 48 → 2 pips). After locking C (the strongest line) the pips
  read 2 (`qa-06`) = 48, exactly "strongest line + the Labelling reason". So the reason was given
  in this run, through the why step's reason cards, without being seen (most likely the tap that
  met the first-ever why-step tip: a tap on its spotlit target goes through to the reason under
  it, by design, and that tip is shown once, which fits "seen once"). `_resumeScene` placed the
  scene correctly. Hardened anyway, with failing-first tests (`resume_hardening_test.dart`):
  a save whose beat asks why but has no reason, with lines after it (a pre-why-step build),
  resumes at that why step and drops the later lines; a reason saved on a built beat is dropped;
  and a lock the controller rejects (a scene out of step with the attempt) no longer reacts to
  the old beat and skips on: the scene goes to the beat or why step the attempt is really at.
- **BUG-3 (P3)** the first result's tip only mentions the red underline when the pen marks a
  row; on a clean run it says "Tap “How we scored this” to see how each score was reached."
- **BUG-4 (P2)** Your file's room card and the past result read latest and best from the same
  scores: each try as it was shown (the AI's for the latest when it scored it, the game's for
  the rest), so the best is never below the latest.
- Minor: the built beat's "Lock it in" is pinned in the dock above the gesture bar (the dock
  respects `viewPadding`); a built beat's reaction no longer shows reason cards, and a strong
  build reads "Every piece, in order." instead of "That's the principle."; the Recall week note
  sits under the list instead of over pick C; the Recall tip says the card's own count and time
  ("I left you 15 notes in Recall. About 8 minutes."); reminders say "notes", not "traps"; the
  name is trimmed once (`PlayerProfile.displayName` / `spokenName`), so the report's kicker reads
  "Sami", not "Sami.".
