# Status 49: first-time tips (contextual, not a tour)

Branch `feat/48-daylight-everywhere` (PR #57, stacked on #56). Worktree `../thelastroom-w15`.
The owner approved contextual first-time tips instead of a full tour: the tower tour becomes
tip 1 of a small tips system.

## Plan

- `features/tips/`: `Tip` ids, an on-device store (SharedPreferences, offline; the old
  `tower.tourSeen` flag counts as `towerDoor` seen), a controller (one tip at a time), the
  spotlight overlay and the bubble (cast arch, Daylight kit).
- Tips: tower_door, answer_cards, why_step, first_result (below the sheet, after its
  timeline), voice_mic, recall_due, your_file.
- Events `tip_shown` {tip, replay} / `tip_done` {tip, action} replace `tower_tour_*`.
- Settings: "Show tips again" resets all and returns to the tower.
- `ui/paper/**` and the paper goldens untouched.

## Done

- `21e7650` feat(events): `tip_shown` / `tip_done` registered first.
- `features/tips/tips.dart` (Tip ids + copy, `TipStore` on SharedPreferences with the legacy
  tour flag, `TipsController`: one tip on screen at a time, `tip_shown` once per tip until a
  reset, `release` hands back an unseen tip) and `tip_overlay.dart` (TipVoice, TipBubble,
  TipOverlay: the old tour generalised; the cut-out lets taps through to the target, a
  translucent Listener puts the tip away as `followed`; `tipTarget` measures a key clipped to
  its scroll view). `tower_tour.dart` is gone.
- Tower: tower_door (arch cut-out; "next room" line after a reset with rooms played), then
  your_file (Skills tab) once a room is played, then recall_due (Recall tab) when notes are due.
  One tip per visit; never with the welcome-back card, the reminder explainer (waits for it to
  be answered after room 1) or the notice over the tab bar. `TabItem.anchor` keys the tabs.
- Mission player: answer_cards (first non-built beat's cards + the Lock-in dock), why_step (the
  reasons, once asked); the beat timer is paused while a tip is up (`running: … && _tip == null`).
- Debrief: first_result is an inline bubble UNDER the Dossier, after `onFinished` + 600 ms (the
  cards fade up first), scrolled into view; a honey ring (foreground decoration, no layout
  change) on "How we scored this"; tapping it is `followed`, a tap elsewhere `dismissed`.
  The voice debrief has no "How we scored this", so no tip there.
- Voice: voice_mic on the record tile when the recorder is `empty` (ready), via
  `RecorderPanel.recordKey`.
- Settings: "First-time tips" panel, "Show tips again" → `replayAll()` → tower.
- Tests: `test/features/tips/tips_test.dart` (17); harness/VoiceRig override the store with all
  tips seen (`InMemoryTipStore.allSeen()`); the tour group left `tower_test.dart`.
- `1fd78cc` feat(mobile): the tips (events `tower_tour_*` removed from the enum and EVENTS.md).
- Stills `.pr-screenshots/48/tips-*.jpg` (360 × 800; door and cards at 2x too; mic at the
  voice rig's 390 × 844) from `test/features/tips/stills` (`WRITE_STILLS=1`), each looked at.
  The cut-out gives way to the bubble when the target is tall (4 answer cards, 2x text).
- Gates: secrets, standards 25/25, format, analyze (no issues), events (41), env, `npm run
  test` (mobile 1,029, brand 349, content 309, engine 137), build:web, commit range: pass.
  `ui/paper/**`, `packages/brand` and the paper goldens: no diff.
- Goldens compared on Linux (Docker, ubuntu:24.04 amd64, Flutter 3.47.8, SDK sha256
  baf7dcc5… = releases_linux.json) at 1fd78cc: all 59 pass against the committed images, so
  none changed and none needed redrawing (the paper ones included).
- Release APK built at 1fd78cc.

## Next

1. Session log commit, push, dispatch CI on the branch, PR #57 body "First-time tips".
2. Release APK on the realme (LFCQ8HKNAUDIFUPR). Never merge.
