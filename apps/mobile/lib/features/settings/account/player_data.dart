import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/app_database.dart';
import '../../../core/profile/profile_repository.dart';
import '../../debrief/ai_score_store.dart';
import '../../leaderboard/leaderboard_board.dart';
import '../../mission/mission_resume.dart';
import '../../progression/first_day.dart';
import '../../progression/progression_store.dart';
import '../../recall/recall_store.dart';
import '../../tips/tips.dart';
import '../../tower/welcome_back.dart';

/// What "Sign out" (FR-3) forgets on this device, so the next person starts as a new player.
/// Everything here is the player's, and it's all on the account they signed out of (attempts and
/// the profile on the server; the rest is rebuilt from them, or is a first-time moment the next
/// player should see too):
///
/// - the database: attempts, the profile, the outbox, the restore and merge flags;
/// - the Recall Room's schedule, the progression record (XP from recall rounds, celebrated
///   skills, the interview date), the first-day moment, the last tower visit, the tips seen;
/// - the saved AI verdicts, the left-mission slots, the old pre-database profile keys, and the
///   last leaderboard boards seen (and the leaderboard report, which lives in `meta`).
///
/// What stays is the device's, not the player's: sound on/off and volumes, reminders on/off and
/// whether the permission was asked, and the backend's own session storage (signed out already).
/// Matched by these exact keys and prefixes, so nothing unknown is ever removed.
abstract final class PlayerData {
  /// The `SharedPreferences` keys (the stores written with the legacy API).
  static const List<String> keys = [
    SharedPreferencesRecallStore.key,
    SharedPreferencesProgressionStore.key,
    SharedPreferencesFirstDayStore.key,
    SharedPreferencesLastVisitStore.key,
    SharedPreferencesTipStore.legacyTour,
  ];

  /// `SharedPreferences` key prefixes.
  static const List<String> prefixes = [SharedPreferencesTipStore.prefix];

  /// The `SharedPreferencesAsync` keys.
  static const List<String> asyncKeys = [LocalAiScoreStore.key];

  /// `SharedPreferencesAsync` key prefixes.
  static const List<String> asyncPrefixes = [
    LocalProfileRepository.prefix,
    LocalResumeStore.prefix,
    SharedPreferencesLeaderboardCache.prefix,
  ];

  /// Whether [key] holds player data, by [exact] keys or [starts] prefixes.
  static bool isPlayers(
    String key, {
    required List<String> exact,
    required List<String> starts,
  }) => exact.contains(key) || starts.any(key.startsWith);

  /// Clears it all: the database first (the progress itself), then both preference stores.
  static Future<void> clear(
    AppDatabase db, {
    SharedPreferencesAsync? prefs,
  }) async {
    await db.clearPlayerData();
    final legacy = await SharedPreferences.getInstance();
    for (final key in legacy.getKeys().toList()) {
      if (isPlayers(key, exact: keys, starts: prefixes)) {
        await legacy.remove(key);
      }
    }
    final store = prefs ?? SharedPreferencesAsync();
    final async = await store.getKeys();
    final players = [
      for (final key in async)
        if (isPlayers(key, exact: asyncKeys, starts: asyncPrefixes)) key,
    ];
    if (players.isNotEmpty) await store.clear(allowList: players.toSet());
  }
}
