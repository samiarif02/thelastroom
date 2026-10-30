import 'dart:io';

import 'package:engine/engine.dart';
import 'package:test/test.dart';

/// The engine's flags and the database's `mission_attempts.flags` check must be the same set
/// (lead note on PR #7): a flag the engine raises but the database refuses would make every
/// sync of that attempt fail. A new flag ships as a migration first, then here.
void main() {
  test('Flag wire names equal the flags check in the mission_attempts migration', () {
    final migrations = Directory('../../supabase/migrations');
    final sql = [
      for (final f in migrations.listSync().whereType<File>())
        if (f.path.endsWith('.sql')) f.readAsStringSync(),
    ].join('\n');
    final check = RegExp(r'flags\s*<@\s*array\[([^\]]*)\]')
        .allMatches(sql)
        .toList();
    expect(check, isNotEmpty, reason: 'the flags check is in a migration');
    // The latest definition wins, if a later migration ever replaces the check.
    final names = RegExp(r"'([a-z_]+)'")
        .allMatches(check.last.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();
    expect(names, {for (final f in Flag.values) f.wireName});
  });
}
