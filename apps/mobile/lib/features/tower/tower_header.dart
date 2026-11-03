import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../progression/progression.dart';

/// The top of the tower (direction.md §1, mockup `01-home`): the date (Caption 4), the
/// greeting (Heading 4) and the weekly ring (56, "2/3", "this week"); under them the XP and,
/// when one is set, the interview countdown. A first visit says how the week starts. When a
/// session has just closed the week, the ring sweeps to full and six sparks fly (motion 6).
class TowerHeader extends ConsumerWidget {
  const TowerHeader({
    super.key,
    required this.name,
    required this.progression,
    this.firstVisit = false,
    this.weekJustClosed = false,
  });

  final String name;
  final Progression progression;
  final bool firstVisit;
  final bool weekJustClosed;

  static const String thisWeek = 'this week';
  static const String firstWeek = 'Your week starts with one room.';

  /// "Morning, Sami." by the player's clock. A name typed with a full stop doesn't get two.
  static String greeting(String name, int hour) {
    final who = PlayerProfile.spokenName(name);
    final part = hour < _noon
        ? 'Morning'
        : hour < _evening
        ? 'Afternoon'
        : 'Evening';
    return '$part, $who.';
  }

  static const int _noon = 12;
  static const int _evening = 18;

  static String xp(int xp) => '${_grouped(xp)} XP';

  static String countdown(int days) => switch (days) {
    < 0 => 'Interview done',
    0 => 'Interview today',
    1 => 'Interview tomorrow',
    _ => 'Interview in $days days',
  };

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "Tuesday, 12 November".
  static String date(DateTime t) =>
      '${_days[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]}';

  /// 1247 → "1,247".
  static String _grouped(int n) {
    final s = '$n';
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(progressionClockProvider)();
    final p = progression;
    final interview = p.interviewDate;
    final daysLeft = interview == null ? null : dayOf(now).daysUntil(interview);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date(now),
                    style: DaylightType.caption4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                  const SizedBox(height: DaylightSpace.s2),
                  Semantics(
                    header: true,
                    child: Text(
                      greeting(name, now.hour),
                      style: DaylightType.heading4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DaylightSpace.s12),
            _Sparks(
              on: weekJustClosed,
              child: WeeklyRing(
                done: p.sessionsThisWeek,
                goal: p.weeklyGoal,
                caption: thisWeek,
              ),
            ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s12),
        Wrap(
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s8,
          children: [
            Tag(
              label: xp(p.xp),
              icon: PhosphorFill.lightning,
              tone: TagTone.honey,
            ),
            if (daysLeft != null)
              Tag(label: countdown(daysLeft), icon: PhosphorBold.calendarBlank),
          ],
        ),
        if (firstVisit) ...[
          const SizedBox(height: DaylightSpace.s8),
          Text(
            firstWeek,
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
        ],
      ],
    );
  }
}

/// Motion 6: six honey sparks radiate from the ring as it closes, 40 ms apart, 500 ms each.
/// Reduced motion: none (the ring's honey says it).
class _Sparks extends StatefulWidget {
  const _Sparks({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  State<_Sparks> createState() => _SparksState();
}

class _SparksState extends State<_Sparks> with SingleTickerProviderStateMixin {
  static const int _count = 6;
  static const Duration _each = Duration(milliseconds: 500);
  static const Duration _gap = Duration(milliseconds: 40);

  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: DaylightMotion.ringClose + _each + _gap * _count,
  );

  @override
  void didUpdateWidget(_Sparks old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on && !MediaQuery.disableAnimationsOf(context)) {
      _t.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      widget.child,
      Positioned(
        top: WeeklyRing.defaultSize / 2,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              painter: _SparkPainter(
                elapsed: _t.value * _t.duration!.inMilliseconds,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.elapsed});

  final double elapsed;

  static const double _from = 32;
  static const double _to = 52;
  static const double _size = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final start = DaylightMotion.ringClose.inMilliseconds.toDouble();
    final paint = Paint()..color = DaylightColors.honey;
    for (var i = 0; i < _SparksState._count; i++) {
      final t =
          ((elapsed - start - i * _SparksState._gap.inMilliseconds) /
                  _SparksState._each.inMilliseconds)
              .clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final a = -math.pi / 2 + i * 2 * math.pi / _SparksState._count;
      final r = _from + (_to - _from) * DaylightMotion.ease.transform(t);
      paint.color = DaylightColors.honey.withValues(alpha: 1 - t);
      canvas.drawCircle(Offset.fromDirection(a, r), _size, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.elapsed != elapsed;
}
