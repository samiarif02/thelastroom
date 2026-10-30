import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';
import 'tower_rooms.dart';

/// One room on the Tower: a window in the facade and the mission's title beside it.
///
/// - done: the window is lit, the best score stamped in its corner; tap to replay.
/// - current: the window glows (pulsing, unless motion is reduced) under an "Enter" tab.
/// - locked: dark glass, a lock, the title as a teaser.
///
/// [lighting] runs 0 → 1 as a just-finished room lights up (the reward moment).
class RoomWindow extends StatelessWidget {
  const RoomWindow({
    super.key,
    required this.room,
    required this.grade,
    required this.onTap,
    this.pulse = 0,
    this.lighting = 1,
  });

  final TowerRoom room;
  final ChapterGrade grade;
  final VoidCallback onTap;

  /// The current room's glow, 0 → 1 → 0.
  final double pulse;
  final double lighting;

  static const String enter = 'Enter';
  static const String replay = 'Play again';

  static const double _window = 56;
  static const double _hairline = 0.8;
  static const double _glowBlur = 22;

  /// The current room never dims below this while it pulses.
  static const double _glowFloor = 0.55;
  static const double _stampAngle = -0.1;

  String get _semantics {
    final m = room.mission;
    return switch (room.state) {
      RoomState.done =>
        'Mission ${m.number}, ${m.title}. Done, best score ${room.best}. Tap to play again.',
      RoomState.current => 'Mission ${m.number}, ${m.title}. Enter.',
      RoomState.locked => 'Mission ${m.number}, ${m.title}. Locked.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = room.state;
    final key = grade.key;
    final lit = state == RoomState.done ? lighting : 0.0;
    final glow = state == RoomState.current
        ? _glowFloor + (1 - _glowFloor) * pulse
        : lit;
    return Semantics(
      button: true,
      label: _semantics,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _window + BrandSpace.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
            child: Row(
              children: [
                _Window(
                  state: state,
                  grade: grade,
                  glow: glow,
                  best: room.best,
                  lit: lit,
                ),
                const SizedBox(width: BrandSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MISSION ${room.mission.number}',
                        style: BrandType.label.copyWith(
                          color: state == RoomState.locked
                              ? BrandColors.textSecondary.withValues(alpha: 0.6)
                              : key,
                        ),
                      ),
                      Text(
                        room.mission.title,
                        style: BrandType.choice.copyWith(
                          color: state == RoomState.locked
                              ? BrandColors.textSecondary
                              : BrandColors.textPrimary,
                        ),
                      ),
                      // Under the title, not beside it: at 2x text there's no room beside.
                      if (state == RoomState.done)
                        Text(
                          replay.toUpperCase(),
                          style: BrandType.label.copyWith(
                            color: BrandColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: BrandSpace.sm),
                switch (state) {
                  RoomState.current => _Tab(label: enter, grade: grade),
                  RoomState.done || RoomState.locked => const SizedBox.shrink(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({
    required this.state,
    required this.grade,
    required this.glow,
    required this.best,
    required this.lit,
  });

  final RoomState state;
  final ChapterGrade grade;
  final double glow;
  final int? best;
  final double lit;

  @override
  Widget build(BuildContext context) {
    final key = grade.key;
    const size = RoomWindow._window;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(BrandColors.void_, grade.tint, glow),
          border: Border.all(
            color: key.withValues(alpha: 0.25 + 0.6 * glow),
            width: RoomWindow._hairline,
          ),
          boxShadow: [
            if (glow > 0)
              BoxShadow(
                color: key.withValues(alpha: 0.45 * glow),
                blurRadius: RoomWindow._glowBlur,
              ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The window's cross bars.
            Center(
              child: SizedBox(
                width: RoomWindow._hairline,
                child: ColoredBox(color: key.withValues(alpha: 0.3)),
              ),
            ),
            Center(
              child: SizedBox(
                height: RoomWindow._hairline,
                child: ColoredBox(color: key.withValues(alpha: 0.3)),
              ),
            ),
            if (state == RoomState.locked)
              const Center(child: LockGlyph(color: BrandColors.textSecondary)),
            if (best case final score? when state == RoomState.done)
              Center(
                child: Opacity(
                  opacity: lit,
                  child: StampIn(
                    t: lit,
                    angle: RoomWindow._stampAngle,
                    child: Text(
                      '$score',
                      style: BrandType.stamp.copyWith(color: key),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "ENTER" in a brass tab: Duolingo's START bubble, in the film's language.
class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.grade});

  final String label;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: grade.key,
      borderRadius: BorderRadius.circular(BrandRadius.md),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.md,
        vertical: BrandSpace.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: BrandType.label.copyWith(color: BrandColors.void_),
      ),
    ),
  );
}

/// A small padlock, drawn: shackle and body.
class LockGlyph extends StatelessWidget {
  const LockGlyph({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size(size, size), painter: _LockPainter(color)),
  );
}

class _LockPainter extends CustomPainter {
  const _LockPainter(this.color);

  final Color color;

  static const double _stroke = 1.4;
  static const double _bodyTop = 0.45;
  static const double _shackleInset = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final w = size.width;
    final h = size.height;
    canvas
      ..drawRect(Rect.fromLTRB(0, h * _bodyTop, w, h), paint)
      ..drawArc(
        Rect.fromLTRB(w * _shackleInset, 0, w * (1 - _shackleInset), h * 0.8),
        math.pi,
        math.pi,
        false,
        paint,
      );
  }

  @override
  bool shouldRepaint(_LockPainter old) => old.color != color;
}
