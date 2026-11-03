import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

/// "Too fast: read before you answer": a guessed pick, called out on screen as the
/// interviewer calls it out in words. A honey tag (never red: the trap colour is the
/// debrief's), fading in and out with [shown].
class GuessCue extends StatelessWidget {
  const GuessCue({super.key, required this.shown});

  final bool shown;

  static const String text = 'Too fast: read before you answer';

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: DaylightMotion.colour,
      curve: DaylightMotion.ease,
      child: Semantics(
        liveRegion: true,
        label: shown ? text : null,
        excludeSemantics: true,
        child: const Tag(
          label: text,
          icon: PhosphorBold.hourglass,
          tone: TagTone.honeySolid,
        ),
      ),
    ),
  );
}

/// The back button mid-mission: stay, or leave with the attempt saved on the device.
class LeaveSheet extends StatelessWidget {
  const LeaveSheet({
    super.key,
    required this.onResume,
    required this.onLeave,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onResume;
  final VoidCallback onLeave;
  final ChapterGrade grade;

  static const String title = 'Leave the interview?';
  static const String line =
      'Your progress is saved. You can continue where you left off.';
  static const String resume = 'Resume';
  static const String leave = 'Leave';

  @override
  Widget build(BuildContext context) => ChoiceSheet(
    title: title,
    line: line,
    primary: resume,
    onPrimary: onResume,
    secondary: leave,
    onSecondary: onLeave,
  );
}

/// Reopening a mission the player left: continue it, or start again.
class ResumeSheet extends StatelessWidget {
  const ResumeSheet({
    super.key,
    required this.onContinue,
    required this.onRestart,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final ChapterGrade grade;

  static const String title = 'Continue where you left off?';
  static const String line = 'Your answers so far are kept, in the same order.';
  static const String resume = 'Continue';
  static const String restart = 'Start again';

  @override
  Widget build(BuildContext context) => ChoiceSheet(
    title: title,
    line: line,
    primary: resume,
    primaryIcon: PhosphorFill.play,
    onPrimary: onContinue,
    secondary: restart,
    onSecondary: onRestart,
  );
}
