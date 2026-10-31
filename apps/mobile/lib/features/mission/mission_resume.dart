import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One beat as far as the player got: the line, how long they took, and their reason.
class SavedPlay {
  const SavedPlay({required this.optionId, this.decidedIn, this.reasonId});

  final String optionId;
  final Duration? decidedIn;
  final String? reasonId;
}

/// A mission left part-way (the back button, "Leave the interview?"): enough to put the player
/// back where they were. Kept on the device only; the draft's words never leave it.
class SavedAttempt {
  const SavedAttempt({
    required this.missionId,
    required this.seed,
    required this.attemptNumber,
    required this.plays,
    this.draft,
    this.draftDone = false,
  });

  final String missionId;

  /// The attempt's shuffle seed, so the cards come back in the same order.
  final int seed;
  final int attemptNumber;
  final List<SavedPlay> plays;
  final String? draft;
  final bool draftDone;

  Map<String, Object?> toJson() => {
    'mission_id': missionId,
    'seed': seed,
    'attempt_number': attemptNumber,
    'draft': draft,
    'draft_done': draftDone,
    'plays': [
      for (final p in plays)
        {
          'option_id': p.optionId,
          'decided_ms': p.decidedIn?.inMilliseconds,
          'reason_id': p.reasonId,
        },
    ],
  };

  /// Parses what [toJson] wrote. Anything malformed (an older format, a hand-edited store) is
  /// null: the player simply starts the mission afresh.
  static SavedAttempt? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final missionId = json['mission_id'];
    final seed = json['seed'];
    final attempt = json['attempt_number'];
    final plays = json['plays'];
    final draft = json['draft'];
    final draftDone = json['draft_done'];
    if (missionId is! String ||
        seed is! int ||
        attempt is! int ||
        plays is! List<Object?> ||
        (draft != null && draft is! String) ||
        draftDone is! bool) {
      return null;
    }
    final parsed = <SavedPlay>[];
    for (final play in plays) {
      if (play is! Map<String, Object?>) return null;
      final option = play['option_id'];
      final ms = play['decided_ms'];
      final reason = play['reason_id'];
      if (option is! String ||
          (ms != null && ms is! int) ||
          (reason != null && reason is! String)) {
        return null;
      }
      parsed.add(
        SavedPlay(
          optionId: option,
          decidedIn: ms is int ? Duration(milliseconds: ms) : null,
          reasonId: reason is String ? reason : null,
        ),
      );
    }
    return SavedAttempt(
      missionId: missionId,
      seed: seed,
      attemptNumber: attempt,
      plays: parsed,
      draft: draft is String ? draft : null,
      draftDone: draftDone,
    );
  }
}

/// Where a left mission waits to be resumed: one slot per mission.
abstract interface class ResumeStore {
  Future<SavedAttempt?> load(String missionId);
  Future<void> save(SavedAttempt attempt);
  Future<void> clear(String missionId);
}

/// [ResumeStore] in `shared_preferences`, one JSON value per mission.
class LocalResumeStore implements ResumeStore {
  LocalResumeStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static String _key(String missionId) => 'mission_resume.$missionId';

  @override
  Future<SavedAttempt?> load(String missionId) async {
    final raw = await _prefs.getString(_key(missionId));
    if (raw == null) return null;
    try {
      return SavedAttempt.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(SavedAttempt attempt) =>
      _prefs.setString(_key(attempt.missionId), jsonEncode(attempt.toJson()));

  @override
  Future<void> clear(String missionId) => _prefs.remove(_key(missionId));
}

/// For tests, and wherever the device store isn't wanted.
class InMemoryResumeStore implements ResumeStore {
  final Map<String, SavedAttempt> _saved = {};

  @override
  Future<SavedAttempt?> load(String missionId) async => _saved[missionId];

  @override
  Future<void> save(SavedAttempt attempt) async =>
      _saved[attempt.missionId] = attempt;

  @override
  Future<void> clear(String missionId) async => _saved.remove(missionId);
}

final resumeStoreProvider = Provider<ResumeStore>((ref) => LocalResumeStore());
