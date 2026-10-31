import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progress/progress_repository.dart';
import '../debrief/debrief_facts.dart';

/// One mission's line in the progress file (FR-16, FR-41), read straight off the stored
/// attempts' engine scores: nothing here scores anything.
class MissionProgress {
  const MissionProgress({required this.mission, required this.attempts});

  final Mission mission;

  /// This mission's attempts, oldest first.
  final List<AttemptRecord> attempts;

  bool get played => attempts.isNotEmpty;
  int get attemptCount => attempts.length;

  /// The best total, or null before it's played.
  int? get best => played
      ? attempts.map((a) => a.score.total).reduce((a, b) => a > b ? a : b)
      : null;

  MissionScore? get latest => played ? attempts.last.score : null;

  /// The lesson the latest attempt still has to work on; null on a clean run or before play.
  Lesson? get lessonToWorkOn {
    final latest = this.latest;
    return latest == null ? null : DebriefFacts.of(mission, latest).lesson;
  }
}

/// The Chapter 1 summary at the top of the file, and every mission's line.
class ProgressReport {
  const ProgressReport({required this.missions, required this.sinceBaseline});

  /// Built from [attempts] over the playable [missions].
  factory ProgressReport.of(
    List<Mission> missions,
    List<AttemptRecord> attempts,
    AttemptRecord? baseline,
  ) {
    final lines = [
      for (final m in missions)
        MissionProgress(
          mission: m,
          attempts: [
            for (final a in attempts)
              if (a.missionId == m.id) a,
          ],
        ),
    ];
    final latest = attempts.isEmpty ? null : attempts.last;
    return ProgressReport(
      missions: lines,
      sinceBaseline: baseline == null || latest == null || latest == baseline
          ? null
          : compareToBaseline(baseline: baseline.score, latest: latest.score),
    );
  }

  final List<MissionProgress> missions;

  /// The latest attempt against the Mission 1 baseline (FR-30); null until there's an attempt
  /// after the baseline.
  final BaselineComparison? sinceBaseline;

  int get done => missions.where((m) => m.played).length;
  int get total => missions.length;

  /// The average of the played missions' best totals, rounded; null before any is played.
  int? get average {
    final bests = [for (final m in missions) ?m.best];
    if (bests.isEmpty) return null;
    return (bests.reduce((a, b) => a + b) / bests.length).round();
  }
}

extension ProgressSkills on ProgressReport {
  /// Each dimension averaged over the played missions' latest attempts, 0–100, rounded: the
  /// skill radar (brief 17). Null before any mission is played.
  Map<Dimension, int>? get skills {
    final latest = [for (final m in this.missions) ?m.latest];
    if (latest.isEmpty) return null;
    return {
      for (final d in Dimension.values)
        d:
            (latest.map((s) => s.dimensions[d] ?? 0).reduce((a, b) => a + b) /
                    latest.length)
                .round(),
    };
  }
}

/// The report from the progress store.
final progressReportProvider = FutureProvider.autoDispose<ProgressReport>((
  ref,
) async {
  final store = ref.read(progressRepositoryProvider);
  return ProgressReport.of(
    missions,
    await store.attempts(),
    await store.baseline(),
  );
});
