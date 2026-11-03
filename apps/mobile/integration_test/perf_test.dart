import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/notifications/reminder_primer.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/scene/mission_card.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/mission/widgets/next_control.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/recall/recall_card_view.dart';
import 'package:the_last_room/features/recall/recall_screen.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/tower/tower_door.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/ui/daylight/pick_card.dart';
import 'package:the_last_room/ui/paper/dossier.dart';

import '../test/core/notifications/reminder_fakes.dart'
    show MemoryReminderStore;
import '../test/features/mission/mission_harness.dart';
import '../test/features/recall/recall_fixtures.dart';

/// NFR-3 (60 fps on a mid-range Android): frame timing over the game's heavy paths, on the
/// device's own screen, with the player's real flow and fakes only for storage, sound and
/// analytics (nothing of the device's is read or written but the perf app's own prefs).
///
/// Each path is measured from the engine's [FrameTiming]s (build and raster per frame, the
/// same numbers `watchPerformance` summarises) and, off the web, traced with `traceAction` for
/// the driver's timeline summaries. `reportData['summary']` holds the per-path numbers;
/// `test_driver/perf_driver.dart` writes everything to `build/perf/`.
///
/// Run it on a device only through the command in docs/status/56.md: a profile build, which
/// is its own app (com.thelastroom.app.perf), never the player's.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // NFR-3's budget at 60 Hz, for the summariser's "missed" counts (it defaults to 16 ms).
  kBuildBudget = _budget;
  final summary = <String, Object>{};

  /// Measures [action] as [name]: the frames it drew, summarised, into [summary].
  Future<void> measure(String name, Future<void> Function() action) async {
    final timings = <FrameTiming>[];
    // The engine hands timings over in batches, about once a second: let the last batch
    // before this path go by, then collect, then wait for this path's last batch.
    await Future<void>.delayed(_flush);
    void collect(List<FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(collect);
    if (kIsWeb) {
      await action();
    } else {
      await binding.traceAction(action, reportKey: '${name}_timeline');
    }
    await Future<void>.delayed(_flush);
    SchedulerBinding.instance.removeTimingsCallback(collect);
    final stats = _stats(timings);
    summary[name] = stats;
    binding.reportData = {...?binding.reportData, 'summary': summary};
    debugPrint('perf $name: $stats');
  }

  setUp(
    () => binding.framePolicy =
        LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );

  testWidgets('the title, first launch', (tester) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await measure('title', () async {
      await rig.boot(Routes.home, size: null);
      await rig.until(find.byType(TitleScreen));
      await rig.run(_titleRuns);
    });
  });

  testWidgets('a session: tower, a room, the debrief, Your file, Recall', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    rig.overrides.add(
      reminderSettingsStoreProvider.overrideWithValue(MemoryReminderStore()),
    );
    await rig.unlockThrough(5);
    // A mistake for the Recall Room to bring back.
    final (weak, _) = weakOf(m1.beats[0]);
    await rig.progress.recordAttempt(
      m1Attempt([
        weak,
        strongestOf(m1.beats[1]),
        strongestOf(m1.beats[2]),
      ], number: 2),
    );
    await rig.boot(Routes.tower(), size: null);
    await rig.until(find.byType(TowerScreen));
    await rig.run(_settle);
    if (find.text(ReminderPrimer.notNow).evaluate().isNotEmpty) {
      await tester.tap(find.text(ReminderPrimer.notNow));
      await rig.run(_settle);
    }

    final tower = find
        .descendant(
          of: find.byType(TowerScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await measure('tower_scroll', () async {
      for (final dy in [-_fling, _fling, -_fling, _fling]) {
        await tester.fling(tower, Offset(0, dy), _flingSpeed);
        await rig.run(_settle);
      }
    });

    await tester.ensureVisible(find.byType(PlayCue));
    await rig.run(_settle);
    await measure('door_to_room', () async {
      await tester.tap(find.byType(PlayCue));
      await rig.until(find.byType(MissionPlayer));
      await rig.run(_settle);
    });

    final mission = rig.state(5).mission;
    await measure('mission_beat', () async {
      // The title card, then every line typing out at its own pace, Next after each.
      // (The card may have moved on by itself while the last path's timings flushed.)
      if (find.byType(MissionCard).evaluate().isNotEmpty) await rig.tapScene();
      final lines = rig.state(5).scene.length;
      for (var i = 0; i < lines; i++) {
        await rig.until(find.byType(NextControl));
        await rig.tapNext();
      }
      await rig.until(find.byType(ChoiceCard));
      await rig.pick(strongest(mission.beats[0]));
    });

    await measure('why_step', () async {
      await rig.until(find.text(reasonLabel));
      await rig.pick(soundFor(mission.beats[0]));
      // Her reaction, then the next beat's cards arriving.
      await rig.until(find.text(beatLabel(mission.beats[1].kind, 1, 3)));
      await rig.run(_settle);
    });

    for (final beat in mission.beats.skip(1)) {
      await rig.until(find.text(beatLabel(beat.kind, beat.index(mission), 3)));
      await rig.say(strongest(beat));
    }
    await rig.until(find.text(rig.state(5).followUpLine!.text));
    await rig.until(find.text(replyLabel));

    await measure('debrief', () async {
      await rig.say(rig.state(5).replyOptions.first);
      await rig.until(find.byType(Dossier));
      // The Candidate assessment's whole timeline: slide, stamps, seal, the pen.
      await rig.run(BrandMotion.dossier + BrandMotion.pen + _settle);
    });

    rig.container.read(routerProvider).go(Routes.progress);
    await rig.until(find.byType(ProgressScreen));
    await rig.run(_settle);
    await measure('your_file_scroll', () async {
      final file = find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final dy in [-_fling, -_fling, _fling, _fling]) {
        await tester.fling(file, Offset(0, dy), _flingSpeed);
        await rig.run(_settle);
      }
    });

    await measure('recall_room', () async {
      rig.container.read(routerProvider).go(Routes.recall);
      await rig.until(find.byType(RecallScreen));
      await rig.until(find.byType(RecallCardView));
      await rig.run(_settle);
      final pick = find.descendant(
        of: find.byType(RecallCardView),
        matching: find.byType(PickCard),
      );
      if (pick.evaluate().isNotEmpty) {
        await tester.ensureVisible(pick.first);
        await tester.tap(pick.first);
        await rig.run(_settle);
      }
    });
  });
}

/// One frame at 60 Hz: NFR-3's budget.
const Duration _budget = Duration(microseconds: 16667);

/// Longer than the engine's batching of frame timings (about a second).
const Duration _flush = Duration(milliseconds: 1500);
const Duration _settle = Duration(milliseconds: 1200);
const Duration _titleRuns = Duration(seconds: 5);
const double _fling = 600;
const double _flingSpeed = 2000;

AnswerOption strongest(Beat beat) =>
    beat.options.firstWhere((o) => beat.isStrongest(o.id));

Reason soundFor(Beat beat) =>
    beat.why!.reasons.firstWhere((r) => r.isSoundFor(strongest(beat).id));

extension on Beat {
  int index(Mission mission) => mission.beats.indexOf(this);
}

/// Average, 90th and 99th percentile build and raster times (ms), and the frames over the
/// 16.6 ms budget: on the UI thread, on the raster thread, and either (a dropped frame).
Map<String, Object> _stats(List<FrameTiming> timings) {
  if (timings.isEmpty) return {'frames': 0};
  double ms(Duration d) =>
      d.inMicroseconds / Duration.microsecondsPerMillisecond;
  List<double> sorted(Iterable<Duration> ds) =>
      [for (final d in ds) ms(d)]..sort();
  double at(List<double> xs, double p) =>
      xs[((xs.length - 1) * p).round().clamp(0, xs.length - 1)];
  double avg(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
  double round(double x) => (x * 100).roundToDouble() / 100;
  final build = sorted(timings.map((t) => t.buildDuration));
  final raster = sorted(timings.map((t) => t.rasterDuration));
  final budget = ms(_budget);
  return {
    'frames': timings.length,
    'build_avg_ms': round(avg(build)),
    'build_p90_ms': round(at(build, 0.9)),
    'build_p99_ms': round(at(build, 0.99)),
    'build_worst_ms': round(build.last),
    'raster_avg_ms': round(avg(raster)),
    'raster_p90_ms': round(at(raster, 0.9)),
    'raster_p99_ms': round(at(raster, 0.99)),
    'raster_worst_ms': round(raster.last),
    'missed_build': build.where((x) => x > budget).length,
    'missed_raster': raster.where((x) => x > budget).length,
    // A frame is dropped when either thread runs over (they work in a pipeline).
    'missed_frames': timings
        .where(
          (t) => ms(t.buildDuration) > budget || ms(t.rasterDuration) > budget,
        )
        .length,
  };
}
