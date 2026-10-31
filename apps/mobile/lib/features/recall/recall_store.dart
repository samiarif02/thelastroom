import 'dart:convert';

import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Recall Room's state on the device: its cards, and the attempts already turned into
/// cards (so an attempt is only counted once, even after its cards retire).
class RecallSchedule {
  const RecallSchedule({this.cards = const [], this.ingested = const {}});

  final List<RecallCard> cards;

  /// Keys of the attempts whose mistakes are already cards ([attemptKey]).
  final Set<String> ingested;

  static const RecallSchedule empty = RecallSchedule();

  Map<String, Object?> toJson() => {
    'v': _version,
    'cards': [
      for (final c in cards)
        {'id': c.cardId, 'box': c.box.name, 'due': _dayToJson(c.due)},
    ],
    'ingested': ingested.toList()..sort(),
  };

  /// Parses what [toJson] wrote. Anything malformed (another version, a hand-edited value) is a
  /// [FormatException]; the store then starts over rather than crash the room.
  static RecallSchedule fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['v'] != _version) {
      throw const FormatException('not a recall schedule');
    }
    final cards = json['cards'];
    final ingested = json['ingested'];
    if (cards is! List<Object?> || ingested is! List<Object?>) {
      throw const FormatException('recall schedule is missing its lists');
    }
    return RecallSchedule(
      cards: [for (final c in cards) _cardFromJson(c)],
      ingested: {
        for (final key in ingested)
          if (key is String) key else throw const FormatException('bad key'),
      },
    );
  }

  static RecallCard _cardFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'box': final String box,
      'due': final String due,
    }) {
      final leitner = LeitnerBox.values.where((b) => b.name == box).firstOrNull;
      if (leitner == null) throw FormatException('unknown box', box);
      return RecallCard(cardId: id, box: leitner, due: _dayFromJson(due));
    }
    throw const FormatException('not a recall card');
  }

  static const int _version = 1;
}

/// The key an attempt is remembered by: its stored id, or (for an attempt not yet stored, as in
/// the in-memory repository) its mission and number.
String attemptKey(String missionId, int attemptNumber, String? attemptId) =>
    attemptId ?? '$missionId#$attemptNumber';

String _dayToJson(CalendarDay day) => day.toString();

CalendarDay _dayFromJson(String text) {
  final parts = text.split('-');
  if (parts.length != _dateParts) throw FormatException('not a day', text);
  final numbers = [for (final p in parts) int.tryParse(p)];
  if (numbers.contains(null)) throw FormatException('not a day', text);
  return CalendarDay(numbers[0]!, numbers[1]!, numbers[2]!);
}

const int _dateParts = 3;

/// Where the schedule persists.
abstract interface class RecallStore {
  /// The saved schedule, or [RecallSchedule.empty] on first run.
  Future<RecallSchedule> load();

  Future<void> save(RecallSchedule schedule);
}

/// [RecallStore] on `shared_preferences`: one small JSON document, on the device only (no
/// account needed, works offline).
class SharedPreferencesRecallStore implements RecallStore {
  const SharedPreferencesRecallStore();

  static const String key = 'recall.schedule';

  @override
  Future<RecallSchedule> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(key);
    if (text == null) return RecallSchedule.empty;
    return RecallSchedule.fromJson(jsonDecode(text));
  }

  @override
  Future<void> save(RecallSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(schedule.toJson()));
  }
}

/// An in-memory store for tests and the catalog.
class InMemoryRecallStore implements RecallStore {
  InMemoryRecallStore([this.schedule = RecallSchedule.empty]);

  RecallSchedule schedule;

  @override
  Future<RecallSchedule> load() async => schedule;

  @override
  Future<void> save(RecallSchedule schedule) async => this.schedule = schedule;
}

final recallStoreProvider = Provider<RecallStore>(
  (ref) => const SharedPreferencesRecallStore(),
);
