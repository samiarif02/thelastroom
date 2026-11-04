import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/daylight/daylight_route.dart';
import '../mission/mission_lookup.dart';
import 'chapter_section.dart';
import 'elevator.dart';
import 'room_entry.dart';
import 'tower_rooms.dart';

/// Every chapter, floor by floor (the owner, 4 Nov: "under Northstar tower there should be
/// 'View all chapters', and then a new view, chapter-wise"): the floor you're on opened, the
/// others folded to a strip of their doors. The rooms are the tower's own ([towerRoomsProvider])
/// so a room is played, next or locked here exactly when it is on the tower; an open room rides
/// the same lift and grows out of its door, a locked one says what opens it.
class AllChaptersScreen extends ConsumerStatefulWidget {
  const AllChaptersScreen({super.key});

  static const String kicker = 'Northstar tower';
  static const String title = 'All chapters';
  static const String back = 'Back to the tower';
  static String intro(int rooms, int floors) =>
      '$rooms rooms on $floors floors. Each room opens the next, and each floor the one above.';
  static const String trouble = 'The rooms didn’t load. Try again.';
  static const String retry = 'Try again';

  /// The floor that opens first: the one with the room to play, or the top once all are lit.
  static int currentChapter(List<TowerRoom> rooms) {
    for (final r in rooms) {
      if (r.state == RoomState.current) return r.mission.chapter;
    }
    return rooms.isEmpty ? 1 : rooms.last.mission.chapter;
  }

  @override
  ConsumerState<AllChaptersScreen> createState() => _AllChaptersScreenState();
}

class _AllChaptersScreenState extends ConsumerState<AllChaptersScreen> {
  late final GameSounds _sounds = ref.read(gameSoundsProvider);

  /// The floors opened, by number; set from the current floor once the rooms are read.
  Set<int>? _expanded;
  int? _note;
  TowerRoom? _riding;
  bool _departed = false;
  bool _tracked = false;

  static const double _maxWidth = 520;

  void _opened(List<TowerRoom> rooms) {
    if (_tracked) return;
    _tracked = true;
    final current = AllChaptersScreen.currentChapter(rooms);
    _expanded ??= {current};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvent.allChaptersOpened, {
        'missions_done': EventValue.count(
          rooms.where((r) => r.state == RoomState.done).length,
        ),
        'chapter': EventValue.count(current),
      });
    });
  }

  void _toggle(Chapter c) {
    _sounds.uiTap();
    setState(() {
      final open = _expanded ??= {};
      if (!open.remove(c.number)) open.add(c.number);
    });
  }

  void _tapRoom(TowerRoom room) {
    if (_riding != null) return;
    _sounds.uiTap();
    if (!room.enterable) {
      _sounds.lockedRoomTapped();
      setState(
        () => _note = _note == room.mission.number ? null : room.mission.number,
      );
      return;
    }
    announceRoomEntered(ref, room);
    setState(() {
      _note = null;
      _riding = room;
    });
  }

  /// The lift has arrived: into the room through the door that was tapped. The list stays
  /// under it, shut, so back from the room returns here.
  void _arrived() {
    final room = _riding;
    if (room == null || _departed || !mounted) return;
    _departed = true;
    final door = DaylightPageRoute.takeDoor(context);
    unawaited(
      context
          .push<void>(Routes.mission(room.mission.number), extra: door)
          .whenComplete(() {
            if (!mounted) return;
            setState(() {
              _riding = null;
              _departed = false;
            });
            ref.invalidate(towerRoomsProvider);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(towerRoomsProvider);
    final rooms = reading.value;
    if (rooms != null) _opened(rooms);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final List<Widget> body;
    if (rooms == null && reading.hasError) {
      body = [_Trouble(onRetry: () => ref.invalidate(towerRoomsProvider))];
    } else if (rooms == null) {
      body = [const _Skeleton()];
    } else {
      final open = _expanded ?? const <int>{};
      var i = 0;
      body = [
        Entrance(
          index: i++,
          child: Text(
            AllChaptersScreen.intro(rooms.length, chapters.length),
            style: DaylightType.body5.copyWith(color: DaylightColors.ink2),
          ),
        ),
        for (final c in chapters) ...[
          const SizedBox(height: DaylightSpace.s24),
          Entrance(
            index: i++,
            child: ChapterSection(
              chapter: c,
              rooms: [
                for (final r in rooms)
                  if (r.mission.chapter == c.number) r,
              ],
              expanded: open.contains(c.number),
              onToggle: () => _toggle(c),
              onRoom: _tapRoom,
              note: _note,
            ),
          ),
        ],
      ];
    }
    return DaylightGround(
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                DaylightTopBar(
                  leadingIcon: PhosphorBold.arrowLeft,
                  leadingLabel: AllChaptersScreen.back,
                  onLeading: () => context.go(Routes.tower()),
                  kicker: AllChaptersScreen.kicker,
                  title: AllChaptersScreen.title,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      DaylightSpace.s16,
                      DaylightSpace.s16,
                      DaylightSpace.s16,
                      DaylightSpace.s48 + bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: body,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_riding case final room?)
            Elevator(
              floor: room.mission.number,
              grade: room.mission.grade,
              onArrived: _arrived,
            ),
        ],
      ),
    );
  }
}

/// While the rooms read: three floors as sand shapes, never a spinner.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  static const double _line = 16;
  static const double _head = 48;
  static const double _row = 76;

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width, double radius = 8}) => SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DaylightColors.sand,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
    return Semantics(
      label: 'Opening the chapters',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(_line, width: 260),
          for (var floor = 0; floor < 3; floor++) ...[
            const SizedBox(height: DaylightSpace.s24),
            block(_head, radius: DaylightRadius.card),
            if (floor == 0)
              for (var r = 0; r < 3; r++) ...[
                const SizedBox(height: DaylightSpace.s8),
                block(_row, radius: DaylightRadius.card),
              ],
          ],
        ],
      ),
    );
  }
}

/// The rooms couldn't be read: say so, and offer to try again.
class _Trouble extends StatelessWidget {
  const _Trouble({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => DaylightPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AllChaptersScreen.trouble,
          style: DaylightType.body4.copyWith(color: DaylightColors.ink2),
        ),
        const SizedBox(height: DaylightSpace.s12),
        TactileButton(label: AllChaptersScreen.retry, onPressed: onRetry),
      ],
    ),
  );
}

/// Under the tower: the quiet way to every chapter at once, with how many rooms there are.
class AllChaptersLink extends StatelessWidget {
  const AllChaptersLink({super.key, required this.onTap});

  final VoidCallback onTap;

  static const String label = 'View all chapters';
  static String aside(int rooms, int floors) => '$rooms rooms · $floors floors';

  static const double _arrow = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final count = aside(missions.length, chapters.length);
    return Tactile(
      label: '$label, $count',
      onTap: onTap,
      style: TactileStyle(
        face: DaylightColors.raised,
        edge: DaylightColors.sand2,
        radius: BorderRadius.circular(DaylightRadius.card),
        depth: DaylightSize.edgeSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DaylightSpace.s16,
          vertical: DaylightSpace.s12,
        ),
        child: Row(
          children: [
            Icon(PhosphorBold.buildings, size: _arrow + 4, color: f.deep),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Wrap(
                spacing: DaylightSpace.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    label,
                    style: DaylightType.body2.copyWith(color: f.deep),
                  ),
                  Text(
                    count,
                    style: DaylightType.tabular(DaylightType.caption4)
                        .copyWith(color: DaylightColors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DaylightSpace.s8),
            Icon(PhosphorBold.arrowRight, size: _arrow, color: f.deep),
          ],
        ),
      ),
    );
  }
}
