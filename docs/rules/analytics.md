# Analytics

Product analytics is PostHog (brief §10), wired in a later session. Until then
`LogAnalytics` writes events to the log. Either way, feature code only ever calls:

```dart
ref.read(analyticsProvider).track(AnalyticsEvent.missionCompleted, {
  'mission_id': mission.id,
  'chapter': 1,
  'score_bucket': bucket.name,
  'attempt_number': attempt,
});
```

## Register before you build

1. Add the value to `AnalyticsEvent` (`apps/mobile/lib/core/analytics/analytics_event.dart`).
2. Add the row to `docs/EVENTS.md`: when it fires, which properties.
3. Then build the feature that fires it.

`npm run check:events` fails if the enum and `docs/EVENTS.md` differ, if feature code fires an
event by string or calls the SDK directly, or if a wire name is written as a string literal
outside the registry. Registered-but-unfired events are a warning (normal before a feature
exists, a finding after).

## The rules (8x's six, unchanged)

1. **`object_action`**: a noun and a past-tense verb (`mission_completed`, not
   `complete_mission`).
2. **`snake_case`** names and property keys.
3. **Past tense**: it already happened.
4. **No variables in the name.** Names are fixed enum values; variation goes in properties.
5. **No PII, no free text.** Property values are ids, enum names, numbers and booleans.
   **Never answer text, drafts, emails or names.** Bucket scores (`score_bucket`) rather than
   sending raw text-derived values.
6. **Common attributes are defined once** (platform, app version, content version) in the
   analytics implementation, not repeated at each call site.

## What we measure (brief §12)

Activation (% of guests finishing Mission 1 → `user_activated`), D1/D3/D7 return, median score
delta from the Mission 1 baseline to the Mission 7 review, Mission 3 recall pass rate,
notification open rate by type and variant. **Never invent metrics or testimonials** in docs,
the README or the demo.
