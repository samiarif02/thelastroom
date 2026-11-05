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
  /// the last table-wide revoke, less any column revoked after (issue 74's XP columns). Postgres
  /// adds column grants up, so a later migration's grant (brief 30's `beat_plays`) extends the
  /// earlier list rather than replacing it.
  Set<String> granted(String privilege, String table) {
    final revokes = RegExp(
      'revoke [a-z, ]*$privilege[a-z, ]* on table public\\.$table\\b',
    ).allMatches(sql).toList();
    final since = revokes.isEmpty ? 0 : revokes.last.end;
    final grants = RegExp(
      'grant $privilege \\(([^)]*)\\)\\s*on table public\\.$table\\b',
    ).allMatches(sql.substring(since)).toList();
    expect(grants, isNotEmpty, reason: '$privilege grant on $table');
    final revoked = {
      for (final r in RegExp(
        'revoke $privilege \\(([^)]*)\\)\\s*on table public\\.$table\\b',
      ).allMatches(sql.substring(since)))
        for (final c in r.group(1)!.split(',')) c.trim(),
    };
    return {
      for (final g in grants)
        for (final c in g.group(1)!.split(',')) c.trim(),
    }.difference(revoked);
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

  const report = RemoteLeaderboardReport(visible: true);

  test('the leaderboard report sends only its own granted columns', () {
    final keys = report.toRow().keys.toSet();
    expect(granted('insert', 'profiles'), containsAll(keys));
    expect(granted('update', 'profiles'), containsAll(keys));
    expect(keys, isNot(contains('total_xp_at')));
    expect(keys, isNot(contains('week_xp_at')));
  });

  test(
    'no client may write the board\'s XP (issue 74): the server counts it',
    () {
      const xp = {'total_xp', 'week_xp', 'week_start', 'streak_weeks'};
      expect(granted('insert', 'profiles').intersection(xp), isEmpty);
      expect(granted('update', 'profiles').intersection(xp), isEmpty);
      expect(report.toRow().keys.toSet().intersection(xp), isEmpty);
    },
  );

  test('the profile row leaves the leaderboard columns to the report', () {
    // A project without the leaderboard migration still takes the profile.
    expect(
      const RemoteProfile().toRow().keys.toSet().intersection(
        report.toRow().keys.toSet(),
      ),
      isEmpty,
    );
  });

  test('the board function returns the columns the app reads, and no id', () {
    final returns = RegExp(
      r'create function public\.leaderboard\([^)]*\)\s*returns table \(([^)]*)\)',
    ).firstMatch(sql)!;
    final columns = [
      for (final line in returns.group(1)!.split(','))
        line.trim().split(RegExp(r'\s+')).first,
    ];
    expect(columns, [
      'rank',
      'display_name',
      'tag',
      'total_xp',
      'week_xp',
      'streak_weeks',
      'is_me',
    ]);
    final row = RemoteLeaderboardRow.fromRow({
      for (final c in columns)
        c: c == 'tag'
            ? '4821'
            : (c == 'is_me' ? true : (c == 'display_name' ? 'Sami' : 1)),
    });
    expect(row, isNotNull);
    expect(row!.tag, '4821');
    expect(row.displayName, 'Sami');
  });

  test('a board row with a missing or wrong column is skipped', () {
    expect(RemoteLeaderboardRow.fromRow({'rank': 1}), isNull);
    expect(RemoteLeaderboardRow.fromRow('x'), isNull);
    final noName = RemoteLeaderboardRow.fromRow({
      'rank': 2,
      'display_name': null,
      'tag': '0042',
      'total_xp': 10,
      'week_xp': 0,
      'streak_weeks': 0,
      'is_me': false,
    });
    expect(noName?.displayName, isNull);
  });

  test('visibility is read back from the profile row, on by default', () {
    expect(RemoteProfile.fromRow(const {}).leaderboardVisible, isTrue);
    expect(
      RemoteProfile.fromRow(const {'leaderboard_visible': false})
          .leaderboardVisible,
      isFalse,
    );
  });

  test('nothing the server sets, and never the draft, is in a sent row', () {
    for (final row in [
      attempt.toRow(),
      voiceAttempt.toRow(),
      const RemoteProfile().toRow(),
      report.toRow(),
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
