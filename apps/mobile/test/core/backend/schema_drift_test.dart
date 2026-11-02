import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/remote_rows.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';

/// The rows the app sends and the database's migrations must agree, or every sync fails on the
/// phone while the tests stay green.
void main() {
  // In the order they're applied: by file name (the timestamp).
  final files = [
    for (final f in Directory(
      '../../supabase/migrations',
    ).listSync().whereType<File>())
      if (f.path.endsWith('.sql')) f,
  ]..sort((a, b) => a.path.compareTo(b.path));
  final sql = [for (final f in files) f.readAsStringSync()].join('\n');

  /// The columns a client holds `<privilege>` on for `public.<table>`: every column grant since
  /// the last table-wide revoke. Postgres adds column grants up, so a later migration's grant
  /// (brief 30's `beat_plays`) extends the earlier list rather than replacing it.
  Set<String> granted(String privilege, String table) {
    final revokes = RegExp(
      'revoke [a-z, ]*$privilege[a-z, ]* on table public\\.$table\\b',
    ).allMatches(sql).toList();
    final since = revokes.isEmpty ? 0 : revokes.last.end;
    final grants = RegExp(
      'grant $privilege \\(([^)]*)\\)\\s*on table public\\.$table\\b',
    ).allMatches(sql.substring(since)).toList();
    expect(grants, isNotEmpty, reason: '$privilege grant on $table');
    return {
      for (final g in grants)
        for (final c in g.group(1)!.split(',')) c.trim(),
    };
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
    beatPlays: const [
      {'reason_id': 'o_r1', 'decided_us': 3200000},
    ],
  );

  // A voice mission's attempt (brief 35): the points made instead of the picks.
  final voiceAttempt = RemoteAttempt(
    attemptId: 'v',
    missionId: 'm',
    contentSchemaVersion: 1,
    relevance: 0,
    specificity: 0,
    structure: 0,
    adaptability: 0,
    total: 0,
    hinted: true,
    flags: const [],
    completedAt: DateTime.utc(2026),
    attemptNumber: 1,
    seed: 0,
    beatOptionIds: const [],
    followUpId: '',
    replyOptionId: '',
    voiceAnswer: const {
      'made': ['p1'],
      'source': 'ai',
      'seconds': 3,
    },
  );

  test('an attempt row sends exactly the columns a client may insert', () {
    // Between them, a built answer and a spoken one use every granted column, and no other.
    expect({
      ...attempt.toRow().keys,
      ...voiceAttempt.toRow().keys,
    }, granted('insert', 'mission_attempts'));
    expect(
      granted('insert', 'mission_attempts'),
      containsAll(voiceAttempt.toRow().keys),
    );
  });

  test('a profile row sends only columns a client may insert and update', () {
    final keys = const RemoteProfile().toRow().keys.toSet();
    expect(granted('insert', 'profiles'), containsAll(keys));
    expect(granted('update', 'profiles'), containsAll(keys));
  });

  test('nothing the server sets, and never the draft, is in a sent row', () {
    for (final row in [
      attempt.toRow(),
      voiceAttempt.toRow(),
      const RemoteProfile().toRow(),
    ]) {
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
