import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/core/audio/audio_settings.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/profile/drift_profile_repository.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/drift_progress_repository.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/core/sync/sync_worker.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/recall/recall_store.dart';
import 'package:the_last_room/features/settings/account/player_data.dart';
import 'package:the_last_room/features/tips/tips.dart';

import '../../core/backend/fakes.dart';
import '../../core/db/db_support.dart';
import '../tower/played_attempt.dart';

/// "Sign out" (FR-3) underneath the card: the backup that decides whether the device may go,
/// and what it forgets when it does (and what it keeps).
void main() {
  late AppDatabase db;
  late FakeBackend server;
  late CapturedLog log;
  late OutboxSignal signal;
  late DriftProgressRepository progress;

  setUp(() {
    db = memoryDb();
    server = FakeBackend();
    log = CapturedLog();
    signal = OutboxSignal();
    progress = DriftProgressRepository(db, log: log.log, signal: signal);
  });
  tearDown(() async {
    await signal.close();
    await db.close();
  });

  SyncWorker worker() =>
      SyncWorker(db: db, backend: server, log: log.log, signal: signal);

  test(
    'the backup sends everything, retry waits ignored, and nothing is left',
    () async {
      await progress.recordAttempt(playedAttempt(missions[0]));
      await progress.recordAttempt(playedAttempt(missions[1]));
      // An earlier send failed, so the rows wait out a backoff.
      await Outbox(db)
          .failed(await Outbox(db).due(DateTime.now()), DateTime.now());
      expect(await Outbox(db).due(DateTime.now()), isEmpty);
      final w = worker();
      final left = await w.flushEverything();
      await w.dispose();
      expect(left, (rooms: 0, other: 0));
      expect(server.attempts, hasLength(2));
    },
  );

  test('offline, the backup reports the rooms still waiting', () async {
    await progress.recordAttempt(playedAttempt(missions[0]));
    await progress.recordAttempt(playedAttempt(missions[1]));
    await progress.recordAttempt(playedAttempt(missions[2]));
    await DriftProfileRepository(
      db,
      signal: signal,
    ).save(const PlayerProfile(firstName: 'Sami', onboarded: true));
    server.online = false;
    final w = worker();
    final left = await w.flushEverything();
    await w.dispose();
    expect(left, (rooms: 3, other: 1));
    expect(server.attempts, isEmpty);
  });

  test('clearing forgets the player and keeps the device settings', () async {
    await progress.recordAttempt(playedAttempt(missions[0]));
    await DriftProfileRepository(
      db,
      signal: signal,
    ).save(const PlayerProfile(firstName: 'Sami', onboarded: true));
    await db.setMeta(SyncWorker.restoredKey, 'done');
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRecallStore.key: '{}',
      SharedPreferencesTipStore.keyOf(Tip.values.first): true,
      SharedPreferencesTipStore.legacyTour: true,
      SharedPreferencesAudioSettingsStore.enabledKey: false,
      SharedPreferencesAudioSettingsStore.effectsKey: 0.4,
      SharedPreferencesReminderSettingsStore.enabledKey: true,
      SharedPreferencesReminderSettingsStore.offeredKey: true,
      'sb-project-auth-token': 'kept',
    });
    final device = _FakePrefs()
      ..values.addAll({
        LocalAiScoreStore.key: '{}',
        '${LocalResumeStore.prefix}m01': '{}',
        '${LocalProfileRepository.prefix}first_name': 'Sami',
        'something.else': 'kept',
      });

    await PlayerData.clear(db, prefs: device);

    for (final table in AppDatabase.playerTables) {
      expect(await rows(db, table), 0, reason: table);
    }
    final legacy = await SharedPreferences.getInstance();
    expect(legacy.getKeys(), {
      SharedPreferencesAudioSettingsStore.enabledKey,
      SharedPreferencesAudioSettingsStore.effectsKey,
      SharedPreferencesReminderSettingsStore.enabledKey,
      SharedPreferencesReminderSettingsStore.offeredKey,
      'sb-project-auth-token',
    });
    expect(device.values.keys, ['something.else']);
    // The next guest's profile is a new player's: onboarding again.
    expect((await DriftProfileRepository(db).load()).onboarded, isFalse);
  });
}

/// `SharedPreferencesAsync` in memory, with the two calls the clear makes.
class _FakePrefs implements SharedPreferencesAsync {
  final Map<String, Object> values = {};

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async =>
      values.keys.toSet();

  @override
  Future<void> clear({Set<String>? allowList}) async {
    if (allowList == null) {
      values.clear();
    } else {
      values.removeWhere((key, _) => allowList.contains(key));
    }
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
