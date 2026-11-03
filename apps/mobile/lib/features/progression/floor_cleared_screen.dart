import 'dart:async';
import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/haptics.dart';
import '../mission/mission_lookup.dart';
import '../tower/tower_header.dart';
import 'progression.dart';
import 'skill_badges.dart' show SkillCopy;

/// Floor cleared (direction.md §6, mockup `06`, motion 8): the one full-bleed colour screen,
/// shown once, the first time a floor's last room is finished. The floor's colour with soft
/// white rays and arch confetti; the kicker and the title, left-aligned; the floor's skill as
/// a medal (when it was earned, with no hints); the floor's three interviewers in honey-lit
/// arches, smiling; the numbers; the next floor's teaser; one honey button. Tap anywhere to
/// skip the choreography. Reduced motion: everything is there at once, faded in.
class FloorClearedScreen extends ConsumerStatefulWidget {
  const FloorClearedScreen({super.key, required this.floor});

  /// 1, 2 or 3.
  final int floor;

  static String kicker(int floor, int rooms) =>
      'Floor $floor cleared · $rooms of $rooms rooms lit';

  static String title(int floor) => switch (floor) {
    1 => 'You got through the door.',
    2 => 'You held up under pressure.',
    _ => 'You made it to the top.',
  };

  static String earnedIn(Skill s) =>
      'Earned in ${SkillCopy.where(s).toLowerCase()}, with no hints.';
  static String notYet(Skill s) =>
      '${SkillCopy.name(s)} is earned in ${SkillCopy.where(s).toLowerCase()} with no hints. '
      'Play it again any time.';

  static String teaser(Chapter next) =>
      'Floor ${next.number} is open: ${next.title}';
  static String teaserLine(Chapter next) => switch (next.number) {
    2 => 'Seven rooms. You answer out loud.',
    _ => 'Seven rooms. Choices and out loud, with Sam at the top.',
  };

  static String lift(int floor) => 'Take the lift to floor $floor';
  static String report(int floor) => 'Read your floor $floor report';
  static const String toTower = 'Back to the tower';
  static const String roomsLit = 'Rooms lit';
  static const String totalXp = 'Total XP';
  static const String thisWeek = 'This week';
  static const String skipLabel = 'Skip the celebration';

  /// The skill the floor's last room earns.
  static Skill skillOf(int floor) => switch (floor) {
    1 => Skill.evidenceBuilder,
    2 => Skill.conflictNavigator,
    _ => Skill.thinkUnderPressure,
  };

  /// The whole moment (2.4 s).
  static const Duration length = Duration(milliseconds: 2400);

  @override
  ConsumerState<FloorClearedScreen> createState() => _FloorClearedScreenState();
}

class _FloorClearedScreenState extends ConsumerState<FloorClearedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: FloorClearedScreen.length,
  );
  bool _thudded = false;

  /// When the badge lands, on the 0–1 clock.
  static const double _badgeAt = 0.33;

  @override
  void initState() {
    super.initState();
    _t.addListener(() {
      if (!_thudded && _t.value >= _badgeAt) {
        _thudded = true;
        stampThud();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t.isAnimating || _t.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = 1;
      stampThud();
      _thudded = true;
    } else {
      unawaited(_t.forward());
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _skip() {
    if (_t.isAnimating) _t.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.floor.clamp(1, chapters.length);
    final f = ChapterGrade.values[n - 1].floor;
    final next = chapters.where((c) => c.number == n + 1).firstOrNull;
    final floorMissions = missions.where((m) => m.chapter == n).toList();
    final hosts = <String>{for (final m in floorMissions) m.question.speakerId}
        .take(3)
        .toList();
    final p = ref.watch(progressionProvider).value ?? Progression.empty;
    final skill = FloorClearedScreen.skillOf(n);
    final earned = p.unlocked.contains(skill);
    final still = MediaQuery.disableAnimationsOf(context);
    final insets = MediaQuery.paddingOf(context);
    void go(String route) => context.go(route);
    final primary = n == reportedChapter
        ? TactileButton(
            label: FloorClearedScreen.report(n),
            icon: PhosphorBold.bookOpen,
            tone: TactileTone.floor,
            onPressed: () => go(Routes.report),
          )
        : TactileButton(
            label: next == null
                ? FloorClearedScreen.toTower
                : FloorClearedScreen.lift(next.number),
            icon: PhosphorBold.elevator,
            tone: TactileTone.floor,
            onPressed: () => go(Routes.tower(lit: floorMissions.last.number)),
          );
    return DaylightGround(
      color: f.base,
      floor: f,
      dark: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final t = _t.value;
            double at(double from, double to) =>
                still ? 1 : ((t - from) / (to - from)).clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RaysAndConfetti(
                          rays: at(0, 0.125),
                          fall: still ? 0 : at(0.2, 0.87),
                          floor: f,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      DaylightSpace.s16,
                      DaylightSpace.s8,
                      DaylightSpace.s16,
                      insets.bottom + DaylightSpace.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DaylightSpace.s8,
                          ),
                          child: Opacity(
                            opacity: at(0, 0.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      PhosphorFill.buildings,
                                      size: DaylightSpace.s16,
                                      color: DaylightColors.honey,
                                    ),
                                    const SizedBox(width: DaylightSpace.s4),
                                    Expanded(
                                      child: Text(
                                        FloorClearedScreen.kicker(
                                          n,
                                          floorMissions.length,
                                        ),
                                        style: DaylightType.caption3.copyWith(
                                          color: f.on,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: DaylightSpace.s8),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    FloorClearedScreen.title(n),
                                    style: DaylightType.heading3.copyWith(
                                      color: DaylightColors.raised,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: DaylightSpace.s16),
                        Center(
                          child: _medal(
                            skill,
                            earned,
                            at(0.12, 0.33),
                            at(0.33, 0.46),
                          ),
                        ),
                        const SizedBox(height: DaylightSpace.s8),
                        Opacity(
                          opacity: at(0.33, 0.46),
                          child: Text(
                            earned
                                ? FloorClearedScreen.earnedIn(skill)
                                : FloorClearedScreen.notYet(skill),
                            textAlign: TextAlign.center,
                            style: DaylightType.body5.copyWith(color: f.on),
                          ),
                        ),
                        const SizedBox(height: DaylightSpace.s16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final (i, id) in hosts.indexed) ...[
                              if (i > 0)
                                const SizedBox(width: DaylightSpace.s12),
                              _pop(
                                at(0.46 + i * 0.05, 0.62 + i * 0.05),
                                ArchPortrait(
                                  person: CastPeople.byId(id),
                                  expression: CastExpression.smile,
                                  width: _panel,
                                  height: _panelHeight,
                                  ground: DaylightColors.honey,
                                  border: DaylightSpace.s4,
                                  borderColor: DaylightColors.honeyTint,
                                  idle: false,
                                  semanticLabel: interviewerById(id).name,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: DaylightSpace.s16),
                        Opacity(
                          opacity: at(0.6, 0.75),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Stat(
                                  label: FloorClearedScreen.roomsLit,
                                  value:
                                      '${floorMissions.length}/${floorMissions.length}',
                                ),
                              ),
                              const SizedBox(width: DaylightSpace.s8),
                              Expanded(
                                child: _Stat(
                                  label: FloorClearedScreen.totalXp,
                                  value: TowerHeader.xp(p.xp)
                                      .replaceAll(' XP', ''),
                                ),
                              ),
                              const SizedBox(width: DaylightSpace.s8),
                              Expanded(
                                child: _Stat(
                                  label: FloorClearedScreen.thisWeek,
                                  value:
                                      '${math.min(p.sessionsThisWeek, p.weeklyGoal)}/${p.weeklyGoal}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (next != null) ...[
                          const SizedBox(height: DaylightSpace.s12),
                          Opacity(
                            opacity: at(0.7, 0.85),
                            child: _Teaser(next: next),
                          ),
                        ],
                        const SizedBox(height: DaylightSpace.s16),
                        Opacity(opacity: at(0.75, 0.9), child: primary),
                        if (n == reportedChapter && next != null) ...[
                          const SizedBox(height: DaylightSpace.s8),
                          Opacity(
                            opacity: at(0.75, 0.9),
                            child: TactileButton(
                              label: FloorClearedScreen.lift(next.number),
                              icon: PhosphorBold.elevator,
                              tone: TactileTone.quiet,
                              compact: true,
                              onPressed: () => go(
                                Routes.tower(lit: floorMissions.last.number),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const double _medalWidth = 184;
  static const double _panel = 80;
  static const double _panelHeight = 96;
  static const double _dropFrom = 0.8;

  Widget _medal(Skill skill, bool earned, double drop, double ribbon) {
    final medal = earned
        ? SkillMedal(
            icon: SkillCopy.icon(skill),
            name: SkillCopy.name(skill),
            width: _medalWidth,
          )
        : SkillBadge(
            icon: SkillCopy.icon(skill),
            name: SkillCopy.name(skill),
            width: _medalWidth / 2,
          );
    return Opacity(
      opacity: drop,
      child: Transform.scale(
        scale:
            _dropFrom + (1 - _dropFrom) * DaylightMotion.ease.transform(drop),
        child: medal,
      ),
    );
  }

  Widget _pop(double t, Widget child) => Opacity(
    opacity: t,
    child: Transform.translate(
      offset: Offset(
        0,
        (1 - DaylightMotion.ease.transform(t)) * DaylightSpace.s16,
      ),
      child: child,
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: f.deep,
        borderRadius: BorderRadius.circular(DaylightRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DaylightType.caption4.copyWith(color: f.on)),
            const SizedBox(height: DaylightSpace.s4),
            Text(
              value,
              style: DaylightType.tabular(DaylightType.heading6)
                  .copyWith(color: DaylightColors.raised),
            ),
          ],
        ),
      ),
    );
  }
}

/// The next floor, open: its colour, the lock open, what it asks of you.
class _Teaser extends StatelessWidget {
  const _Teaser({required this.next});

  final Chapter next;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[next.number - 1].floor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: f.base,
        borderRadius: BorderRadius.circular(DaylightRadius.card),
        boxShadow: DaylightElevation.edgeOf(f.deep),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Row(
          children: [
            Container(
              width: _tile,
              height: _tile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: f.soft,
                borderRadius: BorderRadius.circular(DaylightRadius.inner),
              ),
              child: Icon(
                PhosphorBold.lockSimpleOpen,
                size: DaylightSpace.s24 - DaylightSpace.s4,
                color: f.deep,
              ),
            ),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FloorClearedScreen.teaser(next),
                    style: DaylightType.body4.copyWith(
                      color: DaylightColors.raised,
                    ),
                  ),
                  Text(
                    FloorClearedScreen.teaserLine(next),
                    style: DaylightType.caption4.copyWith(color: f.on),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rays (7% white, fanning from behind the badge) and the arch confetti falling.
class _RaysAndConfetti extends CustomPainter {
  _RaysAndConfetti({
    required this.rays,
    required this.fall,
    required this.floor,
  });

  final double rays;
  final double fall;
  final FloorColours floor;

  static const double _rayAlpha = 0.07;
  static const int _rayCount = 8;
  static const int _bits = 14;
  static const int _seed = 7;
  static const double _bitW = 10;
  static const double _bitH = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.38);
    final reach = size.longestSide;
    final ray = Paint()
      ..color = DaylightColors.raised.withValues(alpha: _rayAlpha * rays);
    for (var i = 0; i < _rayCount; i++) {
      final a = i * 2 * math.pi / _rayCount;
      const w = 0.12;
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(
          centre.dx + math.cos(a - w) * reach,
          centre.dy + math.sin(a - w) * reach,
        )
        ..lineTo(
          centre.dx + math.cos(a + w) * reach,
          centre.dy + math.sin(a + w) * reach,
        )
        ..close();
      canvas.drawPath(path, ray);
    }
    if (fall <= 0 || fall >= 1) return;
    final random = math.Random(_seed);
    final colours = [
      DaylightColors.honey,
      DaylightColors.raised,
      floor.soft,
      DaylightFloors.three.soft,
      DaylightFloors.two.soft,
    ];
    for (var i = 0; i < _bits; i++) {
      final x = random.nextDouble() * size.width;
      final y0 = -_bitH - random.nextDouble() * size.height * 0.3;
      final y = y0 + fall * (size.height * (0.7 + random.nextDouble() * 0.4));
      final turn = (random.nextDouble() - 0.5) * math.pi * (1 + fall);
      final paint = Paint()
        ..color = colours[i % colours.length].withValues(alpha: 1 - fall * 0.6);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(turn);
      // An arch: the motif, even in the confetti.
      final r = RRect.fromRectAndCorners(
        const Rect.fromLTWH(-_bitW / 2, -_bitH / 2, _bitW, _bitH),
        topLeft: const Radius.circular(_bitW / 2),
        topRight: const Radius.circular(_bitW / 2),
      );
      canvas
        ..drawRRect(r, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_RaysAndConfetti old) =>
      old.rays != rays || old.fall != fall;
}
