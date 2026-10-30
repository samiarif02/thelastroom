import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/remote_rows.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';

/// The rows the app sends and the database's migrations must agree, or every sync fails on the
/// phone while the tests stay green.
void main() {
  final sql = [
    for (final f in Directory(
      '../../supabase/migrations',
    ).listSync().whereType<File>())
      if (f.path.endsWith('.sql')) f.readAsStringSync(),
  ].join('\n');

  /// The columns of the last `grant <privilege> (...) on table public.<table>`.
  Set<String> granted(String privilege, String table) {
    final grants = RegExp(
      'grant $privilege \\(([^)]*)\\)\\s*on table public\\.$table',
    ).allMatches(sql).toList();
    expect(grants, isNotEmpty, reason: '$privilege grant on $table');
    return grants.last.group(1)!.split(',').map((c) => c.trim()).toSet();
  }

  final attempt = RemoteAttempt(
    attemptId: 'a',
    missionId: 'm',
    contentSchemaVersion: 1,
    relevance: 0,
    specificity: 0,
    structure: 0,
    adaptability: 0,
    total: 0,
    hinted: false,
    flags: const [],
    completedAt: DateTime.utc(2026),
    attemptNumber: 1,
    seed: 1,
    beatOptionIds: const ['o'],
    followUpId: 'f',
    replyOptionId: 'r',
  );

  test('an attempt row sends exactly the columns a client may insert', () {
    expect(attempt.toRow().keys.toSet(), granted('insert', 'mission_attempts'));
  });

  test('a profile row sends only columns a client may insert and update', () {
    final keys = const RemoteProfile().toRow().keys.toSet();
    expect(granted('insert', 'profiles'), containsAll(keys));
    expect(granted('update', 'profiles'), containsAll(keys));
  });

  test('nothing the server sets, and never the draft, is in a sent row', () {
    for (final row in [attempt.toRow(), const RemoteProfile().toRow()]) {
      expect(row.keys, isNot(contains('user_id')));
      expect(row.keys, isNot(contains('created_at')));
      expect(row.keys, isNot(contains('draft')));
    }
  });

  test('the experience check lists every Experience name', () {
    final check = RegExp(r'experience in \(([^)]*)\)').firstMatch(sql)!;
    final names = RegExp("'([A-Za-z]+)'")
        .allMatches(check.group(1)!)
        .map((m) => m.group(1))
        .toSet();
    expect(names, {for (final e in Experience.values) e.name});
  });

  test('a row read back maps to the same values', () {
    final back = RemoteAttempt.fromRow({
      ...attempt.toRow(),
      'user_id': 'u',
      'created_at': '2026-10-31T00:00:00Z',
    })!;
    expect(back.toRow(), attempt.toRow());
    const profile = RemoteProfile(
      firstName: 'Sami',
      nervesLevel: 4,
      onboarded: true,
    );
    expect(RemoteProfile.fromRow(profile.toRow()).toRow(), profile.toRow());
  });

  test('a server row without picks is not restorable', () {
    final old = attempt.toRow()..remove('beat_option_ids');
    expect(RemoteAttempt.fromRow(old), isNull);
  });
}
