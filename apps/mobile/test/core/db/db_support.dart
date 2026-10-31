import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:the_last_room/core/db/app_database.dart';

/// A database in memory, as a fresh install.
AppDatabase memoryDb() {
  // Each test opens its own in-memory database, each on its own executor, so drift's
  // "created more than once" debug warning doesn't apply here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

Future<int> rows(AppDatabase db, String table) async =>
    (await db.customSelect('select count(*) as n from $table').getSingle())
        .read<int>('n');
