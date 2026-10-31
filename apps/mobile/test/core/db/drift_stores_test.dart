import 'dart:io';
import 'dart:math' as math;

import 'package:content/content.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/db/ids.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/profile/drift_profile_repository.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/drift_progress_repository.dart';
import 'package:the_last_room/core/sync/outbox.dart';

import '../../features/tower/played_attempt.dart';
import 'db_support.dart';

void main() {
  final log = Log(sink: (_) {});

  group('progress', () {
    late AppDatabase db;
    late DriftProgressRepository repo;
    setUp(() {
      db = memoryDb();
      repo = DriftProgressRepository(
        db,
        log: log,
        clock: () => DateTime.utc(2026, 10, 31, 9),
        random: math.Random(1),
      );
    });
    tearDown(() => db.close());

    test(
      'recording an attempt writes it and its outbox row together',
      () async {
        await repo.recordAttempt(playedAttempt(missions[0]));
        expect(await rows(db, 'attempts'), 1);
        expect(await rows(db, 'outbox'), 1);
        final due = await Outbox(db).due(DateTime.utc(2026, 10, 31, 9));
        final stored = (await repo.attempts()).single;
        expect(due.single.kind, OutboxKind.attempt);
        expect(due.single.ref, stored.attemptId);
      },
    );

    test(
      'a failed write leaves neither the attempt nor its outbox row',
      () async {
        await db.customStatement('drop table outbox');
        await expectLater(
          repo.recordAttempt(playedAttempt(missions[0])),
          throwsA(anything),
        );
        expect(await rows(db, 'attempts'), 0);
      },
    );

    test('the score read back is the engine\'s, from the picks', () async {
      final played = playedAttempt(missions[0], pick: 2);
      await repo.recordAttempt(played);
      final back = (await repo.attempts()).single;
      expect(back.score, played.score);
      expect(back.beatOptionIds, played.beatOptionIds);
      expect(back.completedAt, DateTime.utc(2026, 10, 31, 9));
    });

    test('order, filter and baseline match the in-memory store', () async {
      await repo.recordAttempt(playedAttempt(missions[1]));
      await repo.recordAttempt(playedAttempt(missions[0]));
      await repo.recordAttempt(playedAttempt(missions[0], attempt: 2));
      expect((await repo.attempts()).map((a) => a.missionId), [
        missions[1].id,
        missions[0].id,
        missions[0].id,
      ]);
      expect(await repo.attempts(missionId: missions[0].id), hasLength(2));
      expect((await repo.baseline())!.attemptNumber, 1);
    });

    test('a row that no longer matches the content is skipped, not mis-scored', () async {
      await repo.recordAttempt(playedAttempt(missions[0]));
      await db.customStatement(
        "update attempts set beat_option_ids = '[\"gone\",\"gone\",\"gone\"]'",
      );
      expect(await repo.attempts(), isEmpty);
    });

    test(
      'progress survives closing and reopening the database (a restart)',
      () async {
        final dir = await Directory.systemTemp.createTemp('tlr');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/db.sqlite');
        final first = AppDatabase(NativeDatabase(file));
        await DriftProgressRepository(
          first,
          log: log,
        ).recordAttempt(playedAttempt(missions[0]));
        await DriftProfileRepository(first)
            .save(const PlayerProfile(firstName: 'Sami', onboarded: true));
        await first.close();

        final second = AppDatabase(NativeDatabase(file));
        addTearDown(second.close);
        final again = await DriftProgressRepository(
          second,
          log: log,
        ).attempts();
        expect(again.single.missionId, missions[0].id);
        final profile = await DriftProfileRepository(second).load();
        expect(profile.onboarded, isTrue);
        expect(profile.firstName, 'Sami');
      },
    );
  });

  group('profile', () {
    late AppDatabase db;
    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    test('a fresh database reads a fresh profile', () async {
      final p = await DriftProfileRepository(db).load();
      expect(p.onboarded, isFalse);
      expect(await rows(db, 'outbox'), 0);
    });

    test(
      'every field round-trips, and each save queues one profile row',
      () async {
        final repo = DriftProfileRepository(db);
        final saved = PlayerProfile(
          firstName: 'Sami',
          experience: Experience.freshGraduate,
          targetRole: TargetRole.product,
          nervesLevel: 4,
          calmMode: true,
          weeklyGoal: 3,
          autoAdvance: false,
          onboarded: true,
          waitlistJoinedAt: DateTime.utc(2026, 10, 31),
        );
        await repo.save(saved);
        await repo.save(saved);
        final p = await repo.load();
        expect(p.firstName, 'Sami');
        expect(p.experience, Experience.freshGraduate);
        expect(p.targetRole, TargetRole.product);
        expect(p.nervesLevel, 4);
        expect(p.calmMode, isTrue);
        expect(p.weeklyGoal, 3);
        expect(p.autoAdvance, isFalse);
        expect(p.onboarded, isTrue);
        expect(p.waitlistJoinedAt, DateTime.utc(2026, 10, 31));
        expect(await rows(db, 'outbox'), 1);
      },
    );

    test(
      'a profile from the old shared_preferences store is carried over once',
      () async {
        final legacy = InMemoryProfileRepository(
          const PlayerProfile(firstName: 'Sami', onboarded: true),
        );
        final repo = DriftProfileRepository(db, legacy: legacy);
        expect((await repo.load()).firstName, 'Sami');
        await legacy.save(const PlayerProfile(firstName: 'Other'));
        expect((await repo.load()).firstName, 'Sami', reason: 'read only once');
        expect(
          await rows(db, 'outbox'),
          1,
          reason: 'and queued for the server',
        );
      },
    );
  });

  test('attempt ids are version-4 UUIDs and never repeat', () {
    final random = math.Random.secure();
    final ids = {for (var i = 0; i < 1000; i++) newUuid(random)};
    expect(ids, hasLength(1000));
    final shape = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(ids.every(shape.hasMatch), isTrue);
  });

  test('backoff doubles from 5 s and stops at 30 min', () {
    expect(Outbox.backoff(1), const Duration(seconds: 5));
    expect(Outbox.backoff(2), const Duration(seconds: 10));
    expect(Outbox.backoff(5), const Duration(seconds: 80));
    expect(Outbox.backoff(40), Outbox.maxBackoff);
  });
}
