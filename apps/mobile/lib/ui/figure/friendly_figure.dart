import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// An interviewer as the scenes that predate Daylight address them: a handle on one of the
/// cast (`CastPeople` in `packages/brand`), drawn by `CastFigure`. Kept so those screens show
/// the Daylight cast without changing; new code uses `CastPerson` and `CastFigure` directly.
///
/// The old figures stood in a 100 × 120 box; the cast's 200 grid sits in it at [gridScale],
/// [gridTop] down, so the face lands where the old face did ([faceCenter], inside
/// `MissionSet.faceInDesign`) and the torso runs on to the bottom edge.
@immutable
class FriendlyFigure {
  const FriendlyFigure._(this.person);

  final CastPerson person;

  /// The content id of the interviewer (`packages/content`).
  String get id => person.id;

  /// The cast's grid in the 100 × 120 box: half size.
  static const double gridScale = 0.5;

  /// How far down the box the grid starts.
  static const double gridTop = 2;

  /// Grid units the torso continues below the bust to reach the box's bottom edge.
  static const double extendBelow = (120 - gridTop) / gridScale - CastBody.grid;

  /// The middle of the face, in the box's units.
  static const Offset faceCenter = Offset(
    CastBody.grid / 2 * gridScale,
    CastFeatures.eyeY * gridScale + gridTop,
  );

  static const FriendlyFigure priya = FriendlyFigure._(CastPeople.priya);
  static const FriendlyFigure marcus = FriendlyFigure._(CastPeople.marcus);
  static const FriendlyFigure lena = FriendlyFigure._(CastPeople.lena);
  static const FriendlyFigure sam = FriendlyFigure._(CastPeople.sam);

  /// Every figure, by content id.
  static final Map<String, FriendlyFigure> byId = {
    for (final f in [priya, marcus, lena, sam]) f.id: f,
  };

  /// The figure for content id [id]; Priya for an unknown one.
  static FriendlyFigure of(String id) => byId[id] ?? priya;
}
