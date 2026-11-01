import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progress/progress_repository.dart';
import '../mission/mission_lookup.dart';

/// The Chapter 1 report (brief 24, FR-41): the player's first try (the Mission 1 baseline)
/// against their latest review (the chapter's last mission), skill by skill. Both sides are the
/// engine's scores, recomputable from the stored picks, so the comparison is like for like.
class ChapterReport {
  const ChapterReport({
    required this.chapter,
    required this.review,
    required this.firstTry,
    required this.latest,
  });

  final Chapter chapter;

  /// The mission that closes the chapter (Mission 7, the review).
  final Mission review;
  final MissionScore firstTry;
  final MissionScore latest;

  BaselineComparison get change =>
      compareToBaseline(baseline: firstTry, latest: latest);

  /// How the total moved, in honest words.
  ScoreDeltaBucket get overall => ScoreDeltaBucket.of(change.totalDelta);

  ScoreDeltaBucket skill(Dimension d) =>
      ScoreDeltaBucket.of(change.dimensionDeltas[d]!);
}

/// Words for a change, never stronger than the numbers: a few points either way is "about the
/// same" ([ScoreDeltaBucket.flatBand]).
String changeWords(ScoreDeltaBucket bucket) => switch (bucket) {
  ScoreDeltaBucket.upALot => 'Well up on your first try',
  ScoreDeltaBucket.up => 'Up on your first try',
  ScoreDeltaBucket.flat => 'About the same as your first try',
  ScoreDeltaBucket.down => 'Lower than your first try',
};

/// Whether the report is open yet, and what it shows.
sealed class ChapterReportState {
  const ChapterReportState();
}

/// The review hasn't been played: the report says what opens it.
class ReportNotYet extends ChapterReportState {
  const ReportNotYet(this.review);

  final Mission review;
}

class ReportReady extends ChapterReportState {
  const ReportReady(this.report);

  final ChapterReport report;
}

/// Chapter 1's report from the progress store.
final chapterReportProvider = FutureProvider.autoDispose<ChapterReportState>((
  ref,
) async {
  final store = ref.read(progressRepositoryProvider);
  final catalog = ref.read(missionCatalogProvider);
  const chapterNumber = 1;
  final chapter = chapters.firstWhere((c) => c.number == chapterNumber);
  final review = catalog.lastWhere((m) => m.chapter == chapterNumber);
  final reviews = await store.attempts(missionId: review.id);
  final baseline = await store.baseline();
  if (reviews.isEmpty || baseline == null) return ReportNotYet(review);
  return ReportReady(
    ChapterReport(
      chapter: chapter,
      review: review,
      firstTry: baseline.score,
      latest: reviews.last.score,
    ),
  );
});
