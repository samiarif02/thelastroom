import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/leaderboard/leaderboard_report.dart';
import 'package:the_last_room/core/profile/drift_profile_repository.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/sync/account_merge.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/core/sync/sync_worker.dart';

import '../backend/fakes.dart';
import '../db/db_support.dart';

/// Issue 72: the leaderboard's numbers ride the outbox like the profile, on their own row.
void main() {
  late AppDatabase db;
  late FakeBackend server;
  late CapturedLog log;
  late OutboxSignal signal;
  late DateTime now;

  SyncWorker worker() => SyncWorker(
    db: db,
    backend: server,
    log: log.log,
    signal: signal,
    clock: () => now,
  );

  final report = LeaderboardReport(
    totalXp: 940,
    weekXp: 120,
    weekStart: CalendarDay(2026, 11, 2),
    streakWeeks: 2,
  );

  setUp(() {
    db = memoryDb();
    server = FakeBackend();
    log = CapturedLog();
    signal = OutboxSignal();
    now = DateTime.utc(2026, 11, 4, 9);
  });
  tearDown(() async {
    await signal.close();
    await db.close();
  });

  test('a saved report reaches the server, then leaves the outbox', () async {
    await DriftLeaderboardReportStore(db, signal: signal).save(report);
    expect(await rows(db, 'outbox'), 1);
    final w = worker();
    await w.flush();
    await w.dispose();
    expect(server.leaderboardReport?.toRow(), {
      'leaderboard_visible': true,
      'total_xp': 940,
      'week_xp': 120,
      'week_start': '2026-11-02',
      'streak_weeks': 2,
    });
    expect(await rows(db, 'outbox'), 0);
    expect(server.profileUpserts, 0, reason: 'the profile row is its own');
  });

  test('offline it waits, and sign-out never waits for it', () async {
    server.online = false;
    await DriftLeaderboardReportStore(db, signal: signal).save(report);
    final w = worker();
    await w.flush();
    expect(await rows(db, 'outbox'), 1);
    expect(await Outbox(db).pending(), (rooms: 0, other: 0));
    server.online = true;
    now = now.add(Outbox.maxBackoff);
    await w.flush();
    await w.dispose();
    expect(server.leaderboardReport?.totalXp, 940);
  });

  test('saving twice is one row: the latest numbers are sent', () async {
    final store = DriftLeaderboardReportStore(db, signal: signal);
    await store.save(report);
    await store.save(report.copyWith(totalXp: 1000));
    expect(await rows(db, 'outbox'), 1);
    final w = worker();
    await w.flush();
    await w.dispose();
    expect(server.leaderboardUpserts, 1);
    expect(server.leaderboardReport?.totalXp, 1000);
  });

  test('a fresh install restores "Show me on the leaderboard" off', () async {
    server.profile = RemoteProfile.fromRow(const {
      'first_name': 'Sami',
      'onboarded': true,
      'leaderboard_visible': false,
    });
    final w = worker();
    await w.start();
    await w.dispose();
    expect((await DriftLeaderboardReportStore.read(db))?.visible, isFalse);
  });

  test(
    'a sign-in carries the account\'s visibility, and re-sends the numbers',
    () async {
      await DriftProfileRepository.write(
        db,
        const PlayerProfile(onboarded: true),
      );
      await DriftLeaderboardReportStore.write(db, report);
      await prepareAccountMerge(db);
      server.profile = RemoteProfile.fromRow(const {
        'onboarded': true,
        'leaderboard_visible': false,
      });
      await pullAccountMerge(db, server);
      final stored = await DriftLeaderboardReportStore.read(db);
      expect(stored?.visible, isFalse);
      expect(stored?.totalXp, 940);
      final queued = await Outbox(db).due(now);
      expect(queued.map((e) => e.kind), contains(OutboxKind.leaderboard));
    },
  );

  test('a report that was never saved sends nothing', () async {
    final w = worker();
    await Outbox(db).add(OutboxKind.leaderboard, Outbox.leaderboardRef);
    await w.flush();
    await w.dispose();
    expect(server.leaderboardUpserts, 0);
  });

  test('a report reads back the same, and junk reads as the default', () {
    expect(LeaderboardReport.fromJson(report.toJson()), report);
    expect(LeaderboardReport.fromJson('x'), LeaderboardReport.initial);
  });
}
