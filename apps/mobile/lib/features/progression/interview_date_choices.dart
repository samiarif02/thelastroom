import 'dart:async';

import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'progression.dart';

/// FR-4's optional interview date, as a few big tiles rather than a calendar: close enough to
/// pace the reminders' countdown, quick to answer, and "Not sure yet" is a fine answer. It saves
/// on tap and stays on the device. Onboarding shows it as a step. Daylight (brief 48): white
/// tiles on a hard edge, two across; the picked one takes the floor's tint, ring and a check.
class InterviewDateChoices extends ConsumerStatefulWidget {
  const InterviewDateChoices({super.key});

  static const String kicker = 'Optional';
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

  static const double _iconSize = 20;
  static const double _largeAt = 1.3;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        // Two across; one at large text, so a label never breaks inside a word.
        final large =
            MediaQuery.textScalerOf(context).scale(DaylightSpace.s16) >
            DaylightSpace.s16 * _largeAt;
        final half = (box.maxWidth - DaylightSpace.s12) / 2;
        const choices = InterviewDateChoices.choices;
        return Wrap(
          spacing: DaylightSpace.s12,
          runSpacing: DaylightSpace.s12,
          children: [
            for (final (i, (label, days)) in choices.indexed)
              SizedBox(
                // "Not sure yet", the odd one out, takes the whole row.
                width: large || i == choices.length - 1 ? box.maxWidth : half,
                child: Tactile(
                  label: label,
                  selected: _picked == label,
                  onTap: () => _pick(label, days),
                  style: TactileStyle(
                    face: _picked == label ? f.tint : DaylightColors.raised,
                    edge: _picked == label ? f.base : DaylightColors.sand2,
                    radius: BorderRadius.circular(DaylightRadius.card),
                    ring: _picked == label ? f.base : null,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: DaylightSize.button,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DaylightSpace.s16,
                        vertical: DaylightSpace.s12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _picked == label
                                ? PhosphorFill.checkCircle
                                : days == null
                                ? PhosphorRegular.clock
                                : PhosphorRegular.calendarBlank,
                            size: _iconSize,
                            color: _picked == label
                                ? f.base
                                : DaylightColors.ink2,
                          ),
                          const SizedBox(width: DaylightSpace.s12),
                          Expanded(
                            child: Text(
                              label,
                              style: DaylightType.body2.copyWith(
                                color: _picked == label
                                    ? f.deep
                                    : DaylightColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
