import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/progress/file_trouble.dart';
import 'package:the_last_room/features/progress/past_result_screen.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/ui/paper/dossier.dart';

import '../mission/mission_harness.dart';
import '../tower/played_attempt.dart';

/// Brief 48: a played room in Your file opens its last result, read back from the device and
/// never scored again; the Candidate assessment is the debrief's own sheet.
void main() {
  Future<void> tapText(MissionRig rig, String text) async {
    final f = find.text(text);
    await rig.until(f);
    await rig.tester.ensureVisible(f);
    await rig.tester.pump();
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  testWidgets('the last try, its sheet, latest against best, what you said', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    final m = missions[0];
    final strong = playedAttempt(m);
    final weak = playedAttempt(m, pick: 2, attempt: 2);
    await rig.progress.recordAttempt(strong);
    await rig.progress.recordAttempt(weak);
    await rig.boot(Routes.result(m.number), size: const Size(411, 914));
    await rig.until(find.byType(Dossier));
    final sheet = tester.widget<Dossier>(find.byType(Dossier));
    expect(sheet.total, weak.score.total);
    expect(find.textContaining('Try 2 of 2.'), findsOneWidget);
    expect(find.text(ProgressScreen.offline), findsOneWidget);
    // A dimension below its best says the best.
    final below = Dimension.values.firstWhere(
      (d) => weak.score.dimensions[d]! < strong.score.dimensions[d]!,
    );
    expect(
      find.text(
        PastResultScreen.latestBest(
          weak.score.dimensions[below]!,
          strong.score.dimensions[below]!,
        ),
      ),
      findsWidgets,
    );
    // The lines chosen, in quotation marks.
    final line = m.beats.first.options[2].text;
    expect(find.text('“$line”'), findsOneWidget);
    // Nothing is scored again: no new attempt, no AI request.
    expect(await rig.progress.attempts(missionId: m.id), hasLength(2));
    await tapText(rig, PastResultScreen.again(m.number));
    await rig.until(find.byType(MissionPlayer));
  });

  testWidgets('a spoken room lists the points made and missed', (tester) async {
    final rig = MissionRig(tester);
    final room = missions.firstWhere((m) => m.answerMode == AnswerMode.voice);
    await rig.unlockThrough(room.number + 1);
    await rig.boot(Routes.result(room.number), size: const Size(411, 914));
    await rig.until(find.byType(Dossier));
    await tapText(rig, PastResultScreen.voiceNote);
    expect(find.text(PastResultScreen.saidVoice), findsOneWidget);
    expect(find.text(room.voice!.listenFor.first.text), findsOneWidget);
  });

  testWidgets('a room not played yet says so, with the way back', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.result(4));
    await rig.until(find.text(PastResultScreen.notPlayedTitle));
    expect(find.text(PastResultScreen.notPlayedLine(missions[3])), findsOne);
    expect(find.byType(Dossier), findsNothing);
    await tapText(rig, PastResultScreen.back);
    await rig.until(find.byType(ProgressScreen));
  });

  testWidgets('a number that isn\'t a room is not a crash', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.result(99));
    await rig.until(find.text(PastResultScreen.unknownLine));
  });

  testWidgets('a store that won\'t read says so, and tries again', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.progress.recordAttempt(playedAttempt(missions[0]));
    rig.progress.failReads = true;
    await rig.boot(Routes.result(1));
    await rig.until(find.text(FileTrouble.title));
    rig.progress.failReads = false;
    await tapText(rig, FileTrouble.retry);
    await rig.until(find.byType(Dossier));
  });

  for (final (scale, still) in [(2.0, false), (2.0, true)]) {
    testWidgets('the result survives ${scale}x text, reduced motion: $still', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.progress.recordAttempt(playedAttempt(missions[0]));
      await rig.boot(Routes.result(1), textScale: scale, reduceMotion: still);
      await rig.until(find.byType(Dossier));
      await rig.run(const Duration(seconds: 6));
    });
  }
}
