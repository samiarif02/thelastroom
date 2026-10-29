---
name: decision-flutter
description: Flutter (no Flame) for Android, iOS and a web demo build; 8x's discipline ported, not their stack
type: project
---

**Flutter 3.47.8** (pinned in README and CI) for Android and iOS, plus a **Flutter web build as
the reviewers' demo link**. No Flame: this is a narrative card-choice game, so widgets,
CustomPainter, fragment shaders, flutter_animate and Rive cover it. Riverpod 3, go_router,
drift, supabase_flutter. Dart pub workspace monorepo mirroring 8x's folder layout.

**Why:** pixel-level control for the cinematic UI, one codebase, a playable link with no install.
8x said "any stack"; their templates show the discipline, so we port the discipline
(AGENTS.md "Where this repo differs from 8x's templates").
**How to apply:** don't add Next.js/Expo/Prisma-isms; map each 8x standard to its Dart
equivalent. Related: [[decision-offline-first-outbox]].
