import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

/// The voice toggle in the top bar of a voice mission: the interviewers' lines are spoken, or
/// only subtitled (the bubble is always on). A raised tag-sized button in a 48 target.
class MuteControl extends StatelessWidget {
  const MuteControl({super.key, required this.muted, required this.onPressed});

  final bool muted;
  final VoidCallback onPressed;

  static const String on = 'Voice on';
  static const String off = 'Voice off';
  static const String muteLabel = 'Mute the interviewer';
  static const String unmuteLabel = 'Let the interviewer speak';
  static const double _icon = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return Tactile(
      label: muted ? unmuteLabel : muteLabel,
      onTap: onPressed,
      style: TactileStyle(
        face: DaylightColors.raised,
        edge: DaylightColors.sand2,
        radius: BorderRadius.circular(DaylightRadius.inner),
        depth: DaylightSize.edgeSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DaylightSpace.s12,
          vertical: DaylightSpace.s8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              muted ? PhosphorBold.ear : PhosphorBold.speakerHigh,
              size: _icon,
              color: muted ? DaylightColors.ink2 : f.deep,
            ),
            const SizedBox(width: DaylightSpace.s4),
            Text(
              muted ? off : on,
              style: DaylightType.caption3.copyWith(
                color: muted ? DaylightColors.ink2 : f.deep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// While the recruiter listens to the recording (at most `VoiceScorer.timeout`): the
/// interviewer in an arch, thinking (the delay reads as thought, never a spinner).
class ListeningCard extends StatelessWidget {
  const ListeningCard({
    super.key,
    this.grade = ChapterGrade.lobby,
    this.person = CastPeople.marcus,
  });

  final ChapterGrade grade;
  final CastPerson person;

  static const String title = 'The recruiter is listening…';
  static const String line =
      'Your answer is being transcribed and scored on what you said. If it takes too long, '
      "you'll tick your own points instead.";

  static const double _arch = 120;
  static const double _archHeight = 148;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArchPortrait(
          person: person,
          expression: CastExpression.thinking,
          width: _arch,
          height: _archHeight,
          ground: grade.floor.soft,
        ),
        const SizedBox(height: DaylightSpace.s24),
        ExcludeSemantics(child: Text(title, style: DaylightType.heading5)),
        const SizedBox(height: DaylightSpace.s8),
        Text(
          line,
          style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
        ),
      ],
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
  Widget build(BuildContext context) => DaylightPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              PhosphorBold.microphoneSlash,
              size: DaylightSpace.s24,
              color: grade.floor.deep,
            ),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(child: Text(line, style: DaylightType.body5)),
          ],
        ),
        const SizedBox(height: DaylightSpace.s16),
        TactileButton(label: done, icon: PhosphorBold.check, onPressed: onDone),
      ],
    ),
  );
}
