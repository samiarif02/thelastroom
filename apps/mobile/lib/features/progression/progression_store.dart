import 'dart:convert';

import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What progression keeps on the device beyond the stored attempts: the Recall Room's XP and
/// the days it was played (rounds aren't attempts), the skills already celebrated (each unlock
/// card is shown once), and the player's interview date (FR-4; it stays on the device).
class ProgressionRecord {
  const ProgressionRecord({
    this.recallXp = 0,
    this.recallDays = const {},
    this.celebrated = const {},
    this.interviewDate,
  });

  final int recallXp;
  final Set<CalendarDay> recallDays;
  final Set<Skill> celebrated;
  final CalendarDay? interviewDate;

  static const ProgressionRecord empty = ProgressionRecord();

  ProgressionRecord copyWith({
    int? recallXp,
    Set<CalendarDay>? recallDays,
    Set<Skill>? celebrated,
    CalendarDay? Function()? interviewDate,
  }) => ProgressionRecord(
    recallXp: recallXp ?? this.recallXp,
    recallDays: recallDays ?? this.recallDays,
    celebrated: celebrated ?? this.celebrated,
    interviewDate: interviewDate == null ? this.interviewDate : interviewDate(),
  );

  Map<String, Object?> toJson() => {
    'v': _version,
    'recall_xp': recallXp,
    'recall_days': [for (final d in recallDays) d.toString()]..sort(),
    'celebrated': [for (final s in celebrated) s.wireName]..sort(),
    'interview_date': interviewDate?.toString(),
  };

  /// Parses what [toJson] wrote; anything else is a [FormatException] (the caller starts over).
  static ProgressionRecord fromJson(Object? json) {
    if (json case {
      'v': _version,
      'recall_xp': final int xp,
      'recall_days': final List<Object?> days,
      'celebrated': final List<Object?> celebrated,
    }) {
      final date = (json as Map<String, Object?>)['interview_date'];
      return ProgressionRecord(
        recallXp: xp,
        recallDays: {for (final d in days) _day(d)},
        celebrated: {
          for (final s in celebrated)
            Skill.values.firstWhere(
              (k) => k.wireName == s,
              orElse: () => throw FormatException('unknown skill', s),
            ),
        },
        interviewDate: date == null ? null : _day(date),
      );
    }
    throw const FormatException('not a progression record');
  }

  static CalendarDay _day(Object? text) {
    final parts = text is String ? text.split('-') : const <String>[];
    final numbers = [for (final p in parts) int.tryParse(p)];
    if (numbers.length != _dateParts || numbers.contains(null)) {
      throw FormatException('not a day', text);
    }
    return CalendarDay(numbers[0]!, numbers[1]!, numbers[2]!);
  }

  static const int _version = 1;
  static const int _dateParts = 3;
}

abstract interface class ProgressionStore {
  Future<ProgressionRecord> load();
  Future<void> save(ProgressionRecord record);
}

class SharedPreferencesProgressionStore implements ProgressionStore {
  const SharedPreferencesProgressionStore();

  static const String key = 'progression.record';

  @override
  Future<ProgressionRecord> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(key);
    if (text == null) return ProgressionRecord.empty;
    return ProgressionRecord.fromJson(jsonDecode(text));
  }

  @override
  Future<void> save(ProgressionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(record.toJson()));
  }
}

class InMemoryProgressionStore implements ProgressionStore {
  InMemoryProgressionStore([this.record = ProgressionRecord.empty]);

  ProgressionRecord record;

  @override
  Future<ProgressionRecord> load() async => record;

  @override
  Future<void> save(ProgressionRecord record) async => this.record = record;
}

final progressionStoreProvider = Provider<ProgressionStore>(
  (ref) => const SharedPreferencesProgressionStore(),
);
