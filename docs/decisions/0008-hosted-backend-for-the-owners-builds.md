# ADR 0008: a hosted backend for the owner's builds

Date: 2026-11-04 · Status: accepted (owner)

## Context
Live AI scoring ran only on a laptop (local Supabase + `supabase functions serve`), with the
owner's phone reaching it over USB (`adb reverse`). The link reset on every reconnect, and a voice
room silently fell back to the self-check on 4 Nov. The reviewer will see the app on its own, away
from the laptop, at the final feedback.

## Decision
The owner created a Supabase project (free tier, `eeanpdlqxmatuidrhoht`, ap-southeast-2). It holds
the same six migrations (with their RLS), anonymous sign-in and 6-digit email codes, and the
`score` and `score-voice` Edge Functions. `GEMINI_API_KEY` is a function secret the owner set in
the dashboard. The owner's release builds point at it through a define file kept outside the repo
(URL + anon key only).

The project's auth config was matched to its secure defaults (email confirmation on, two-factor
on, a one-minute email interval) rather than pushing the repo's local-development `config.toml`,
which loosens them for local work; only anonymous sign-in and the 6-digit OTP were changed.

## What stays the same
ADR 0005 holds: a clone runs with no backend, fully offline, and nothing in git points at the
hosted project. The app still holds only the anon key.

## Consequences
- Live AI and voice scoring work on any network for the owner's builds.
- Free tiers on both sides: Supabase's built-in email sender allows a few emails an hour, and the
  Gemini key rate-limits heavy use (the fallback chain and offline score absorb it). Real users
  would need SMTP and a paid Gemini key (cost: [ai-reliability-and-cost.md](../ai-reliability-and-cost.md)).
- New migrations reach the hosted project with `supabase db push --linked` after they merge.
