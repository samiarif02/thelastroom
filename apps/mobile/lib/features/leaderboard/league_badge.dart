import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

/// A league's name, colours and glyph (issue 72). The glyph differs per league as well as the
/// colour, so the badge reads without colour.
extension LeagueLook on League {
  String get title => switch (this) {
    League.bronze => 'Bronze',
    League.silver => 'Silver',
    League.gold => 'Gold',
    League.platinum => 'Platinum',
    League.diamond => 'Diamond',
  };

  /// "Gold league".
  String get label => '$title league';

  LeagueColours get colours => DaylightLeagues.all[index];

  IconData get glyph => switch (this) {
    League.bronze => PhosphorFill.medal,
    League.silver => PhosphorFill.medal,
    League.gold => PhosphorFill.trophy,
    League.platinum => PhosphorFill.crownSimple,
    League.diamond => PhosphorFill.sparkle,
  };
}

/// A league's medallion: its base colour with a deep rim and a white glyph, [size] across.
/// Screen readers hear "Gold league" (or nothing, when [label] is false and the row says it).
class LeagueBadge extends StatelessWidget {
  const LeagueBadge({
    super.key,
    required this.league,
    this.size = 24,
    this.label = true,
  });

  final League league;
  final double size;
  final bool label;

  static const double _rim = 0.1;
  static const double _glyph = 0.55;

  @override
  Widget build(BuildContext context) {
    final c = league.colours;
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.base,
        shape: BoxShape.circle,
        border: Border.all(color: c.deep, width: size * _rim),
      ),
      alignment: Alignment.center,
      child: Icon(
        league.glyph,
        size: size * _glyph,
        color: DaylightColors.raised,
      ),
    );
    return label
        ? Semantics(label: league.label, excludeSemantics: true, child: badge)
        : ExcludeSemantics(child: badge);
  }
}
