import 'dart:convert';

import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend/remote_rows.dart';
import '../../core/profile/profile_repository.dart';

/// One player on the board, as `public.leaderboard()` returned them: a first name (or none), the
/// server's 4-digit tag, the XP, the streak. Never a user id or an email (the server sends none).
class BoardEntry {
  const BoardEntry({
    required this.rank,
    required this.firstName,
    required this.tag,
    required this.totalXp,
    required this.weekXp,
    required this.streakWeeks,
    required this.isMe,
  });

  factory BoardEntry.fromRemote(RemoteLeaderboardRow r) => BoardEntry(
    rank: r.rank,
    firstName: r.displayName,
    tag: r.tag,
    totalXp: r.totalXp,
    weekXp: r.weekXp,
    streakWeeks: r.streakWeeks,
    isMe: r.isMe,
  );

  final int rank;
  final String? firstName;
  final String tag;
  final int totalXp;
  final int weekXp;
  final int streakWeeks;
  final bool isMe;

  /// The name as players see it: the first name as it's said ([PlayerProfile.spokenName]), or
  /// "Candidate" with no name.
  String get name {
    final spoken = PlayerProfile.spokenName(firstName ?? '');
    return spoken.isEmpty ? PlayerProfile.fallbackName : spoken;
  }

  bool get hasName => PlayerProfile.spokenName(firstName ?? '').isNotEmpty;

  /// "Sami · #4821", or "Candidate 4821" with no first name: duplicates stay distinguishable.
  String get label => hasName ? '$name · #$tag' : '$name $tag';

  League get league => leagueFor(totalXp);

  /// The figure [scope] ranks.
  int score(LeaderboardScope scope) =>
      scope == LeaderboardScope.week ? weekXp : totalXp;

  Map<String, Object?> toJson() => {
    'rank': rank,
    'name': firstName,
    'tag': tag,
    'total_xp': totalXp,
    'week_xp': weekXp,
    'streak_weeks': streakWeeks,
    'me': isMe,
  };

  static BoardEntry? fromJson(Object? json) {
    if (json case {
      'rank': final int rank,
      'tag': final String tag,
      'total_xp': final int total,
      'week_xp': final int week,
      'streak_weeks': final int streak,
      'me': final bool me,
    }) {
      final name = (json as Map<String, Object?>)['name'];
      return BoardEntry(
        rank: rank,
        firstName: name is String ? name : null,
        tag: tag,
        totalXp: total,
        weekXp: week,
        streakWeeks: streak,
        isMe: me,
      );
    }
    return null;
  }
}

/// A board as fetched at [fetchedAt]: its entries best first, the caller's among them.
class Board {
  Board({
    required this.scope,
    required List<BoardEntry> entries,
    required this.fetchedAt,
  }) : entries = [...entries]..sort((a, b) => a.rank.compareTo(b.rank));

  final LeaderboardScope scope;
  final List<BoardEntry> entries;

  /// When the server answered (UTC). An offline board says "as of" this.
  final DateTime fetchedAt;

  /// The caller's row; null only on a board fetched before they had a profile row.
  BoardEntry? get me => entries.where((e) => e.isMe).firstOrNull;

  /// Everyone on the board who has scored, the caller included when they have.
  List<BoardEntry> get scored => [
    for (final e in entries)
      if (e.score(scope) > 0) e,
  ];

  /// No one has scored yet on this board ("Be the first on the board").
  bool get isEmpty => scored.isEmpty;

  /// The podium: the first three who scored.
  List<BoardEntry> get podium => scored.take(podiumSize).toList();

  /// Everyone after the podium, best first (the caller wherever they are, even with 0).
  List<BoardEntry> get rest => [
    for (final e in entries)
      if (!podium.contains(e)) e,
  ];

  /// The player just above the caller on this board, or the last listed one when the caller is
  /// outside the top N; null at the top.
  BoardEntry? get above {
    final mine = me;
    if (mine == null) return null;
    final ahead = [
      for (final e in entries)
        if (e.rank < mine.rank) e,
    ];
    return ahead.lastOrNull;
  }

  static const int podiumSize = 3;

  Map<String, Object?> toJson() => {
    'v': _version,
    'scope': scope.wireName,
    'at': fetchedAt.toUtc().toIso8601String(),
    'entries': [for (final e in entries) e.toJson()],
  };

  /// Parses what [toJson] wrote; null for anything else (the cache is then ignored).
  static Board? fromJson(Object? json) {
    if (json case {
      'v': _version,
      'scope': final String scope,
      'at': final String at,
      'entries': final List<Object?> entries,
    }) {
      final s = LeaderboardScope.values
          .where((v) => v.wireName == scope)
          .firstOrNull;
      final time = DateTime.tryParse(at);
      if (s == null || time == null) return null;
      return Board(
        scope: s,
        entries: [for (final e in entries) ?BoardEntry.fromJson(e)],
        fetchedAt: time.toUtc(),
      );
    }
    return null;
  }

  static const int _version = 1;
}

/// The last board of each scope this device saw, for offline ("as of …"), and the caller's
/// score when they last looked (the count-up). The board holds other players' first names and
/// tags, exactly as it showed them; nothing else.
abstract interface class LeaderboardCache {
  Future<Board?> load(LeaderboardScope scope);
  Future<void> save(Board board);

  /// The caller's score on [scope] when they last looked, or null the first time.
  Future<int?> seen(LeaderboardScope scope);
  Future<void> setSeen(LeaderboardScope scope, int score);
}

class SharedPreferencesLeaderboardCache implements LeaderboardCache {
  SharedPreferencesLeaderboardCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const String prefix = 'leaderboard.';

  @override
  Future<Board?> load(LeaderboardScope scope) async {
    final text = await _prefs.getString('${prefix}board.${scope.wireName}');
    if (text == null) return null;
    try {
      return Board.fromJson(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Board board) => _prefs.setString(
    '${prefix}board.${board.scope.wireName}',
    jsonEncode(board.toJson()),
  );

  @override
  Future<int?> seen(LeaderboardScope scope) =>
      _prefs.getInt('${prefix}seen.${scope.wireName}');

  @override
  Future<void> setSeen(LeaderboardScope scope, int score) =>
      _prefs.setInt('${prefix}seen.${scope.wireName}', score);
}

class InMemoryLeaderboardCache implements LeaderboardCache {
  InMemoryLeaderboardCache({Map<LeaderboardScope, Board>? boards})
    : boards = boards ?? {};

  final Map<LeaderboardScope, Board> boards;
  final Map<LeaderboardScope, int> seenScores = {};

  @override
  Future<Board?> load(LeaderboardScope scope) async => boards[scope];

  @override
  Future<void> save(Board board) async => boards[board.scope] = board;

  @override
  Future<int?> seen(LeaderboardScope scope) async => seenScores[scope];

  @override
  Future<void> setSeen(LeaderboardScope scope, int score) async =>
      seenScores[scope] = score;
}

final leaderboardCacheProvider = Provider<LeaderboardCache>(
  (ref) => SharedPreferencesLeaderboardCache(),
);
