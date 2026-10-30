import 'package:engine/engine.dart';

import 'identified.dart';

/// The three faces every interviewer portrait has (brief §5); the scene picks one as the
/// answer lands.
enum Expression { neutral, pleased, skeptical }

/// One of the fictional Northstar Labs interviewers (brief §5).
class Interviewer implements Identified {
  const Interviewer({
    required this.id,
    required this.name,
    required this.role,
    required this.voice,
    required this.tests,
  });

  @override
  final String id;

  /// Shown in small caps above their subtitles.
  final String name;
  final String role;

  /// One line on how they talk, for writers and the typing-sound voice (brief 09): every line
  /// they say should sound like this one person.
  final String voice;

  /// The dimensions this interviewer mostly probes; their follow-ups lean on these.
  final Set<Dimension> tests;
}
