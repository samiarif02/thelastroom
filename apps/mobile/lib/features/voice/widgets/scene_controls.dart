import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../../debrief/red_pen_slip.dart';

/// The voice toggle in the corner of a voice mission: the interviewers' lines are spoken, or
/// only subtitled (subtitles are always on). One labelled 48 pt target.
class MuteControl extends StatelessWidget {
  const MuteControl({super.key, required this.muted, required this.onPressed});

  final bool muted;
  final VoidCallback onPressed;

  static const String on = 'VOICE ON';
  static const String off = 'VOICE OFF';
  static const String muteLabel = 'Mute the interviewer';
  static const String unmuteLabel = 'Let the interviewer speak';
  static const double _alpha = 0.7;

  @override
  Widget build(BuildContext context) => Pressable(
    label: muted ? unmuteLabel : muteLabel,
    onTap: onPressed,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
      child: Center(
        widthFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandVivid.night.withValues(alpha: _alpha),
            borderRadius: BorderRadius.circular(BrandRadius.pill),
            border: Border.all(
              color: muted ? BrandVivid.hairline() : BrandVivid.accent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSpace.md,
              vertical: BrandSpace.sm,
            ),
            child: Text(
              muted ? off : on,
              style: BrandVividType.kicker.copyWith(
                color: muted ? BrandVivid.onDeepSoft : BrandVivid.accent,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// While the recruiter listens to the recording (at most `VoiceScorer.timeout`).
class ListeningCard extends StatelessWidget {
  const ListeningCard({super.key, this.grade = ChapterGrade.lobby});

  final ChapterGrade grade;

  static const String title = 'The recruiter is listening…';
  static const String line =
      'Your answer is being transcribed and scored on what you said. If it takes too long, '
      "you'll tick your own points instead.";

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: title,
    child: PaperSlip(
      grade: grade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: BrandSpace.xxl,
            child: ExcludeSemantics(child: BankersLamp()),
          ),
          const SizedBox(height: BrandSpace.md),
          ExcludeSemantics(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: BrandVividType.title,
            ),
          ),
          const SizedBox(height: BrandSpace.sm),
          Text(
            line,
            textAlign: TextAlign.center,
            style: BrandType.body.copyWith(color: SlipInk.text),
          ),
        ],
      ),
    ),
  );
}

/// Answering with no recording (the microphone refused): say it out loud, then Done.
class SpokenAloudPanel extends StatelessWidget {
  const SpokenAloudPanel({
    super.key,
    required this.onDone,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onDone;
  final ChapterGrade grade;

  static const String line =
      "Say your answer out loud, as you would in the room. Tap Done when you've finished.";
  static const String done = 'Done';

  @override
  Widget build(BuildContext context) => PaperSlip(
    grade: grade,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          line,
          textAlign: TextAlign.center,
          style: BrandType.body.copyWith(color: SlipInk.text),
        ),
        const SizedBox(height: BrandSpace.md),
        VividButton(label: done, expand: true, onPressed: onDone),
      ],
    ),
  );
}
