import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// One of the three prototype art directions compared in brief 03. A direction is more than a
/// font pair: it carries its own palette, chapter grades, type ramp and motion vocabulary.
///
/// PROTOTYPE: these live beside the real tokens ([BrandColors], [BrandType]) and never replace
/// them. Brief 06 promotes the winner into the real tokens and deletes the rest.
class CinematicDirection {
  const CinematicDirection({
    required this.id,
    required this.letter,
    required this.name,
    required this.mood,
    required this.references,
    required this.palette,
    required this.type,
    required this.grades,
    required this.motion,
  });

  /// URL-safe id, used in `/dev/directions/<id>`.
  final String id;

  /// A, B or C, as the brief names them.
  final String letter;

  final String name;

  /// The mood in one line.
  final String mood;

  /// The films and title sequences it borrows from.
  final String references;

  final DirectionPalette palette;
  final DirectionType type;

  /// Chapter 1 (warm amber lobby), 2 (cold steel blue), 3 (oxblood and gold), in order.
  final List<DirectionGrade> grades;

  final DirectionMotion motion;

  /// The Chapter 1 grade, which every Mission 1 frame uses.
  DirectionGrade get lobby => grades.first;
}

/// A direction's colours. Text pairs are contrast-tested in `test/contrast_test.dart`.
class DirectionPalette {
  const DirectionPalette({
    required this.void_,
    required this.surface,
    required this.raised,
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.redPen,
  });

  /// Letterbox bars and the deepest shadow.
  final Color void_;

  /// The scene's background.
  final Color surface;

  /// Raised layers: answer cards, the desk.
  final Color raised;

  /// Hairlines.
  final Color line;

  final Color textPrimary;
  final Color textSecondary;

  /// The dossier's sheet.
  final Color paper;

  /// Typed text on the sheet.
  final Color ink;

  /// Field labels on the sheet.
  final Color inkSoft;

  /// The interviewer's note on the sheet.
  final Color redPen;
}

/// How a direction reads one chapter's colour grade.
class DirectionGrade {
  const DirectionGrade({
    required this.name,
    required this.key,
    required this.shadow,
    required this.tint,
  });

  final String name;

  /// The light in the scene. Also legible as text on the direction's surfaces.
  final Color key;

  /// What the vignette falls to.
  final Color shadow;

  /// A second colour laid into the light (haze, bokeh, the oxblood in Chapter 3).
  final Color tint;
}

/// A direction's type ramp. Every style carries its bundled font and its colour.
class DirectionType {
  const DirectionType({
    required this.eyebrow,
    required this.titleCard,
    required this.display,
    required this.body,
    required this.subtitle,
    required this.speaker,
    required this.choice,
    required this.label,
    required this.score,
    required this.stamp,
    required this.note,
  });

  /// "CHAPTER ONE" above the title.
  final TextStyle eyebrow;

  /// The chapter title card.
  final TextStyle titleCard;

  /// Names and headings.
  final TextStyle display;

  final TextStyle body;

  /// The interviewer's line, typewritten.
  final TextStyle subtitle;

  /// The speaker's name, set in small caps (or tracked capitals where the face has none).
  final TextStyle speaker;

  /// Answer card text.
  final TextStyle choice;

  /// Small tracked labels.
  final TextStyle label;

  /// Scores: always tabular figures, so digits don't jitter while they tick.
  final TextStyle score;

  /// The word inside a stamp.
  final TextStyle stamp;

  /// The red-pen note.
  final TextStyle note;
}

/// A direction's motion vocabulary: how its letterbox moves, how its camera cuts, how fast its
/// typewriter types.
class DirectionMotion {
  const DirectionMotion({
    required this.letterbox,
    required this.letterboxCurve,
    required this.cut,
    required this.cutCurve,
    required this.perCharacter,
    required this.titleCard,
    required this.dossierSlide,
    required this.dossierCurve,
  });

  final Duration letterbox;
  final Curve letterboxCurve;

  /// The wide → close-up camera move.
  final Duration cut;
  final Curve cutCurve;

  /// Typewriter speed.
  final Duration perCharacter;

  /// The whole title card sequence.
  final Duration titleCard;

  /// The file sliding onto the desk.
  final Duration dossierSlide;
  final Curve dossierCurve;
}
