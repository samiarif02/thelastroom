# Deployment

Nothing ships from a feature branch or a dirty tree. Everything below happens **after** a PR is
merged to `main`, and only when the person asks.

| What | How it ships | Who/when |
| --- | --- | --- |
| **Web demo** (the reviewers' link) | `flutter build web --release` from `main`, deployed to static hosting. Host chosen in the deploy session [Decision needed]; the build already runs on every PR. | After merge. Deploy early and keep it current (README §5 "Demos"). |
| **Android APK** | `flutter build apk --release`, attached to a GitHub Release (`gh release create`). | At milestones. Signing keys never in git (`docs/rules/secrets.md`). |
| **iOS** | Xcode archive → TestFlight. | Only if needed for the demo. |
| **Supabase migrations** | `supabase db push` to the linked project, from `main`, after the PR that adds them merges. | `docs/rules/migrations.md`. |
| **Edge Functions** (`coach`) | `supabase functions deploy coach`; secrets via `supabase secrets set --env-file .env`. | After merge. |

## Rules

- **Build what CI built.** Release builds use the pinned Flutter version (README, CI).
- **Config by flavor file.** `--dart-define-from-file=env/prod.json` for release builds; the
  file is gitignored and holds only public values.
- **Order matters.** A release that depends on a new table or function waits until the migration
  or function is deployed. The PR says so in its watch list.
- **Web first-frame budget.** The web build keeps a branded loading screen in
  `apps/mobile/web/index.html` and defers heavy assets (brief §9: first frame < 3 s).
- **Notifications are mobile-only.** The web build skips them; Settings says so.
