import 'dart:convert';

import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/remote_rows.dart';
import '../db/app_database.dart';
import '../sync/outbox.dart';

/// What this device reports to the shared leaderboard (issue 72): "Show me on the
/// leaderboard", and the engine's numbers (the same XP "Your file" shows). The device works them
/// out; the server only ranks them.
class LeaderboardReport {
  const LeaderboardReport({
    this.visible = true,
    this.totalXp = 0,
    this.weekXp = 0,
    this.weekStart,
    this.streakWeeks = 0,
  });

  /// "Show me on the leaderboard": on by default. Off, the player still sees the board and
  /// their own rank; nobody else sees them.
  final bool visible;
  final int totalXp;

  /// XP earned in the UTC week starting [weekStart].
  final int weekXp;

  /// The UTC Monday [weekXp] belongs to; null before anything was reported.
  final CalendarDay? weekStart;

  /// Weeks in a row the weekly goal was met ([weeksInARow]).
  final int streakWeeks;

  static const LeaderboardReport initial = LeaderboardReport();

  LeaderboardReport copyWith({
    bool? visible,
    int? totalXp,
    int? weekXp,
    CalendarDay? weekStart,
    int? streakWeeks,
  }) => LeaderboardReport(
    visible: visible ?? this.visible,
    totalXp: totalXp ?? this.totalXp,
    weekXp: weekXp ?? this.weekXp,
    weekStart: weekStart ?? this.weekStart,
    streakWeeks: streakWeeks ?? this.streakWeeks,
  );

  /// The server row. With nothing reported yet, the week is [fallbackWeek]'s (0 XP in it).
  RemoteLeaderboardReport toRemote({required CalendarDay fallbackWeek}) =>
      RemoteLeaderboardReport(
        visible: visible,
        totalXp: totalXp,
        weekXp: weekXp,
        weekStart: '${weekStart ?? fallbackWeek}',
        streakWeeks: streakWeeks,
      );

  Map<String, Object?> toJson() => {
    'visible': visible,
    'total_xp': totalXp,
    'week_xp': weekXp,
    'week_start': weekStart?.toString(),
    'streak_weeks': streakWeeks,
  };

  /// Parses what [toJson] wrote; anything else reads as [initial] (the next report rewrites it).
  static LeaderboardReport fromJson(Object? json) {
    if (json case {
      'visible': final bool visible,
      'total_xp': final int total,
      'week_xp': final int week,
      'streak_weeks': final int streak,
    }) {
      return LeaderboardReport(
        visible: visible,
        totalXp: total,
        weekXp: week,
        weekStart: _day((json as Map<String, Object?>)['week_start']),
        streakWeeks: streak,
      );
    }
    return initial;
  }

  static CalendarDay? _day(Object? text) {
    final parts = text is String ? text.split('-') : const <String>[];
    final n = [for (final p in parts) int.tryParse(p)];
    if (n.length != _dateParts || n.contains(null)) return null;
    return CalendarDay(n[0]!, n[1]!, n[2]!);
  }

  static const int _dateParts = 3;

  @override
  bool operator ==(Object other) =>
      other is LeaderboardReport &&
      other.visible == visible &&
      other.totalXp == totalXp &&
      other.weekXp == weekXp &&
      other.weekStart == weekStart &&
      other.streakWeeks == streakWeeks;

  @override
  int get hashCode =>
      Object.hash(visible, totalXp, weekXp, weekStart, streakWeeks);
}

/// Where the report is kept.
abstract interface class LeaderboardReportStore {
  Future<LeaderboardReport> load();

  /// Stores [report] and queues it for the server.
  Future<void> save(LeaderboardReport report);
}

/// The report in the device's database (a `meta` value), queued in the same transaction
/// ([OutboxKind.leaderboard]), so play offline reaches the board once the device is back.
/// "Sign out" clears it with the rest of `meta`.
class DriftLeaderboardReportStore implements LeaderboardReportStore {
  DriftLeaderboardReportStore(this._db, {this._signal});

  final AppDatabase _db;
  final OutboxSignal? _signal;

  static const String metaKey = 'leaderboard';

  @override
  Future<LeaderboardReport> load() async =>
      await read(_db) ?? LeaderboardReport.initial;

  @override
  Future<void> save(LeaderboardReport report) async {
    await _db.transaction(() async {
      await write(_db, report);
      await Outbox(_db).add(OutboxKind.leaderboard, Outbox.leaderboardRef);
    });
    _signal?.ping();
  }

  /// The stored report, or null before the first.
  static Future<LeaderboardReport?> read(AppDatabase db) async {
    final text = await db.metaValue(metaKey);
    if (text == null) return null;
    try {
      return LeaderboardReport.fromJson(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  /// Writes [report] without queuing it (a restore uses this directly).
  static Future<void> write(AppDatabase db, LeaderboardReport report) =>
      db.setMeta(metaKey, jsonEncode(report.toJson()));
}

/// The report for this run only: tests, and anywhere the device database isn't used.
class InMemoryLeaderboardReportStore implements LeaderboardReportStore {
  InMemoryLeaderboardReportStore([this.report = LeaderboardReport.initial]);

  LeaderboardReport report;

  @override
  Future<LeaderboardReport> load() async => report;

  @override
  Future<void> save(LeaderboardReport report) async => this.report = report;
}

/// The report's store. `main.dart` overrides it with [DriftLeaderboardReportStore].
final leaderboardReportStoreProvider = Provider<LeaderboardReportStore>(
  (ref) => InMemoryLeaderboardReportStore(),
);
