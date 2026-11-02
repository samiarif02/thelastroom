# Design research: fun AND credible

Brief 43, phase 1. The question: how do the best learning and self-improvement products make the
practice feel like play *and* keep an adult's trust? The Last Room sits in an awkward spot.
Interviews are high stakes and make people anxious, but the product is a game you should want to
open on day 3. The owner's bar: "a fun experience in a professional way… not fully childish, not
generic, not AI-generic… so users come back on day 3 or day 5."

The starting point is main's **vivid** look, which the owner liked: rich chapter colour, the cast,
rings, a sunflower Play button. A reviewer found it **too childish**: cartoon faces, stars, yellow
pills. Main is also mostly **dark** (an evening sky), and the owner's last rejection was "still
too dark and serious". So the research looks for products that are light, colourful and warm, and
still read as a serious tool.

Each product below has five parts: what it is, what makes it engaging, what makes it feel
premium, what we borrow, and what we avoid.

---

## 1. Duolingo (the 2022–23 path, the character refresh, streak moments)

Sources: [Duolingo: reshaping Duo](https://blog.duolingo.com/reshaping-duo/) ·
[Streak milestone design and animation](https://blog.duolingo.com/streak-milestone-design-animation) ·
[How the streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit) ·
[Achievement badges](https://blog.duolingo.com/achievement-badges) ·
[Johnson Banks: Everyone can Duolingo](https://www.johnsonbanks.co.uk/templates/work/duolingo) ·
[Design Week on the rebrand](https://www.designweek.co.uk/duolingo-rebrand-avoids-silicon-valley-tropes-and-reflects-companys-quirky-personality/) ·
[Apple Design Award 2023](https://english.madhyamam.com/technology/innovative-design-duolingo-wins-apple-design-award-2023-1169335) ·
[a design-system teardown](https://blakecrosley.com/guides/design/duolingo)

- **Engaging.** One linear **path** replaced the branching tree, so there is always exactly one
  next thing to tap. A recurring **cast** with stable personalities gives you someone to come back
  to. Feedback is instant and physical: a green or red banner slides up in about 200 ms with a
  sound. **Milestones are reserved**: the big streak animation (Duo spins and bursts into flame)
  plays only on landmark days. The streak animation alone raised new learners' day-7 retention by
  **+1.7%**. Doubling streak freezes raised daily actives by +0.38%. Learners who reach a 7-day
  streak are 3.6× more likely to finish a course. **Slack beats rigid rules.**
- **Premium.** The work is in the *shape*: "if the overall shape is not appealing, then the
  details within that shape can't compliment it." The character sits at a **slight quarter
  turn**. The illustration system is built from three primitives (rounded rectangle, circle,
  rounded triangle), and the display type is bespoke. Timing is iterated in rough passes: "timing
  is everything in animation."
- **Borrow.** One path with one obvious next step. Tactile buttons: a thick bottom edge that
  collapses on press (`border-bottom: 4px` → `0`, the button drops 4 px). Characters that react.
  Celebration only on milestones. Badges that use the cast instead of abstract stars. The
  "freeze" idea, recast as a weekly goal with slack.
- **Avoid.** Guilt notifications and streak loss aversion; our brief bans streak shaming. The
  saturated primary-green "toy" palette and the hearts and lives system. Owl-level cartoon
  proportions: our people are colleagues, not mascots.

## 2. Duolingo Max: Video Call with Lily (the closest thing to our voice missions)

Sources: [Rive: Duolingo's AI video call brings Lily to life](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life) ·
[Duolingo blog: video call](https://blog.duolingo.com/video-call)

- **Engaging.** It feels like a call with a person. Lily **listens** (leans in, furrows her brow),
  **thinks** (tilts her head while the model is processing: "it looks like she's pondering what
  you said. It's subtle but crucial"), and reacts as **impressed** (brows up, a nod) or
  **confused** (squints).
- **Premium.** A modular rig: eight head animations and eight body animations combine into 64+
  idle variations, so it never loops visibly. Basic visemes for speech. The whole file is under
  1 MB. The reactions are subtle, not exaggerated.
- **Borrow.** This is our model for the interviewer: a small set of **states** (idle, listening,
  thinking, nod, smile, hmm) blended by a state machine, and **latency disguised as thought**.
  The interviewer is never frozen while the app works.
- **Avoid.** Lily's sarcasm. Our cast can be dry (Marcus) or skeptical (Lena), but never
  contemptuous.

## 3. Brilliant (playful, precise, adult)

Sources: [ustwo × Brilliant case study](https://ustwo.com/work/brilliant) ·
[ScreensDesign: Brilliant](https://screensdesign.com/showcase/brilliant-learn-by-doing)

- **Engaging.** A "game feel" north star: "STEM subjects require deep focus, so we had to strike
  the right balance between fun and concentration." There are whimsical flourishes on success,
  encouragement when you struggle, a level gameboard for progress, and **interactive
  explanations** when you're wrong instead of a red X. Loading uses on-brand tangram animations,
  never a spinner.
- **Premium.** Restraint. The fun lives in the *moments* (a correct answer, a level done), while
  the working surface stays calm, white and precise. "Playfulness that reduces anxiety without
  distraction."
- **Borrow.** A calm working surface and a lively reward moment. "Wrong" is an explanation you
  can explore, which suits our debrief basis and the "why that line?" step. Branded loading.
- **Avoid.** Blorbs-style abstract mascots. Ours are people, and people are the point.

## 4. Speak (an AI speaking tutor, the nearest product to Chapters 2–3)

Sources: [speak.com](https://www.speak.com/) ·
[ScreensDesign: Speak](https://screensdesign.com/showcase/speak-learn-spanish-french) ·
[LanguaTalk review](https://languatalk.com/blog/speak-app-review/)

- **Engaging.** Onboarding *is* a conversation with the tutor, so it collects data without a
  form. Home separates **the next lesson** from optional "jump-in" practice. Speech gets instant
  feedback, and you can compare your attempt with a model one. XP and streaks are there but
  quiet.
- **Premium.** Clean, white and photographic. It is positioned as "judgment-free" practice, a
  "pressure-free alternative to human conversation". The AI is framed as a tutor, not as
  technology.
- **Borrow.** "Next mission" as the single hero, with Recall as the optional jump-in. Speaking
  framed as safe practice. Show what was heard, then what to try.
- **Avoid.** The generic app look. Speak is polished but could be any app; our brief demands
  "if a screen could belong to any other quiz app, it isn't done."

## 5. Yoodli and Google Interview Warmup (interview and speech coaching)

Sources: [yoodli.ai](https://yoodli.ai/) ·
[Futurepedia on Yoodli](https://www.futurepedia.io/tool/yoodli-ai) ·
[Interview Warmup (D&AD 2023)](https://dandad.org/awards/professional/2023/237076/interview-warmup) ·
[Stuff on Interview Warmup](https://stuff.co.za/2022/05/18/googles-interview-warmup-uses-ai-help-users-perform-better-during-job-interviews/) ·
[Wordtracker on Interview Warmup](https://wordtracker.com/blog/marketing/googles-ai-tool-helps-you-prepare-for-job-interviews)

- **Engaging.** Interview Warmup transcribes as you speak and then shows **talking points
  covered** (experience, skills, goals), job terms and most-used words. Yoodli shows "you hit all
  your talking points! To work on: clearer transitions."
- **Premium / credible.** **Privacy is stated in the UI**: Warmup "doesn't grade your answer… or
  categorise anything as right or wrong" and doesn't save audio. Yoodli's feedback is "private…
  judgment-free". Feedback is objective, and "Great job" is followed by one thing to work on.
- **Borrow.** For voice missions, a **talking-points checklist** (our `listenFor`) that the
  debrief ticks off: "Points you made / points to add". A privacy line on the recording screen.
  One "to work on", which matches the brief's *one* lesson.
- **Avoid.** The enterprise dashboard look (Yoodli) and Google's flat utility look. Both are
  credible and joyless; there's nothing to come back for.

## 6. Headspace (illustration with calm professionalism, 2024 rebrand)

Sources: [It's Nice That: Italic Studio × Headspace](https://Itsnicethat.com/articles/italic-studio-headspace-graphic-design-project-250424) ·
[Design Compass on the rebrand](https://designcompass.org/en/2024/04/30/headspace/)

- **Engaging.** Round, warm characters and smooth motion "to simplify complex ideas". The faces
  now show "a range of emotions beyond a smile… stress, sadness, contentment, and every mood in
  between."
- **Premium.** A **split of roles**: illustration carries emotion; product cards and photography
  carry "a professional service". It deliberately avoids the healthcare industry's "dreary sea of
  blues and greys": colours are "bright, uplifting, bold and lively". A custom typeface
  (Aperçu-based) is "playful… friendly but functional" and can "flex from playful to clinical".
- **Borrow.** This is the core answer to the owner's brief. **Characters carry the warmth and the
  UI chrome carries the credibility.** Expressions beyond a smile (our "hmm" and "thinking"
  matter as much as the smile). Bright colour as a deliberate rejection of the sombre
  "professional" cliché.
- **Avoid.** Closed-eye blob faces. Our interviewers must look at you.

## 7. Elevate (brain training for adults)

Sources: [App Store listing](https://apps.apple.com/us/app/id875063456) ·
[Apple's Best iPhone App 2014 coverage](https://www.smartcompany.com.au/technology/brain-games-and-puzzles-the-best-apps-of-2014-announced/) ·
[Designrush](https://www.designrush.com/best-designs/apps/elevate)

- **Engaging.** 40+ games, each with its own landscape. After each game you get a score and a
  per-skill proficiency, so you see the skill grow, not just points.
- **Premium.** "Polished design and plenty of attention to detail": colourful icons on white,
  confident typography, numbers set large. It feels like a tool for adults because the **numbers
  are serious** while the art is playful.
- **Borrow.** Big, confident numerals for the four dimensions. A "skill grows over time" view (our
  baseline vs now). Each chapter gets its own colour world.
- **Avoid.** Leaderboards against strangers; the brief has no social features.

## 8. Apple Fitness+ activity rings, Gentler Streak

Sources: [MacRumors: 10 years of activity rings](https://www.macrumors.com/2025/04/14/apple-celebrates-10-years-of-activity-rings) ·
[Apple Design Awards 2024 (Gentler Streak, Social Impact)](https://www.apple.com/in/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards/) ·
[BGR: Gentler Streak redesign](https://bgr.com/tech/gentler-streak-gets-a-major-redesign-focused-on-your-wellbeing/)

- **Engaging.** The ring is the most efficient progress display ever shipped: a goal you can see
  close, with sparks when it does. Monthly challenges and limited awards create dated reasons to
  return.
- **Premium.** Minimal restraint: three colours, one shape, one gesture. Gentler Streak won an ADA
  for a **kind** streak, as likely to suggest rest as effort.
- **Borrow.** The **weekly ring** (3 sessions a week, from the brief) as the one retention gauge,
  closing with sparks. "Rest is fine" copy. A dated award for finishing a floor.
- **Avoid.** Daily pressure. A ring that resets every day would punish exactly the anxious users
  we serve.

## 9. Strava (adult achievement)

Sources: [Strava design teardown](https://blakecrosley.com/guides/design/strava) ·
[Manual × Strava Year in Sport](https://manualcreative.com/work/strava-year-in-sport-2021) ·
[Hello Monday: Year in Sport 2023](https://hellomonday.com/work/strava-year-in-sport-2023)

- **Engaging.** Personal records, kudos (one tap, a 1.2× scale pop with haptics) and an annual
  recap made of animated data scenes.
- **Premium.** One brand colour (orange) against desaturated content. The *data* is the hero and
  it is drawn beautifully (elevation as a story).
- **Borrow.** Data as storytelling: the debrief score and "then vs now" deserve the same care as
  a Strava effort graph. Personal records ("Best Specificity yet"). A shareable chapter recap.
- **Avoid.** Social comparison.

## 10. Babbel, Mimo, Imprint (adult learning brands)

Sources: [Babbel press: the rebrand](https://babbel.com/press/en-us/releases/babbel-unveils-a-bold-new-chapter-a-transformational-rebranding) ·
[Babbel magazine: new look](https://www.babbel.com/en/magazine/course-overview-update) ·
[ScreensDesign: Mimo](https://screensdesign.com/showcase/mimo-learn-codingprogramming) ·
[ScreensDesign: Imprint](https://screensdesign.com/apps/imprint-learn-visually/) ·
[Imprint on Behance](https://behance.net/gallery/189196001/Imprint-App)

- **Babbel** (with Koto, 2023–24): a modern Babbel orange, a new typeface (Feature Text),
  cut-out silhouettes and product cards. It positions itself as a **personal coach**: premium and
  adult, though rather cool. *Borrow* the coach framing and cut-out imagery. *Avoid* the
  coolness.
- **Mimo**: a thin progress line that "quietly" fills, plus XP, streaks and certificates. *Borrow*
  the quiet in-lesson progress. *Avoid* the dark IDE look.
- **Imprint** (Google Play App of the Year 2023): elegant, editorial illustration explaining
  ideas card by card. *Borrow* the editorial confidence: illustration that looks commissioned,
  not generated.

## 11. Award-winning and featured learning apps

- **CapWords**, the Apple Design Award 2025 winner for Delight and Fun
  ([Apple: behind the design](https://developer.apple.com/articles/capwords) ·
  [ADA 2025](https://developer.apple.com/design/awards/2025/)): the moment a photo **peels into a
  sticker** is the whole brand. Haptics, real sounds and physics. Processing time is hidden
  behind a micro-animation ("most users don't notice… while the gears are turning"). It was
  called "the warmest and most humane AI I've ever used." *Borrow*: one **signature physical
  moment** per loop (our card snap and the room lighting up). Hide latency in character. Warm,
  humane AI feedback.
- **Finch**, an App Store Editors' Choice
  ([Deconstructor of Fun](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl) ·
  [Appbot on attachment](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/)):
  54% D1 and 37% D7 retention from **something waiting for you**. The pet "has adventures… even
  while you're away"; the loop has timer-gated returns and no shaming tone. *Borrow*: the
  interviewers have a life between sessions ("Lena has one more question for you…"). Recall cards
  arrive like mail, not chores.
- **Gentler Streak** (above): kindness as a design award.

---

## Diagnosis of what's on main (the `redesign-existing-projects` skill)

The owner asked for the elayadesign skills (MIT) to drive this redesign:
[redesign-existing-projects](https://github.com/elayadesign/redesign-skill) for the audit and
[landing-page-design](https://github.com/elayadesign/ai-design-skills) for the values. The skill's
rule is "report the diagnosis before fixing", so here it is, item by item. **App** is main's vivid
look (`packages/brand/lib/src/vivid*.dart`, `docs/screenshots/*.jpg`, the `vivid-*` goldens).
**Web** is the live landing page (`web/`, https://thelastroom-ten.vercel.app, stills in
`.pr-screenshots/40/`).

| Skill check | App (vivid) | Web (landing) |
| --- | --- | --- |
| Approved font, one family or a briefed pair | Manrope everywhere (the brief now bans it), Cormorant Garamond in the room | Overpass + Atkinson Hyperlegible + Overpass Mono: **three** families, Overpass banned by the brief |
| Weights capped at bold | `w800` on every title (`BrandVividType`) | `font-weight: 800` seven times |
| No italics | Italic subtitles, italic quotes, italic roman numerals on the answer cards, italic reasoning in the debrief | Fine |
| No all-caps subheads | Tracked caps kickers everywhere ("UP NEXT · MISSION 2", "YOU FELL FOR", "YOUR REASONING", "OPEN · 1 OF 3") | `text-transform: uppercase` nine times, mono caps labels, an all-caps CTA |
| Type on the Tailwind scale | 32, 22, 44, 11, 15: off the scale | 72 and 112 px spacing, clamp-driven sizes |
| Flat backgrounds, no gradients | The whole look is gradients: the sky, every card (`cardGradient`), glow shadows | Flat (good), but dark petrol `#0b1d22`, not an approved dark |
| One accent, saturation under 80% | Sunflower `#FFC23D` at 100% HSL saturation; four chapter themes | Amber plus teal, blue and oxblood as accents |
| Tinted shadows, one light | Pure black at 35% (`0x59000000`) | Black at 45% |
| No one-sided card borders | The debrief's reasoning blocks use a left orange bar | Fine |
| Generic card look | Rounded gradient card plus shadow on a gradient sky, repeated for every block | Directory rows with borders and shadows |
| No pill badges | "PLAY" and "VOICE ON" pills, a yellow pill button, star ratings | Square badges (good) |
| Avatars not only circles | Every portrait sits in a circle | No people at all |
| Icons from Phosphor, Solar, Iconamoon | Material-style glyphs (play triangle, lock) | Custom arrows |
| Motion: base curve, at least 200 ms | Custom curves, some under 200 ms | `--fast: 160ms` |
| Content realism, sentence case | Mission titles in Title Case ("Tell Me About Yourself") | Fine, but a five-line subheadline |
| Loading, empty, error states | Designed (06b `SceneState`), good | No 404 found in `web/src/app` |
| Landing structure (Part A) | n/a | No proof signal above the fold, no FAQ, no tagline reveal section, a second message ("Coming soon on Google Play · App Store") beside the CTA |

**What the diagnosis says, in one line:** the vivid look's *ingredients* (colour, cast, rings,
warmth) are right. Its *execution* is what reads as childish: gradients, 800 weights, caps,
pills, stars and italics. The landing page has the opposite problem: disciplined and joyless,
dark, with no people. The fix priority from the skill (fonts, then surfaces, then states, then
layout, then motion, then components, then copy) is the order of the workstreams in
`direction.md`.

---

## Synthesis: 12 principles for The Last Room

Our niche is interview anxiety, professional stakes and a game loop. These principles turn the
research into rules for every screen.

1. **People carry the warmth; the chrome carries the trust** (Headspace, Brilliant). The cast is
   expressive, colourful and alive. Everything around them (type, grid, numbers, cards) is precise
   and quiet. Fun comes from the people and the moments, never from decorating the chrome with
   stars and pills.
2. **Daylight by default; dark only as a spotlight** (Headspace's anti-sombre palette, the
   owner's "too dark"). Screens sit on light, colour-rich grounds. Dark appears only where it
   *means* something: the "on air" voice take and a glimpse of the final room at the top of the
   tower.
3. **One climb, one next step** (Duolingo path, Speak). Home answers "what now?" in one tap: the
   tower, with the current window lit. Recall is the optional jump-in beside it.
4. **Interviewers react like colleagues, not mascots** (Lily, Headspace's range of faces). Adult
   proportions: small almond eyes with lids, brows that do the acting, a mouth that rarely opens.
   States: idle, listening, thinking, nod, smile, hmm. Latency becomes thought.
5. **Every choice is physical** (Duolingo buttons, CapWords stickers). Cards press down and snap
   into the answer, with a haptic and a soft click. One signature moment per loop: **the room
   lights up**.
6. **Feedback explains; it never scolds** (Brilliant, Interview Warmup). A weak pick earns a
   raised eyebrow and a reason, not a red X. Each score has its basis one tap away. There's *one*
   lesson.
7. **Celebrate rarely, celebrate properly** (Duolingo milestones, Apple rings). A mission ends
   with a small, crisp beat (a count-up and "+40 XP"). A floor cleared or a skill earned gets the
   full moment: the cast, the floor lighting up, the badge.
8. **Kind consistency over streaks** (Gentler Streak, Duolingo's slack data). The weekly ring (3
   sessions) is the only habit gauge. Missing a day costs nothing. Rest is said out loud.
9. **Give day 3 and day 5 a personal reason** (Finch, the brief's Recall Room). Come back for
   *your* unfinished business: "Marcus remembers what you said about the deadline." Recall cards
   arrive like a note on your desk, with the interviewer who caught the trap.
10. **Progress has the shape of the world** (rings, Finch's adventures, Strava's data scenes).
    The tower *is* the progress bar: windows light up, floors change colour, and the top floor
    stays visible as a curiosity hook. Then vs now is drawn like a Strava graph.
11. **Speaking feels safe** (Speak, Interview Warmup, Yoodli). The recording screen shows a
    listening face, the talking points to hit and a privacy line ("Stays on this phone").
    Nothing is judged while you speak.
12. **One owned motif, nothing generic** (Duolingo's three primitives, CapWords' sticker). The
    **arched window** of the tower frames portraits, mission nodes, badges and the app icon. A
    characterful typeface, no glassmorphism and no purple-to-blue "AI" gradients.

What this means for the vivid look: **keep** the chapter colours, the cast, the rings and the
sunflower accent. **Move** the ground from night sky to daylight. **Replace** cartoon stars and
pill-shaped yellow badges with the window motif and real character reactions. **Raise** the craft
of the faces, the type and the motion until it reads as made by a studio.
