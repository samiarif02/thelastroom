import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The top of the building (brief §9): the last room, always in sight, out of reach for now.
class LastRoomCard extends StatelessWidget {
  const LastRoomCard({super.key});

  static const String title = 'The Last Room';
  static const String line = 'The offer is decided here.';
  static const String kicker = 'THE TOP FLOOR';

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.finalRound;
    return _FeatureCard(
      colors: [grade.deeper, BrandVivid.night],
      glow: grade.glow,
      kicker: kicker,
      title: title,
      line: line,
      trailing: const LockGlyph(color: BrandVivid.onDeepSoft, size: 22),
    );
  }
}

/// The Recall Room (FR-50s), a clear card while it's still coming.
class RecallRoomCard extends StatelessWidget {
  const RecallRoomCard({super.key});

  static const String title = 'Recall Room';
  static const String line =
      'A few minutes a day to keep what you learned sharp.';
  static const String comingSoon = 'Coming soon';

  @override
  Widget build(BuildContext context) => _FeatureCard(
    colors: const [BrandVivid.locked, BrandVivid.night],
    glow: BrandVivid.accent,
    kicker: comingSoon.toUpperCase(),
    title: title,
    line: line,
    trailing: const LockGlyph(color: BrandVivid.onDeepSoft, size: 22),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.colors,
    required this.glow,
    required this.kicker,
    required this.title,
    required this.line,
    required this.trailing,
  });

  final List<Color> colors;
  final Color glow;
  final String kicker;
  final String title;
  final String line;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title. $kicker. $line',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(BrandSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: BrandVivid.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: BrandVividType.kicker.copyWith(color: glow),
                ),
                const SizedBox(height: 2),
                Text(title, style: BrandVividType.title),
                const SizedBox(height: BrandSpace.xs),
                Text(line, style: BrandVividType.body),
              ],
            ),
          ),
          const SizedBox(width: BrandSpace.md),
          trailing,
        ],
      ),
    ),
  );
}
