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
import '../../core/profile/profile_repository.dart';
import '../../ui/film_kit.dart';
import '../mission/mission_lookup.dart';
import 'elevator.dart';
import 'tower_chapter_card.dart';
import 'tower_extras.dart';
import 'tower_hero.dart';
import 'tower_rooms.dart';

/// Home (FR-31, brief §9 "the building", rebuilt in brief 17): the evening sky over the city,
/// and on it, top to bottom: the mission to play next as a hero card with one "Play" (one tap
/// starts it), then the chapters 1, 2, 3 as cards in their own colours, Chapter 1's rooms
/// 1 → 7 inside, then the last room and the Recall Room. A pinned header (the greeting and
/// "Your file") sits on its own ground, so nothing scrolls through it. [lit] is the mission
/// just finished: its row lights up as the Tower opens (the reward moment).
class TowerScreen extends ConsumerStatefulWidget {
  const TowerScreen({super.key, this.lit});

  final int? lit;

  static const String eyebrow = 'THE TOWER';
  static const String progress = 'Your file';

  /// By the hour on the player's clock.
  static String greeting(String name, int hour) => hour < _noon
      ? 'Good morning, $name.'
      : hour < _evening
      ? 'Good afternoon, $name.'
      : 'Good evening, $name.';

  static const int _noon = 12;
  static const int _evening = 18;
  static String lockedNotice(Mission before) =>
      'Finish “${before.title}” to open this room.';
  static String litNotice(Mission m) => 'Room ${m.number} is lit.';

  @override
  ConsumerState<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends ConsumerState<TowerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lighting = AnimationController(
    vsync: this,
    duration: BrandMotion.cinematic,
    value: widget.lit == null ? 1 : 0,
  );

  late final GameSounds _sounds = ref.read(gameSoundsProvider);
  bool _opened = false;
  TowerRoom? _riding;
  String? _notice;
  Timer? _noticeTimer;

  static const Duration _noticeHold = Duration(milliseconds: 3200);

  void _say(String notice) {
    _noticeTimer?.cancel();
    setState(() => _notice = notice);
    _noticeTimer = Timer(_noticeHold, () {
      if (mounted) setState(() => _notice = null);
    });
  }

  @override
  void initState() {
    super.initState();
    ref.invalidate(towerRoomsProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _lighting.value = 1;
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _lighting.dispose();
    super.dispose();
  }

  /// Once the rooms are known: the event, the sound, and the reward moment.
  void _open(List<TowerRoom> rooms) {
    if (_opened) return;
    _opened = true;
    _sounds.towerOpened();
    ref.read(analyticsProvider).track(AnalyticsEvent.towerOpened, {
      'missions_done': EventValue.count(
        rooms.where((r) => r.state == RoomState.done).length,
      ),
      'after_mission': EventValue.flag(widget.lit != null),
    });
    final lit = widget.lit == null ? null : missionByNumber(widget.lit!);
    if (lit != null) {
      _say(TowerScreen.litNotice(lit));
      if (_lighting.value < 1) unawaited(_lighting.forward());
    }
  }

  void _tapRoom(TowerRoom room, List<TowerRoom> rooms) {
    if (_riding != null) return;
    _sounds.uiTap();
    if (!room.enterable) {
      _sounds.lockedRoomTapped();
      final i = rooms.indexOf(room);
      _say(TowerScreen.lockedNotice(rooms[i - 1].mission));
      return;
    }
    _sounds
      ..roomEntered()
      ..elevator();
    ref.read(analyticsProvider).track(AnalyticsEvent.roomEntered, {
      'mission_id': EventValue.id(room.mission),
      'replay': EventValue.flag(room.state == RoomState.done),
    });
    setState(() => _riding = room);
  }

  void _arrived() {
    final room = _riding;
    if (room == null || !mounted) return;
    _riding = null;
    // Straight into the room: one tap from the tower (brief 17).
    context.go(Routes.mission(room.mission.number));
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(towerRoomsProvider);
    final name =
        ref.watch(profileProvider).value?.displayName ??
        PlayerProfile.fallbackName;
    return Stack(
      fit: StackFit.expand,
      children: [
        const VividBackdrop(),
        switch (rooms) {
          AsyncData(:final value) => _Tower(
            rooms: value,
            name: name,
            lighting: _lighting,
            lit: widget.lit,
            onReady: () => _open(value),
            onTapRoom: (r) => _tapRoom(r, value),
            onProgress: () => context.go(Routes.progress),
          ),
          _ => const SizedBox.shrink(),
        },
        if (_notice case final notice?)
          _Notice(key: ValueKey(notice), text: notice),
        if (_riding case final room?)
          Elevator(
            floor: room.mission.number,
            grade: room.mission.grade,
            onArrived: _arrived,
          ),
      ],
    );
  }
}

class _Tower extends StatefulWidget {
  const _Tower({
    required this.rooms,
    required this.name,
    required this.lighting,
    required this.lit,
    required this.onReady,
    required this.onTapRoom,
    required this.onProgress,
  });

  final List<TowerRoom> rooms;
  final String name;
  final Animation<double> lighting;
  final int? lit;
  final VoidCallback onReady;
  final ValueChanged<TowerRoom> onTapRoom;
  final VoidCallback onProgress;

  @override
  State<_Tower> createState() => _TowerState();
}

class _TowerState extends State<_Tower> {
  final GlobalKey _litRow = GlobalKey();

  static const double _maxWidth = 520;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onReady();
      // A just-finished room scrolls into view; otherwise the hero card is already on top.
      final target = _litRow.currentContext;
      if (target != null) {
        unawaited(Scrollable.ensureVisible(target, alignment: 0.5));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hero = heroRoom(widget.rooms);
    var i = 0;
    Widget enter(Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: BrandSpace.md),
      child: StaggeredEntrance(index: i++, child: child),
    );
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(name: widget.name, onProgress: widget.onProgress),
          Expanded(
            child: _FadeUnderHeader(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  BrandSpace.md,
                  BrandSpace.md,
                  BrandSpace.md,
                  BrandSpace.lg + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hero != null)
                          enter(
                            TowerHero(
                              room: hero,
                              onPlay: () => widget.onTapRoom(hero),
                            ),
                          ),
                        for (final chapter in chapters)
                          enter(
                            AnimatedBuilder(
                              animation: widget.lighting,
                              builder: (context, _) => ChapterCard(
                                chapter: chapter,
                                rooms: [
                                  for (final r in widget.rooms)
                                    if (r.mission.chapter == chapter.number) r,
                                ],
                                lit: widget.lit,
                                lighting: widget.lighting.value,
                                litRowKey: _litRow,
                                onTapRoom: widget.onTapRoom,
                              ),
                            ),
                          ),
                        enter(const LastRoomCard()),
                        enter(const RecallRoomCard()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The greeting band: on its own ground (the top of the sky, opaque), so the cards scrolling
/// up pass beneath it instead of showing through the words.
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onProgress});

  final String name;
  final VoidCallback onProgress;

  static const int _greetingLines = 2;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    return ColoredBox(
      color: BrandVivid.skyTop,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.sm,
          BrandSpace.md,
          BrandSpace.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TowerScreen.eyebrow,
                    style: BrandVividType.kicker.copyWith(
                      color: BrandVivid.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Semantics(
                    header: true,
                    child: Text(
                      TowerScreen.greeting(name, hour),
                      maxLines: _greetingLines,
                      overflow: TextOverflow.ellipsis,
                      style: BrandVividType.title,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BrandSpace.sm),
            VividButton(
              label: TowerScreen.progress,
              primary: false,
              onPressed: onProgress,
            ),
          ],
        ),
      ),
    );
  }
}

/// The top of the scroll fades from the header's colour to clear, so a card slides under the
/// header softly and never with a hard cut through its words.
class _FadeUnderHeader extends StatelessWidget {
  const _FadeUnderHeader({required this.child});

  final Widget child;

  static const double _fade = BrandSpace.md;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: child),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: _fade,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandVivid.skyTop,
                  BrandVivid.skyTop.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// A line at the bottom of the frame for a few seconds (the Tower clears it).
class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Positioned(
    left: BrandSpace.lg,
    right: BrandSpace.lg,
    bottom: MediaQuery.paddingOf(context).bottom + BrandSpace.lg,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? BrandMotion.reducedMotionFade
            : BrandMotion.standard,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(BrandSpace.md),
            decoration: BoxDecoration(
              color: BrandVivid.night,
              borderRadius: BorderRadius.circular(BrandRadius.lg),
              border: Border.all(color: BrandVivid.accent, width: 1.5),
              boxShadow: BrandVivid.cardShadow,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: BrandVividType.row,
            ),
          ),
        ),
      ),
    ),
  );
}
