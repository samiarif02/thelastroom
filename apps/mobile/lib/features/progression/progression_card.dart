import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'progression.dart';

/// The player's progress as the hero of Your file (brief 32; Daylight in brief 48): a floor 1
/// panel, the up-next card's colour, with the XP large, the soft weekly goal as a honey ring on
/// the floor's deep track, the week in words and the interview countdown when a date is set.
/// [stats] sit under it as deep tiles (rooms lit, average, the best gain on a replayed room), and
/// [footer] at the foot (the empty file's "Start room 1"). Never punishing: a quiet week is
/// just "so far".
class ProgressionCard extends ConsumerWidget {
  const ProgressionCard({super.key, this.stats = const [], this.footer});

  final List<Widget> stats;
  final Widget? footer;

  static const String kicker = 'Your progress';
  static const String xpLabel = 'XP';
  static const String ringCaption = 'this week';

  static String weekLine(int done, int goal) {
    if (done >= goal) return 'Goal met this week. Anything more is a bonus.';
    if (done == 0) return 'A new week: 0 of $goal sessions so far.';
    return '$done of $goal sessions this week.';
  }

  static String countdown(int days) => switch (days) {
    0 => 'Your interview is today. You are ready.',
    1 => 'Your interview is tomorrow.',
    _ => 'Your interview is in $days days.',
  };

  /// "1,247": thousands grouped, as the mockups write XP.
  static String grouped(int n) {
    final digits = '${n.abs()}';
    final out = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  static const double _ring = 72;
  static const double _stroke = 8;
  static const double _largeAt = 1.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressionProvider).value ?? Progression.empty;
    final today = dayOf(ref.watch(progressionClockProvider)());
    final interview = p.interviewDate;
    final daysLeft = interview == null ? null : today.daysUntil(interview);
    const f = DaylightFloors.one;
    final still = MediaQuery.disableAnimationsOf(context);
    final week = weekLine(p.sessionsThisWeek, p.weeklyGoal);
    final value = p.weeklyGoal == 0
        ? 0.0
        : (p.sessionsThisWeek / p.weeklyGoal).clamp(0.0, 1.0);
    Widget ring(double v) => CustomPaint(
      painter: RingPainter(
        value: v,
        fill: DaylightColors.honey,
        track: f.deep,
        stroke: _stroke,
      ),
      child: SizedBox.square(
        dimension: _ring,
        child: Padding(
          padding: const EdgeInsets.all(_stroke * 1.5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${p.sessionsThisWeek.clamp(0, p.weeklyGoal)}/${p.weeklyGoal}',
              style: DaylightType.tabular(DaylightType.body1)
                  .copyWith(color: DaylightColors.raised),
            ),
          ),
        ),
      ),
    );
    return ChapterTint(
      floor: f,
      child: DaylightPanel(
        color: f.base,
        edge: f.deep,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(
              builder: (context) {
                final large =
                    MediaQuery.textScalerOf(context).scale(DaylightSpace.s16) >
                    DaylightSpace.s16 * _largeAt;
                final head = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker,
                      style: DaylightType.caption3.copyWith(color: f.on),
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Semantics(
                      label: '${p.xp} $xpLabel',
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: grouped(p.xp),
                              style: DaylightType.tabular(DaylightType.heading2)
                                  .copyWith(color: DaylightColors.raised),
                            ),
                            TextSpan(
                              text: ' $xpLabel',
                              style: DaylightType.title2.copyWith(color: f.on),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s8),
                    Text(
                      week,
                      style: DaylightType.body5.copyWith(
                        color: DaylightColors.raised,
                      ),
                    ),
                  ],
                );
                final gauge = Semantics(
                  label: week,
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      if (still)
                        ring(value)
                      else
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: value),
                          duration: DaylightMotion.ringClose,
                          curve: DaylightMotion.ease,
                          builder: (context, v, _) => ring(v),
                        ),
                      const SizedBox(height: DaylightSpace.s4),
                      Text(
                        ringCaption,
                        style: DaylightType.caption4.copyWith(color: f.on),
                      ),
                    ],
                  ),
                );
                // At large text the ring sits under the numbers, so the week line keeps
                // its width.
                if (large) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      head,
                      const SizedBox(height: DaylightSpace.s12),
                      gauge,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: head),
                    const SizedBox(width: DaylightSpace.s12),
                    gauge,
                  ],
                );
              },
            ),
            if (daysLeft != null && daysLeft >= 0) ...[
              const SizedBox(height: DaylightSpace.s12),
              Row(
                children: [
                  Icon(
                    PhosphorBold.calendarBlank,
                    size: DaylightSpace.s16,
                    color: f.on,
                  ),
                  const SizedBox(width: DaylightSpace.s8),
                  Expanded(
                    child: Text(
                      countdown(daysLeft),
                      style: DaylightType.body4.copyWith(
                        color: DaylightColors.raised,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (stats.isNotEmpty) ...[
              const SizedBox(height: DaylightSpace.s16),
              Builder(
                builder: (context) {
                  // Three across; one under the other at large text.
                  final large =
                      MediaQuery.textScalerOf(context)
                          .scale(DaylightSpace.s16) >
                      DaylightSpace.s16 * _largeAt;
                  if (large) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: DaylightSpace.s8,
                      children: stats,
                    );
                  }
                  // One row, every tile as tall as the tallest (owner, 4 Nov: "Best gain"
                  // wrapped to two lines and stood taller than its neighbours).
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: DaylightSpace.s8,
                      children: [for (final s in stats) Expanded(child: s)],
                    ),
                  );
                },
              ),
            ],
            if (footer case final foot?) ...[
              const SizedBox(height: DaylightSpace.s16),
              foot,
            ],
          ],
        ),
      ),
    );
  }
}

/// A number on the hero's deep colour ("Rooms lit · 4 of 21"), like the reward screen's
/// tiles: the label in the floor's on colour (Caption 4), the value large and white
/// (Heading 5, tabular), an optional [after] beside it ("of 21").
class HeroStat extends StatelessWidget {
  const HeroStat({
    super.key,
    required this.label,
    required this.value,
    this.after,
    this.semanticLabel,
  });

  final String label;
  final String value;
  final String? after;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final a = after;
    return Semantics(
      label: semanticLabel ?? '$label: $value${a == null ? '' : ' $a'}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: f.deep,
          borderRadius: BorderRadius.circular(DaylightRadius.inner),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DaylightSpace.s12,
            DaylightSpace.s8,
            DaylightSpace.s8,
            DaylightSpace.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: DaylightType.caption4.copyWith(color: f.on),
                ),
              ),
              const SizedBox(height: DaylightSpace.s2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: DaylightType.tabular(DaylightType.heading5)
                          .copyWith(color: DaylightColors.raised),
                    ),
                    if (a != null)
                      TextSpan(
                        // No number (the file's "Best gain" before a replay): just the words.
                        text: value.isEmpty ? a : ' $a',
                        style: DaylightType.body5.copyWith(color: f.on),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
