import 'dart:io';
import 'dart:ui' as ui;

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/features/debrief/promise_card.dart';
import 'package:the_last_room/features/progression/first_day.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/recall/recall_store.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/features/tower/welcome_back.dart';
import 'package:the_last_room/ui/paper/dossier.dart';

import '../../../core/notifications/reminder_fakes.dart'
    show MemoryReminderStore;
import '../../mission/mission_harness.dart';
import '../../tower/played_attempt.dart';

/// Brief 61's moments with real type at a 390 × 844 phone, and at 2x text: the debrief's dated
/// promise (a trap, and a clean room), the first-day moment, and a day-3 welcome back. Each
/// must draw without an exception; with `WRITE_STILLS=1` each is saved as a PNG at 2x in
/// `.pr-screenshots/61/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const phone = Size(390, 844);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> still(WidgetTester tester, String name) async {
    await tester.pump();
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & (phone * dpr),
        pixelRatio: pixelRatio / dpr,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/61/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  MissionRig rig(WidgetTester tester) => MissionRig(tester)
    ..overrides.add(
      reminderSettingsStoreProvider.overrideWithValue(
        MemoryReminderStore(const ReminderSettings(offered: true)),
      ),
    );

  for (final scale in [1.0, 2.0]) {
    final x = scale == 1 ? '' : '-2x';
    for (final trap in [true, false]) {
      testWidgets(
        'the debrief promise: ${trap ? 'a trap' : 'a clean room'}$x',
        (tester) async {
          final r = rig(tester);
          await r.boot(Routes.mission(1), size: phone, textScale: scale);
          final m = missions[0];
          await r.playLines(1);
          await r.skipDraft();
          for (final b in m.beats) {
            await r.say(b.options.firstWhere((o) => b.isStrongest(o.id)));
          }
          await r.until(find.text(r.state(1).followUpLine!.text));
          await r.run(const Duration(milliseconds: 300));
          if (r.typing) await r.tapScene();
          // A trap from the follow-up: its weak reply's lesson becomes a Recall note.
          final replies = r.state(1).replyOptions;
          await r.say(
            replies.firstWhere(
              (o) => trap ? o.lessonId != null : o.lessonId == null,
            ),
          );
          await r.until(find.byType(Dossier));
          await r.settleDossier();
          final card = find.byType(PromiseCardView);
          await r.until(card);
          await tester.ensureVisible(card);
          await r.run(const Duration(seconds: 1));
          await still(tester, 'promise-${trap ? 'recall' : 'next-room'}$x');
        },
      );
    }

    testWidgets('the first-day moment$x', (tester) async {
      final r = rig(tester);
      r.firstDay.isShown = false;
      await r.progress.recordAttempt(playedAttempt(missions[0], pick: 1));
      await r.boot(Routes.tower(lit: 1), size: phone, textScale: scale);
      await r.until(find.text(FirstDay.title));
      await r.run(const Duration(seconds: 2));
      await still(tester, 'first-day$x');
    });

    testWidgets('a day-3 welcome back: the next note, the countdown$x', (
      tester,
    ) async {
      final r = rig(tester);
      final now = DateTime.now();
      final today = CalendarDay(now.year, now.month, now.day);
      final attempts = [playedAttempt(missions[0]), playedAttempt(missions[1])];
      for (final a in attempts) {
        await r.progress.recordAttempt(a);
      }
      // The trap from room 1, known in the Recall Room: box three, back in two days.
      r.recall.schedule = RecallSchedule(
        cards: [
          RecallCard(
            cardId: missions[0].beats.first.why!.reasons
                .firstWhere((x) => x.tempts.isNotEmpty)
                .id,
            box: LeitnerBox.three,
            due: today.addDays(2),
          ),
        ],
        ingested: {
          for (final a in attempts)
            attemptKey(a.missionId, a.attemptNumber, a.attemptId),
        },
      );
      r.overrides.addAll([
        lastVisitStoreProvider.overrideWithValue(
          _Visits(now.subtract(const Duration(days: 2))),
        ),
        progressionStoreProvider.overrideWithValue(
          InMemoryProgressionStore(
            ProgressionRecord.empty.copyWith(
              interviewDate: () => today.addDays(9),
            ),
          ),
        ),
      ]);
      await r.boot(Routes.tower(), size: phone, textScale: scale);
      await r.until(find.byType(TowerScreen));
      await r.until(find.textContaining('Welcome back'));
      await r.run(const Duration(seconds: 2));
      expect(find.text(WelcomeBack.interviewLine(9)), findsOneWidget);
      await still(tester, 'welcome-back-day3$x');
    });
  }
}

class _Visits implements LastVisitStore {
  _Visits(this.at);

  DateTime? at;

  @override
  Future<DateTime?> load() async => at;

  @override
  Future<void> save(DateTime when) async => at = when;
}
