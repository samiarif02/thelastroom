import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// The device's database (ADR 0002): the player's progress lives here first and reaches the
/// server through the outbox when it can. Works offline and with no backend at all.
///
/// The tables are plain SQL ([schema]) run by drift's migration strategy, and the repositories
/// query them through drift's executor: no generated code, so a fresh clone needs no
/// `build_runner` step.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  /// The database on this device: a file on Android and iOS, OPFS or IndexedDB in the browser
  /// (through the WASM build and worker committed under `web/`).
  factory AppDatabase.onDevice() => AppDatabase(
    driftDatabase(
      name: fileName,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  static const String fileName = 'the_last_room';

  /// Version 1. A later version adds an `onUpgrade` step ([upgrades]); never edit these
  /// statements once shipped (the same rule as the server's migrations).
  static const List<String> schema = [
    // One row per finished attempt. Append-only, like `mission_attempts`; the draft never
    // leaves the device. The score isn't stored: the engine recomputes it from the picks.
    '''
    create table attempts (
      attempt_id text primary key not null,
      mission_id text not null,
      attempt_number integer not null,
      seed integer not null,
      beat_option_ids text not null,
      follow_up_id text not null,
      reply_option_id text not null,
      hinted integer not null,
      draft text,
      completed_at integer not null,
      content_schema_version integer not null
    )''',
    'create index attempts_completed on attempts (completed_at)',
    // The one profile (id is always 1).
    '''
    create table profile (
      id integer primary key not null check (id = 1),
      first_name text,
      experience text,
      target_role text,
      nerves_level integer,
      calm_mode integer not null default 0,
      weekly_goal integer,
      auto_advance integer not null default 1,
      onboarded integer not null default 0,
      chapter_2_waitlist_at integer
    )''',
    // What still has to reach the server. One row per attempt, one for the profile (its latest
    // state is what's sent, so one row is enough).
    '''
    create table outbox (
      id integer primary key autoincrement,
      kind text not null,
      ref text not null,
      tries integer not null default 0,
      next_try_at integer not null default 0,
      unique (kind, ref)
    )''',
    // Small facts about this device's database, e.g. that the one-time restore has run.
    '''
    create table meta (
      key text primary key not null,
      value text not null
    )''',
  ];

  /// The steps from each version to the next: `upgrades[0]` takes version 1 to 2. A new
  /// install runs [schema] and then every step, so both paths end at the same tables.
  static const List<List<String>> upgrades = [
    // 2 (brief 30): how each beat was played (the reason given, the time taken), so a stored
    // attempt rescores exactly as the debrief scored it. JSON, like beat_option_ids; null on
    // rows from version 1, which rescore at full credit as they always did.
    ['alter table attempts add column beat_plays text'],
    // 3 (brief 35): a voice mission's answer, as JSON ({made, source, seconds}): the points the
    // spoken answer made and who judged them. Null on a built answer. A voice row has no picks
    // (beat_option_ids '[]', follow_up_id and reply_option_id ''); never any audio or words.
    ['alter table attempts add column voice text'],
  ];

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1 + upgrades.length;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final statement in [...schema, ...upgrades.expand((u) => u)]) {
        await customStatement(statement);
      }
    },
    onUpgrade: (m, from, to) async {
      for (var version = from; version < to; version++) {
        for (final statement in upgrades[version - 1]) {
          await customStatement(statement);
        }
      }
    },
  );

  /// "Sign out" (FR-3): forgets the player on this device: every attempt, the profile, the
  /// outbox and the meta flags (the restore and merge markers), so the next guest starts on an
  /// empty database. The schema stays.
  Future<void> clearPlayerData() => transaction(() async {
    for (final table in playerTables) {
      await customStatement('delete from $table');
    }
  });

  /// The tables [clearPlayerData] empties: all of them.
  static const List<String> playerTables = [
    'attempts',
    'profile',
    'outbox',
    'meta',
  ];

  /// A value from [meta], or null.
  Future<String?> metaValue(String key) async {
    final row = await customSelect(
      'select value from meta where key = ?',
      variables: [Variable.withString(key)],
    ).getSingleOrNull();
    return row?.read<String>('value');
  }

  Future<void> setMeta(String key, String value) => customStatement(
    'insert into meta (key, value) values (?, ?) '
    'on conflict (key) do update set value = excluded.value',
    [key, value],
  );
}
