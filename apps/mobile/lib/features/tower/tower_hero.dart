import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';
import '../mission/mission_lookup.dart';
import 'tower_rooms.dart';

/// The top of the tower (brief 17): the mission to play next, big, in its chapter's colour,
/// with the interviewer waiting and one "Play". One tap starts it; nothing to scroll for.
/// Once every room is done it offers the weakest one again, to beat.
class TowerHero extends StatelessWidget {
  const TowerHero({super.key, required this.room, required this.onPlay});

  final TowerRoom room;
  final VoidCallback onPlay;

  static const String upNext = 'UP NEXT';
  static const String beatYourBest = 'BEAT YOUR BEST';
  static const String playAgain = 'Play again';

  /// What the Play button says to a screen reader.
  static String playLabel(TowerRoom room) =>
      '${room.state == RoomState.done ? playAgain : VividButton.playLabel} '
      'Mission ${room.mission.number}, ${room.mission.title}';

  static const double _badge = 84;

  /// The sunbeam's strength: enough for depth, low enough that the kicker over it stays AA in
  /// every theme (brief 31).
  static const double _sunbeam = 0.16;
  static const int _quoteLines = 3;

  @override
  Widget build(BuildContext context) {
    final m = room.mission;
    final grade = m.grade;
    final lead = m.lead;
    final replay = room.state == RoomState.done;
    final kicker = '${replay ? beatYourBest : upNext} · MISSION ${m.number}';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grade.cardGradient,
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: BrandVivid.glowShadow(grade.glow),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        child: Stack(
          children: [
            // A sunbeam across the card: depth, not a flat fill.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.1,
                    colors: [
                      grade.glow.withValues(alpha: _sunbeam),
                      grade.glow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BrandSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kicker, style: BrandVividType.kicker),
                            const SizedBox(height: BrandSpace.sm),
                            Semantics(
                              header: true,
                              child: Text(m.title, style: BrandVividType.hero),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BrandSpace.md),
                      InterviewerBadge(
                        figure: FriendlyFigure.of(lead.id),
                        ring: grade.glow,
                        grade: grade,
                        size: _badge,
                        semanticLabel: '${lead.name}, ${lead.role}',
                      ),
                    ],
                  ),
                  const SizedBox(height: BrandSpace.md),
                  Text(
                    '“${m.question.text}”',
                    maxLines: _quoteLines,
                    overflow: TextOverflow.ellipsis,
                    style: BrandVividType.body.copyWith(
                      color: BrandVivid.onDeep,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: BrandSpace.xs),
                  Text(
                    '${lead.name} · ${lead.role}',
                    style: BrandVividType.kicker,
                  ),
                  if (replay && room.best != null) ...[
                    const SizedBox(height: BrandSpace.sm),
                    StarRow(stars: room.stars, best: room.best!),
                  ],
                  const SizedBox(height: BrandSpace.lg),
                  Semantics(
                    label: playLabel(room),
                    button: true,
                    excludeSemantics: true,
                    onTap: onPlay,
                    child: VividButton.play(
                      label: replay ? playAgain : VividButton.playLabel,
                      expand: true,
                      onPressed: onPlay,
                    ),
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

/// Up to three stars and the best score: a done mission's grade.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    required this.best,
    this.size = 18,
  });

  final int stars;
  final int best;
  final double size;

  static const double _emptyAlpha = 0.28;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars of $maxStars stars, best $best',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maxStars; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: CustomPaint(
              size: Size.square(size),
              painter: StarPainter(
                color: i < stars
                    ? BrandVivid.accent
                    : BrandVivid.onDeep.withValues(alpha: _emptyAlpha),
              ),
            ),
          ),
        const SizedBox(width: BrandSpace.xs),
        Text(
          '$best',
          style: BrandVividType.row.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

/// A five-pointed star, filled.
class StarPainter extends CustomPainter {
  const StarPainter({required this.color});

  final Color color;

  static const int _points = 5;
  static const double _inner = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < _points * 2; i++) {
      final radius = i.isEven ? r : r * _inner;
      final a = -math.pi / 2 + i * math.pi / _points;
      final p = c + Offset.fromDirection(a, radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(StarPainter old) => old.color != color;
}
