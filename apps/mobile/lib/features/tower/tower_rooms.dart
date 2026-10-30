import 'package:content/content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progress/progress_repository.dart';

/// How a room on the Tower looks (FR-31; Duolingo's path: done, START, locked).
enum RoomState {
  /// Played at least once: a lit window with the best score stamped on it. Replayable.
  done,

  /// The next mission to play: glowing, with "Enter".
  current,

  /// Not yet: dark, a lock, and the title as a teaser.
  locked,
}

/// One playable mission as a room.
class TowerRoom {
  const TowerRoom({required this.mission, required this.state, this.best});

  final Mission mission;
  final RoomState state;

  /// The best total across the player's attempts; null until played.
  final int? best;

  bool get enterable => state != RoomState.locked;
}

/// The rooms of the playable missions, in campaign order, from the stored attempts. A mission
/// is done once it has any attempt (any score unlocks the next); the first one not done is
/// current; the rest are locked. Pure, so the Tower's states are tested without a screen.
List<TowerRoom> towerRooms(
  List<Mission> missions,
  List<AttemptRecord> attempts,
) {
  final best = <String, int>{};
  for (final a in attempts) {
    final previous = best[a.missionId];
    if (previous == null || a.score.total > previous) {
      best[a.missionId] = a.score.total;
    }
  }
  final rooms = <TowerRoom>[];
  var currentGiven = false;
  for (final m in missions) {
    final RoomState state;
    if (best.containsKey(m.id)) {
      state = RoomState.done;
    } else if (!currentGiven) {
      state = RoomState.current;
      currentGiven = true;
    } else {
      state = RoomState.locked;
    }
    rooms.add(TowerRoom(mission: m, state: state, best: best[m.id]));
  }
  return rooms;
}

/// The Tower's rooms, from the progress store. Invalidated when the Tower opens, so a finished
/// mission shows lit.
final towerRoomsProvider = FutureProvider.autoDispose<List<TowerRoom>>((
  ref,
) async {
  final attempts = await ref.read(progressRepositoryProvider).attempts();
  return towerRooms(missions, attempts);
});
