import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/profile_repository.dart';
import '../../core/progress/progress_repository.dart';
import '../progression/progression.dart';
import '../progression/skill_badges.dart';

/// What a floor card shows ("Share your floor card", direction.md §6), read off the stored
/// attempts and the progression: nothing here scores anything. Every field is the player's own
/// progress; the only personal thing is [name], and only when the player typed one.
class FloorCardFacts {
  const FloorCardFacts({
    required this.floor,
    required this.title,
    required this.rooms,
    required this.skills,
    required this.xp,
    required this.hosts,
    this.firstRoom,
    this.lastRoom,
    this.then,
    this.now,
    this.name,
  });

  /// From the floor's missions, the [progression] and the stored [attempts] (oldest first).
  /// [name] is what the player typed, if anything: the card shows it as it's said
  /// ([PlayerProfile.spokenName]), and leaves it off when it's empty.
  factory FloorCardFacts.of({
    required int floor,
    required Progression progression,
    required List<AttemptRecord> attempts,
    String? name,
  }) {
    final n = floor.clamp(1, chapters.length);
    final chapter = chapters.firstWhere((c) => c.number == n);
    final rooms = [
      for (final m in missions)
        if (m.chapter == n) m,
    ];
    final first = rooms.isEmpty ? null : rooms.first;
    final last = rooms.isEmpty ? null : rooms.last;
    AttemptRecord? firstOf(Mission? m) =>
        attempts.where((a) => a.missionId == m?.id).firstOrNull;
    AttemptRecord? latestOf(Mission? m) =>
        attempts.where((a) => a.missionId == m?.id).lastOrNull;
    // The skills this floor's rooms can earn, in the order they're earned, that the player has.
    final floorSkills = {
      for (final m in rooms)
        for (final r in m.skillRequirements) r.skill,
    };
    final spoken = PlayerProfile.spokenName(name?.trim() ?? '');
    return FloorCardFacts(
      floor: n,
      title: chapter.title,
      rooms: rooms.length,
      skills: [
        for (final s in SkillCopy.order)
          if (floorSkills.contains(s) && progression.unlocked.contains(s)) s,
      ],
      xp: progression.xp,
      hosts: <String>{for (final m in rooms) m.question.speakerId}
          .take(hostCount)
          .toList(),
      firstRoom: first?.number,
      lastRoom: last?.number,
      then: firstOf(first)?.score.total,
      now: latestOf(last)?.score.total,
      name: spoken.isEmpty ? null : spoken,
    );
  }

  /// 1, 2 or 3.
  final int floor;

  /// The floor's name ("Get through the door").
  final String title;

  /// How many rooms the floor has (all of them lit: the card is for a cleared floor).
  final int rooms;

  /// The skills earned on this floor, in the order the campaign earns them.
  final List<Skill> skills;
  final int xp;

  /// The floor's interviewers' cast ids, at most [hostCount].
  final List<String> hosts;

  /// The floor's first and last room numbers (1 and 7 on floor 1).
  final int? firstRoom;
  final int? lastRoom;

  /// The first room's first score and the last room's latest: then vs now. Null when either
  /// isn't stored (the card then leaves the pair out rather than invent one).
  final int? then;
  final int? now;

  /// The player's name as it's said, only when they typed one.
  final String? name;

  /// A floor has three interviewers.
  static const int hostCount = 3;

  bool get hasThenNow => then != null && now != null;
}

/// The card's facts for [floor], from the progress store, the progression and the profile.
final floorCardFactsProvider = FutureProvider.autoDispose
    .family<FloorCardFacts, int>((ref, floor) async {
      final progression = await ref.watch(progressionProvider.future);
      final attempts = await ref.read(progressRepositoryProvider).attempts();
      final profile = await ref.watch(profileProvider.future);
      return FloorCardFacts.of(
        floor: floor,
        progression: progression,
        attempts: attempts,
        name: profile.firstName,
      );
    });
