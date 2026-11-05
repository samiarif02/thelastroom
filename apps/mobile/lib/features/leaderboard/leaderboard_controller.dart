import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/backend/backend.dart';
import '../../core/leaderboard/leaderboard_report.dart';
import '../progression/progression.dart';
import 'leaderboard_board.dart';

/// What the leaderboard screen shows for one scope.
sealed class BoardState {
  const BoardState();
}

/// A board to show: [live] straight from the server, or the last one this device saw (offline,
/// "as of …"). [seenBefore] is the caller's score when they last looked, for the count-up.
class BoardReady extends BoardState {
  const BoardReady(this.board, {required this.live, this.seenBefore});

  final Board board;
  final bool live;
  final int? seenBefore;
}

/// No backend in this build (no keys, ADR 0005): there's no shared board, and nothing failed.
class BoardNoBackend extends BoardState {
  const BoardNoBackend();
}

/// The board can't be reached (offline, or the guest isn't signed in yet) and none is cached.
class BoardUnavailable extends BoardState {
  const BoardUnavailable();
}

/// The board for [LeaderboardScope]. With a session it first sends what's queued (so the
/// caller's own XP is current), then fetches; any failure falls back to the cached board.
final leaderboardProvider = FutureProvider.autoDispose
    .family<BoardState, LeaderboardScope>((ref, scope) async {
      if (!ref.watch(envProvider).hasSupabase) return const BoardNoBackend();
      final cache = ref.watch(leaderboardCacheProvider);
      final session = ref.watch(sessionProvider);
      final seen = await cache.seen(scope);
      if (session is GuestSession) {
        await _sendQueued(ref);
        try {
          final rows = await ref
              .read(backendProvider)
              .fetchLeaderboard(scope)
              .timeout(LeaderboardTiming.fetch);
          final board = Board(
            scope: scope,
            entries: [for (final r in rows) BoardEntry.fromRemote(r)],
            fetchedAt: ref.read(progressionClockProvider)().toUtc(),
          );
          await cache.save(board);
          return BoardReady(board, live: true, seenBefore: seen);
        } on Object catch (e) {
          // Offline or the server refused: the cached board, said to be old. Only the type.
          ref.read(logProvider).warn('leaderboard unavailable', {
            'error': '${e.runtimeType}',
          });
        }
      }
      final cached = await cache.load(scope);
      return cached == null
          ? const BoardUnavailable()
          : BoardReady(cached, live: false, seenBefore: seen);
    });

/// Sends what's queued first, so the caller's own row is current; never blocks the board for
/// long, and a failure here only means the row may be a little behind.
Future<void> _sendQueued(Ref ref) async {
  try {
    await ref
        .read(syncWorkerProvider)
        ?.flush()
        .timeout(LeaderboardTiming.flush, onTimeout: () {});
  } on Object catch (e) {
    ref.read(logProvider).warn('leaderboard flush skipped', {
      'error': '${e.runtimeType}',
    });
  }
}

abstract final class LeaderboardTiming {
  /// How long the board waits for the outbox before it fetches anyway.
  static const Duration flush = Duration(seconds: 3);

  /// How long the fetch may take before the cached board shows.
  static const Duration fetch = Duration(seconds: 8);
}

/// "Show me on the leaderboard" (on by default).
final leaderboardVisibleProvider = FutureProvider.autoDispose<bool>(
  (ref) async =>
      (await ref.watch(leaderboardReportStoreProvider).load()).visible,
);

final leaderboardActionsProvider = Provider<LeaderboardActions>(
  LeaderboardActions.new,
);

class LeaderboardActions {
  LeaderboardActions(this._ref);

  final Ref _ref;

  /// Switches "Show me on the leaderboard": stored, queued for the server, tracked (only the
  /// flag). The boards refetch, so the change shows at once.
  Future<void> setVisible(bool visible) async {
    final store = _ref.read(leaderboardReportStoreProvider);
    try {
      final report = await store.load();
      if (report.visible != visible) {
        await store.save(report.copyWith(visible: visible));
      }
    } on Object catch (e) {
      _ref.read(logProvider).warn('leaderboard visibility not saved', {
        'error': '${e.runtimeType}',
      });
      return;
    }
    _ref.read(analyticsProvider).track(
      AnalyticsEvent.leaderboardVisibilityChanged,
      {'visible': EventValue.flag(visible)},
    );
    _ref
      ..invalidate(leaderboardVisibleProvider)
      ..invalidate(leaderboardProvider);
  }

  /// The caller looked at [scope] with [score]: the next visit counts up from here.
  Future<void> seen(LeaderboardScope scope, int score) async {
    try {
      await _ref.read(leaderboardCacheProvider).setSeen(scope, score);
    } on Object catch (e) {
      _ref.read(logProvider).warn('leaderboard seen not saved', {
        'error': '${e.runtimeType}',
      });
    }
  }
}

/// Keeps the report current: whenever progression changes (a room, a Recall round, a new
/// week), the engine's numbers are stored and queued for the board. `main.dart` keeps it alive.
final leaderboardReporterProvider = Provider<void>((ref) {
  ref.listen(progressionProvider, (_, next) {
    if (next.value case final p?) unawaited(reportProgression(ref, p));
  }, fireImmediately: true);
});

/// Stores [p]'s numbers in the report when they changed. A player who has never earned XP
/// reports nothing (no empty row on the server).
Future<void> reportProgression(Ref ref, Progression p) async {
  final store = ref.read(leaderboardReportStoreProvider);
  try {
    final current = await store.load();
    if (p.xp == 0 && current == LeaderboardReport.initial) return;
    final next = current.copyWith(
      totalXp: p.xp,
      weekXp: p.weekXp,
      weekStart: p.weekStartUtc,
      streakWeeks: p.weeksInARow,
    );
    if (next != current) await store.save(next);
  } on Object catch (e) {
    if (ref.mounted) {
      ref.read(logProvider).warn('leaderboard report not saved', {
        'error': '${e.runtimeType}',
      });
    }
  }
}
