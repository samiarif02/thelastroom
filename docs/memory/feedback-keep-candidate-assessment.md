---
name: feedback-keep-candidate-assessment
description: The debrief's Candidate assessment sheet stays exactly as it is, look and animations; the ground around it is Daylight (owner, 2026-11-03)
type: feedback
---

The debrief's **Candidate assessment** dossier is kept exactly as it is, look and animations both,
overriding `docs/design/direction.md` §5 ("This replaces the dossier"). The owner, 2026-11-03:
"the assessment complete in the current design is okay… the reviewer liked it, so don't change
this and its animations."

That covers the paper sheet, the N monogram, the NORTHSTAR LABS letterhead, the serif "Candidate
assessment" title and its subtitle, the four dimension rows with "/100" stamps, the red-pen
underline on the weakest row, the red lesson note, the wax seal with "OVERALL", the slide-in /
stamp / seal / pen timeline, and the `stampThud` haptics.

The ground and everything around the sheet are Daylight (the owner, later that day: "this view
background is still the previous colours"): the trust line, XP, the cards under it and the CTA
are restyled; a soft shadow under the sheet is fine.

**How to apply:** never edit `apps/mobile/lib/ui/paper/**`, nor the tokens and fonts it reads
(`colors.dart` paper/ink/red pen/seal, `typography.dart`, `motion.dart`, Cormorant Garamond, and
the sans it reads through `BrandType`). Retiring old tokens keeps every value the paper widgets
read, unchanged. The goldens `paper-dossier.png` and `paper-seal-stamp-pen.png` must never appear
in a diff. In `features/debrief/` and `voice_debrief.dart`, everything but the `Dossier(...)`
call may change, as long as the sheet is untouched.
