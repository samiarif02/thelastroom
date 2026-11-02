/// The Last Room's game engine: pure Dart, deterministic, no I/O and no clock reads.
///
/// The app passes everything in (picks, today's date) and gets plain values back, so every
/// score can be reproduced offline from the stored inputs.
library;

export 'src/baseline.dart';
export 'src/beat.dart';
export 'src/build.dart';
export 'src/calendar_day.dart';
export 'src/dimension.dart';
export 'src/dimension_scores.dart';
export 'src/flag.dart';
export 'src/follow_up.dart';
export 'src/line_cost.dart';
export 'src/pick_credit.dart';
export 'src/progression.dart';
export 'src/recall.dart';
export 'src/scoring.dart';
export 'src/shuffle.dart';
export 'src/skill.dart';
