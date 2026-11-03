import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

/// A question the player must answer before going on, as a sheet over the room: "Delete this
/// take?", "Leave the interview?". The mission player's sheets in the same look, with the voice
/// mission's own words (a recording is never kept, so "your progress is saved" would be untrue).
class VoiceSheet extends StatelessWidget {
  const VoiceSheet({
    super.key,
    required this.title,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    this.grade = ChapterGrade.lobby,
  });

  final String title;
  final String line;

  /// The safe choice ("Keep it", "Stay"), the honey button.
  final String primary;
  final VoidCallback onPrimary;

  /// The one that throws something away.
  final String secondary;
  final VoidCallback onSecondary;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => ChoiceSheet(
    title: title,
    line: line,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
  );
}
