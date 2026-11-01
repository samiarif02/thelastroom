import 'dart:async';
import 'dart:convert';

import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/backend/backend.dart';
import 'ai_score.dart';

/// The AI recruiter's latest verdict on a mission, and when it was given: what "Your file" shows
/// beside the mission (brief 24), as long as no later attempt was played without one.
class SavedAiScore {
  const SavedAiScore({
    required this.missionId,
    required this.at,
    required this.score,
  });

  final String missionId;
  final DateTime at;
  final AiScore score;

  Map<String, Object?> toJson() => {
    'mission_id': missionId,
    'at': at.toUtc().toIso8601String(),
    'model': score.model,
    'overall': _graded(score.overall),
    'dimensions': {
      for (final d in Dimension.values) d.name: _graded(score.dimensions[d]!),
    },
  };

  static Map<String, Object?> _graded(AiGraded g) => {
    'score': g.score,
    'basis': g.basis,
  };

  /// Reads what [toJson] wrote; null for anything malformed (it's simply not shown).
  static SavedAiScore? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final missionId = json['mission_id'];
    final at = DateTime.tryParse(
      json['at'] is String ? json['at']! as String : '',
    );
    final score = AiScore.fromJson(json);
    if (missionId is! String || at == null || score == null) return null;
    return SavedAiScore(missionId: missionId, at: at, score: score);
  }

  /// One `ai_scores` row from the server (the restore on a fresh install); null if malformed.
  static SavedAiScore? fromRow(Object? row) {
    if (row is! Map<String, Object?>) return null;
    final basis = row['basis'];
    if (basis is! Map<String, Object?>) return null;
    Map<String, Object?> graded(String column, String key) => {
      'score': row[column],
      'basis': basis[key],
    };
    return fromJson({
      'mission_id': row['mission_id'],
      'at': row['created_at'],
      'model': row['model'],
      'overall': graded('overall_score', 'overall'),
      'dimensions': {
        for (final d in Dimension.values)
          d.name: graded('${d.name}_score', d.name),
      },
    });
  }
}

/// The verdicts kept on this device, the latest per mission.
abstract interface class AiScoreStore {
  Future<Map<String, SavedAiScore>> latest();
  Future<void> save(SavedAiScore saved);
}

/// [AiScoreStore] in `shared_preferences`: one JSON map, keyed by mission id.
class LocalAiScoreStore implements AiScoreStore {
  LocalAiScoreStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const String _key = 'ai_scores.latest';

  @override
  Future<Map<String, SavedAiScore>> latest() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return const {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return const {};
      return {
        for (final entry in json.entries)
          entry.key: ?SavedAiScore.fromJson(entry.value),
      };
    } on FormatException {
      return const {};
    }
  }

  @override
  Future<void> save(SavedAiScore saved) async {
    final all = {...await latest(), saved.missionId: saved};
    await _prefs.setString(
      _key,
      jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}),
    );
  }
}

/// For tests, and wherever the device store isn't wanted.
class InMemoryAiScoreStore implements AiScoreStore {
  final Map<String, SavedAiScore> _saved = {};

  @override
  Future<Map<String, SavedAiScore>> latest() async => Map.unmodifiable(_saved);

  @override
  Future<void> save(SavedAiScore saved) async =>
      _saved[saved.missionId] = saved;
}

final aiScoreStoreProvider = Provider<AiScoreStore>(
  (ref) => LocalAiScoreStore(),
);

/// How long "Your file" waits for the server's verdicts before showing the device's alone.
const Duration aiScoresFetchTimeout = Duration(seconds: 5);

/// The latest AI verdict per mission: this device's, merged with the server's `ai_scores` when
/// there's a backend and a session (a fresh install gets its verdicts back). The newer of the
/// two wins. Never fails: a store or network problem just means fewer verdicts.
final latestAiScoresProvider =
    FutureProvider.autoDispose<Map<String, SavedAiScore>>((ref) async {
      final local = await _guard(ref.read(aiScoreStoreProvider).latest);
      final merged = {...?local};
      final env = ref.read(envProvider);
      if (env.hasSupabase && ref.read(sessionProvider) is GuestSession) {
        final rows = await _guard(
          () => ref
              .read(backendProvider)
              .fetchAiScores()
              .timeout(aiScoresFetchTimeout),
        );
        for (final row in rows ?? const <Object?>[]) {
          final s = SavedAiScore.fromRow(row);
          if (s == null) continue;
          final mine = merged[s.missionId];
          if (mine == null || s.at.isAfter(mine.at)) merged[s.missionId] = s;
        }
      }
      return merged;
    });

Future<T?> _guard<T>(Future<T> Function() read) async {
  try {
    return await read();
  } on Object {
    return null;
  }
}
