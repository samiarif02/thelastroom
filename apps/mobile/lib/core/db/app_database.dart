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

  /// Version 1. A later version adds an `onUpgrade` step; never edit these statements once
  /// shipped (the same rule as the server's migrations).
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

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final statement in schema) {
        await customStatement(statement);
      }
    },
  );

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
