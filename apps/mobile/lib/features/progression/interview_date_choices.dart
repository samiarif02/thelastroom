import 'dart:async';

import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/film_kit.dart';
import 'progression.dart';

/// FR-4's optional interview date, as a few big chips rather than a calendar: close enough to
/// pace the reminders' countdown, quick to answer, and "Not sure yet" is a fine answer. It saves
/// on tap and stays on the device. Onboarding shows it as a step.
class InterviewDateChoices extends ConsumerStatefulWidget {
  const InterviewDateChoices({super.key});

  static const String kicker = 'OPTIONAL';
  static const String title = 'When’s your interview?';
  static const String line =
      'We’ll count down to it in your reminders. It stays on this device.';

  /// The chips: a label and how many days from today (null: no date).
  static const List<(String, int?)> choices = [
    ('This week', 4),
    ('Next week', 10),
    ('In two weeks', 14),
    ('In a month', 30),
    ('Not sure yet', null),
  ];

  @override
  ConsumerState<InterviewDateChoices> createState() =>
      _InterviewDateChoicesState();
}

class _InterviewDateChoicesState extends ConsumerState<InterviewDateChoices> {
  String? _picked;

  void _pick(String label, int? days) {
    setState(() => _picked = label);
    final today = dayOf(ref.read(progressionClockProvider)());
    final CalendarDay? date = days == null ? null : today.addDays(days);
    unawaited(ref.read(progressionActionsProvider).setInterviewDate(date));
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: BrandSpace.sm,
    runSpacing: BrandSpace.sm,
    children: [
      for (final (label, days) in InterviewDateChoices.choices)
        Semantics(
          selected: _picked == label,
          child: VividButton(
            label: label,
            primary: _picked == label,
            onPressed: () => _pick(label, days),
          ),
        ),
    ],
  );
}
