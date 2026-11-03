# Deployment

Nothing ships from a feature branch or a dirty tree. Everything below happens **after** a PR is
merged to `main`, and only when the person asks. There's no hosted web demo of the game:
reviewers clone the repo and run it, and the owner records a demo video (ADR 0005). The one
hosted thing is the marketing landing page in `web/` (ADR 0007).

| What | How it ships | Who/when |
| --- | --- | --- |
| **The game on the web** | **Not deployed.** `flutter build web --release` runs in CI as a compile check only; `flutter run -d chrome` is a local run target. | Every PR (CI). The game isn't hosted (ADR 0005, D3). |
| **Landing page** (`web/`) | Static Next.js export, built and served by **Vercel's Git integration** (root directory `web`) at https://thelastroom-ten.vercel.app. No token or secret in the repo, no deploy job in CI; CI's `web` job lints, typechecks and builds it. | Every push to `main` (Vercel). ADR 0007. |
| **Android APK** | `flutter build apk --release`, attached to a GitHub Release (`gh release create`). | At milestones. Signing keys never in git (`docs/rules/secrets.md`). |
| **iOS** | Xcode archive → TestFlight. | Only if needed for the demo. |
| **Supabase migrations** | Today: replayed locally by `supabase start` / `supabase db reset`; there's no hosted project (ADR 0005). With one: `supabase db push` from `main`, after the PR that adds them merges. | `docs/rules/migrations.md`. |
| **Edge Functions** (`score`, `score-voice`) | Today: `supabase functions serve --env-file <your .env>` on a laptop; a phone reaches it over USB (`adb reverse tcp:54321 tcp:54321`) or the same Wi-Fi. With a hosted project: `supabase functions deploy`, secrets via `supabase secrets set --env-file .env`. | After merge. |

## Rules

- **Zero setup.** Clone → `flutter pub get` → `cd apps/mobile && flutter run` works with no keys
  and fully offline; the backend is optional at runtime
  ([ADR 0005](../decisions/0005-zero-setup-offline-backend-optional.md)). No change may make a
  key, an env file or the network a requirement to run or play.
- **Build what CI built.** Release builds use the pinned Flutter version (README, CI).
- **Config by flavor file, optional.** A release build that wants the backend adds
  `--dart-define-from-file=env/prod.json`; the file is optional (without it the build runs with
  the backend off), gitignored, and holds only public values.
- **Order matters.** A release that depends on a new table or function waits until the migration
  or function is deployed. The PR says so in its watch list.
- **Web first-frame budget.** The web build (run locally) keeps a branded loading screen in
  `apps/mobile/web/index.html` and defers heavy assets (brief §9: first frame < 3 s).
- **Notifications are mobile-only.** The web build skips them; Settings says so.
- **Check the release artefact, not only the debug build.** Flutter's template declares
  `INTERNET` only in the debug and profile manifests; release builds silently went offline until
  #59. `check:standards` (`android-release-permissions`) now fails without it in `src/main`.
