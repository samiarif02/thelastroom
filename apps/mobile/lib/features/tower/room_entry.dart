import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import 'tower_rooms.dart';

/// The cues of stepping into an open room, the same from the tower and the chapters list: the
/// door and the lift sounds, and `room_entered`. The screen then rides its `Elevator` up.
void announceRoomEntered(WidgetRef ref, TowerRoom room) {
  ref.read(gameSoundsProvider)
    ..roomEntered()
    ..elevator();
  ref.read(analyticsProvider).track(AnalyticsEvent.roomEntered, {
    'mission_id': EventValue.id(room.mission),
    'replay': EventValue.flag(room.state == RoomState.done),
  });
}
