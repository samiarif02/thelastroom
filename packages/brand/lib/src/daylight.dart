import 'package:flutter/animation.dart' show Cubic;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'colors.dart';

/// Daylight Tower (docs/design/direction.md, "Tokens"): warm paper grounds, the chapter colours
/// as solid floors, one honey action accent. Every text pair a widget uses is AA (4.5:1), held
/// by `test/daylight_contrast_test.dart`; the rules are:
///
/// - On [paper], [sand], [raised] and every tint: [ink], [ink2].
/// - On a floor's base or deep colour: [raised] (white) or that floor's [FloorColours.on], never
///   its soft colour.
/// - A floor's deep colour on its tint, its soft colour and on white (speaker names, kickers).
/// - On [honey]: [onHoney]. Honey is never text on green.
/// - [trap] on [trapTint], [paper] and [raised]; [recall] on [recallTint] and [raised]; white
///   on [recall].
abstract final class DaylightColors {
  /// The ground on home, the debrief, the landing.
  static const Color paper = Color(0xFFFBF6EE);

  /// Wells, letter tiles, bar tracks.
  static const Color sand = Color(0xFFF3EBDF);

  /// The pressable edge, tracks. Decorative, never under text it has to carry alone.
  static const Color sand2 = Color(0xFFE7DCCB);

  /// Cards, bubbles, sheets; also the white text on a floor's colour.
  static const Color raised = Color(0xFFFFFFFF);

  /// Text, the active tab.
  static const Color ink = Color(0xFF24201C);

  /// Secondary text (never mid-grey).
  static const Color ink2 = Color(0xFF5E554B);

  /// Locked glyphs only (3.6:1 on paper): an icon on a skill that isn't earned yet. Never text.
  static const Color ink3 = Color(0xFF8A7F73);

  /// The one action accent: primary buttons, XP, lit windows.
  static const Color honey = Color(0xFFEBBE52);

  /// The hard edge under a honey button.
  static const Color honeyEdge = Color(0xFFC3962F);

  /// Text and glyphs on [honey].
  static const Color onHoney = Color(0xFF2A1E05);

  /// The XP tag and a skill that's next: honey, quiet.
  static const Color honeyTint = Color(0xFFF8EAD0);

  /// Text on [honeyTint].
  static const Color honeyInk = Color(0xFF6B4A08);

  /// The weakest dimension, "the line that cost the most": clay, never alarm red.
  static const Color trap = Color(0xFFA8432B);
  static const Color trapTint = Color(0xFFF8E4DC);

  /// The Recall Room and the welcome-back button.
  static const Color recall = Color(0xFF5E4BB4);
  static const Color recallDeep = Color(0xFF43348A);
  static const Color recallTint = Color(0xFFECE8F8);
  static const Color recallSoft = Color(0xFFCFC6EF);

  /// Illustration only: the sky, its clouds, the final floor at dusk, the far city, the desk.
  static const Color sky = Color(0xFFD4E6F4);
  static const Color skyCloud = Color(0xFFEAF3FA);
  static const Color dusk = Color(0xFF3B2A4A);
  static const Color cityFar = Color(0xFFC2D6E8);
  static const Color desk = Color(0xFFE9DCC6);
  static const Color deskTop = Color(0xFFF5ECDD);

  /// The ground the shadows are tinted toward (`rgb(94 72 40)`): lift and grain take its hue.
  static const Color shadow = Color(0xFF5E4828);
}

/// One floor's colours: the building's chapter (floor 1 green, floor 2 blue, floor 3 rose).
@immutable
class FloorColours {
  const FloorColours({
    required this.base,
    required this.deep,
    required this.tint,
    required this.soft,
    required this.on,
  });

  /// The floor itself: the up-next card, the recorder, the reward screen, progress fills.
  final Color base;

  /// The pressable edge under [base], text on [tint], [soft] and white.
  final Color deep;

  /// A mission's ground.
  final Color tint;

  /// The room's wall, the arch behind a face. Decorative on [base] (it fails as text there).
  final Color soft;

  /// Secondary text on [base] and [deep].
  final Color on;
}

/// The three floors (direction.md, "Colour").
abstract final class DaylightFloors {
  /// Floor 1, "Get through the door".
  static const FloorColours one = FloorColours(
    base: Color(0xFF147356),
    deep: Color(0xFF0E5C44),
    tint: Color(0xFFE3F3EA),
    soft: Color(0xFFBFE6D2),
    on: Color(0xFFD6F0E2),
  );

  /// Floor 2, "Under pressure" (voice).
  static const FloorColours two = FloorColours(
    base: Color(0xFF3152BD),
    deep: Color(0xFF22398A),
    tint: Color(0xFFE6ECFB),
    soft: Color(0xFFC3D2F5),
    on: Color(0xFFD3DEFA),
  );

  /// Floor 3, "The final round".
  static const FloorColours three = FloorColours(
    base: Color(0xFFC23A62),
    deep: Color(0xFF8A2343),
    tint: Color(0xFFFBE6EC),
    soft: Color(0xFFF3C0CF),
    on: Color(0xFFFFF0F4),
  );

  static const List<FloorColours> all = [one, two, three];
}

/// A chapter's floor in Daylight.
extension ChapterFloor on ChapterGrade {
  FloorColours get floor => switch (this) {
    ChapterGrade.lobby => DaylightFloors.one,
    ChapterGrade.pressure => DaylightFloors.two,
    ChapterGrade.finalRound => DaylightFloors.three,
  };
}

/// Spacing: the elayadesign scale and nothing else. The phone gutter, card padding and the gap
/// inside a section are [s16]; sections are [s24] apart.
abstract final class DaylightSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;
  static const double s80 = 80;
  static const double s96 = 96;

  /// The phone's side gutter.
  static const double gutter = s16;
}

/// Radii, from Tailwind. Nested: an element inside a card takes the card's radius minus the
/// padding between them (a button in a [panel] card with 16 padding is [inner]).
abstract final class DaylightRadius {
  /// Tags (squared, never pills).
  static const double tag = 6;

  /// Inner elements, in-card buttons, letter tiles.
  static const double inner = 8;

  /// Icon buttons, the answer-so-far strip.
  static const double tile = 12;

  /// Cards and standalone buttons.
  static const double card = 16;

  /// Panels, sheets, the room.
  static const double panel = 24;

  /// The top of an arch: large enough to be a half circle at any width.
  static const double archTop = 999;

  /// The motif: the tower's arched window, top round, bottom [card].
  static const BorderRadius arch = BorderRadius.vertical(
    top: Radius.circular(archTop),
    bottom: Radius.circular(card),
  );
}

/// Fixed sizes of the kit's parts.
abstract final class DaylightSize {
  /// A primary button's height.
  static const double button = 56;

  /// An in-card button's height (the welcome-back card's).
  static const double buttonCompact = 48;

  /// An icon button's tile; it sits in a [hit] target.
  static const double iconTile = 40;

  /// The smallest touch target (44 pt and 48 dp).
  static const double hit = 48;

  /// A tag's height.
  static const double tag = 24;

  /// A letter tile on an answer card.
  static const double letter = 32;

  /// The hard edge under a pressable element, and how far it sinks when pressed.
  static const double edge = 4;

  /// The quieter edge under an icon tile.
  static const double edgeSmall = 2;
}

/// Motion: decelerate into place on [ease]; fast for feedback, measured for movement, never
/// under 200 ms. Only transform and opacity animate. Reduced motion swaps movement for a
/// [colour]-long fade.
abstract final class DaylightMotion {
  /// The base curve, `cubic-bezier(0.22, 1, 0.36, 1)`.
  static const Cubic ease = Cubic(0.22, 1, 0.36, 1);

  /// A press: the element sinks as its edge collapses.
  static const Duration press = Duration(milliseconds: 200);

  /// Colour and opacity, and an expression's blend.
  static const Duration colour = Duration(milliseconds: 300);

  /// Movement: a sheet rising, a card snapping.
  static const Duration move = Duration(milliseconds: 500);

  /// A nod: down and back.
  static const Duration nod = Duration(milliseconds: 600);

  /// The gap between staggered entrances, and their cap.
  static const Duration stagger = Duration(milliseconds: 60);
  static const Duration staggerCap = Duration(milliseconds: 400);

  /// The score dial's sweep and its count-up.
  static const Duration countUp = Duration(milliseconds: 1200);

  /// The weekly ring closing.
  static const Duration ringClose = Duration(milliseconds: 800);

  /// A blink.
  static const Duration blink = Duration(milliseconds: 120);

  /// A screen arriving or leaving (shared axis, fade-through), and its reverse on back.
  static const Duration page = Duration(milliseconds: 300);

  /// Through the door: a room growing out of its door on the tower, and back into it. The
  /// signature, so a little longer than a page, never past 450 ms.
  static const Duration door = Duration(milliseconds: 450);

  /// A screen whose own entrance is the show (the Candidate assessment): only its ground
  /// fades in, so the sheet's timeline plays untouched.
  static const Duration ground = Duration(milliseconds: 200);

  /// Every route under reduced motion: a cross-fade, nothing moves.
  static const Duration reducedPage = Duration(milliseconds: 150);

  /// A back or close icon nudging toward where it goes, before the screen leaves.
  static const Duration nudge = blink;

  /// A sheet settling: it rises a touch past its rest and comes back (about 3% of the way).
  static const Cubic settle = Cubic(0.3, 1.18, 0.55, 1);

  /// A door swinging: slow off its frame, quick through the middle, easing wide open. The
  /// same both ways, so a room closing back into its door is the opening run backwards.
  static const Cubic swing = Cubic(0.65, 0, 0.35, 1);
}

/// The only two shadows. Both lit from above and tinted toward the ground.
abstract final class DaylightElevation {
  /// A pressable element's hard edge (`0 4px 0 sand-2`).
  static const List<BoxShadow> edge = [
    BoxShadow(
      color: DaylightColors.sand2,
      offset: Offset(0, DaylightSize.edge),
    ),
  ];

  /// The edge in another colour: a honey button's, a floor's deep, a selected card's.
  static List<BoxShadow> edgeOf(
    Color color, {
    double depth = DaylightSize.edge,
  }) => [BoxShadow(color: color, offset: Offset(0, depth))];

  /// Bubbles, sheets, the tab bar (`0 8px 24px rgb(94 72 40 / 0.12)`).
  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0x1F5E4828), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// The grain over a flat ground: texture, never a gradient.
  static const double grain = 0.05;
}
