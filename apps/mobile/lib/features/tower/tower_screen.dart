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
import '../mission/widgets/cue_button.dart';
import 'elevator.dart';
import 'room_window.dart';
import 'tower_rooms.dart';

/// Home (FR-31, brief §9 "the building"): a tall tower at night. Chapter 1's seven rooms at the
/// bottom, climbing up; Chapters 2 and 3 as dark floors above with their titles; the last room
/// at the top, always in sight. Finished rooms are lit with their best score, the next one
/// glows with "Enter", the rest are locked. [lit] is the mission just finished: its window
/// lights up as the Tower opens (the reward moment).
class TowerScreen extends ConsumerStatefulWidget {
  const TowerScreen({super.key, this.lit});

  final int? lit;

  static const String eyebrow = 'THE TOWER';
  static const String progress = 'Your file';
  static const String lastRoom = 'The Last Room';
  static const String lastRoomLine = 'The offer is decided here.';
  static const String recallRoom = 'Recall Room';
  static const String comingSoon = 'Coming soon';
  static const String floorLocked = 'Locked';

  static String greeting(String name) => 'Good evening, $name.';
  static String lockedNotice(Mission before) =>
      'Finish “${before.title}” to open this room.';
  static String litNotice(Mission m) => 'Room ${m.number} is lit.';

  @override
  ConsumerState<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends ConsumerState<TowerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: BrandMotion.dolly,
  );
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
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 1;
      _lighting.value = 1;
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _pulse.dispose();
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
    // A brand-new player meets their practice CV before the first room.
    final firstEver =
        room.mission.number == missions.first.number &&
        room.state == RoomState.current;
    context.go(
      firstEver ? Routes.character : Routes.mission(room.mission.number),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(towerRoomsProvider);
    final name =
        ref.watch(profileProvider).value?.displayName ??
        PlayerProfile.fallbackName;
    const grade = ChapterGrade.lobby;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [BrandColors.void_, grade.shadow, grade.tint],
              stops: const [0, 0.7, 1],
            ),
          ),
        ),
        FilmOverlay(
          grain: 0,
          vignetteColor: grade.shadow,
          child: Opacity(
            opacity: 0.35,
            child: Bokeh(colors: [grade.key, BrandColors.textPrimary], seed: 7),
          ),
        ),
        switch (rooms) {
          AsyncData(:final value) => _Facade(
            rooms: value,
            name: name,
            pulse: _pulse,
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

class _Facade extends StatefulWidget {
  const _Facade({
    required this.rooms,
    required this.name,
    required this.pulse,
    required this.lighting,
    required this.lit,
    required this.onReady,
    required this.onTapRoom,
    required this.onProgress,
  });

  final List<TowerRoom> rooms;
  final String name;
  final Animation<double> pulse;
  final Animation<double> lighting;
  final int? lit;
  final VoidCallback onReady;
  final ValueChanged<TowerRoom> onTapRoom;
  final VoidCallback onProgress;

  @override
  State<_Facade> createState() => _FacadeState();
}

class _FacadeState extends State<_Facade> {
  final GlobalKey _focusRoom = GlobalKey();

  static const double _maxWidth = 460;
  static const int _greetingLines = 2;
  static const double _hairline = 0.8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onReady();
      // Bring the room that matters into view: the one just lit, else the current one.
      final target = _focusRoom.currentContext;
      if (target != null) {
        unawaited(Scrollable.ensureVisible(target, alignment: 0.5));
      }
    });
  }

  int? get _focusNumber {
    if (widget.lit != null) return widget.lit;
    for (final r in widget.rooms) {
      if (r.state == RoomState.current) return r.mission.number;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    final chapterOne = chapters.first;
    final focus = _focusNumber;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BrandSpace.lg,
              BrandSpace.sm,
              BrandSpace.sm,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wraps at 2x text rather than squeezing the button.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      TowerScreen.eyebrow,
                      style: BrandType.eyebrow.copyWith(color: grade.key),
                    ),
                    CueButton(
                      label: TowerScreen.progress,
                      quiet: true,
                      onPressed: widget.onProgress,
                    ),
                  ],
                ),
                Semantics(
                  header: true,
                  child: Text(
                    TowerScreen.greeting(widget.name),
                    maxLines: _greetingLines,
                    overflow: TextOverflow.ellipsis,
                    style: BrandType.subtitle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              padding: const EdgeInsets.all(BrandSpace.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Penthouse(),
                      for (final chapter in chapters.reversed.where(
                        (c) => !c.playable,
                      ))
                        _DarkFloor(chapter: chapter),
                      _FloorFrame(
                        grade: grade,
                        title: 'CHAPTER ${chapterOne.number}',
                        subtitle: chapterOne.title,
                        child: Column(
                          children: [
                            for (final room in widget.rooms.reversed)
                              AnimatedBuilder(
                                key: room.mission.number == focus
                                    ? _focusRoom
                                    : null,
                                animation: Listenable.merge([
                                  widget.pulse,
                                  widget.lighting,
                                ]),
                                builder: (context, _) => RoomWindow(
                                  room: room,
                                  grade: room.mission.grade,
                                  pulse: widget.pulse.value,
                                  lighting: room.mission.number == widget.lit
                                      ? widget.lighting.value
                                      : 1,
                                  onTap: () => widget.onTapRoom(room),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const _Lobby(),
                    ],
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

/// One floor of the facade: a brass-edged band with its title.
class _FloorFrame extends StatelessWidget {
  const _FloorFrame({
    required this.grade,
    required this.title,
    required this.subtitle,
    required this.child,
    this.dim = false,
  });

  final ChapterGrade grade;
  final String title;
  final String subtitle;
  final Widget child;
  final bool dim;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: BrandColors.surface.withValues(alpha: dim ? 0.7 : 0.9),
      border: Border.all(
        color: grade.key.withValues(alpha: dim ? 0.15 : 0.4),
        width: _FacadeState._hairline,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(BrandSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              '$title · ${subtitle.toUpperCase()}',
              style: BrandType.label.copyWith(
                color: dim ? BrandColors.textSecondary : grade.key,
              ),
            ),
          ),
          const SizedBox(height: BrandSpace.sm),
          child,
        ],
      ),
    ),
  );
}

/// A locked chapter: dark windows, the titles of its missions as a teaser (FR-31).
class _DarkFloor extends StatelessWidget {
  const _DarkFloor({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final grade = ChapterGrade.values[chapter.number - 1];
    return _FloorFrame(
      grade: grade,
      dim: true,
      title: 'CHAPTER ${chapter.number}',
      subtitle: chapter.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const LockGlyph(color: BrandColors.textSecondary),
              const SizedBox(width: BrandSpace.sm),
              Text(
                TowerScreen.floorLocked.toUpperCase(),
                style: BrandType.label.copyWith(
                  color: BrandColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BrandSpace.xs),
          Text(
            chapter.missionTitles.join('  ·  '),
            style: BrandType.body.copyWith(
              color: BrandColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// The top of the tower: the last room, always in sight, always out of reach (for now).
class _Penthouse extends StatelessWidget {
  const _Penthouse();

  static const double _lampWidth = 48;

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.finalRound;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BrandSpace.xl),
      child: _FloorFrame(
        grade: grade,
        title: 'THE TOP FLOOR',
        subtitle: TowerScreen.lastRoom,
        child: Column(
          children: [
            const SizedBox(
              width: _lampWidth,
              child: BankersLamp(grade: grade, lit: false),
            ),
            const SizedBox(height: BrandSpace.sm),
            Text(
              TowerScreen.lastRoomLine,
              textAlign: TextAlign.center,
              style: BrandType.body.copyWith(color: BrandColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ground floor: the Recall Room's door, not open yet.
class _Lobby extends StatelessWidget {
  const _Lobby();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BrandSpace.sm),
    child: Semantics(
      label: '${TowerScreen.recallRoom}, ${TowerScreen.comingSoon}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LockGlyph(color: BrandColors.textSecondary),
          const SizedBox(width: BrandSpace.sm),
          Flexible(
            child: Text(
              '${TowerScreen.recallRoom.toUpperCase()} · ${TowerScreen.comingSoon.toUpperCase()}',
              style: BrandType.label.copyWith(color: BrandColors.textSecondary),
            ),
          ),
        ],
      ),
    ),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BrandColors.surfaceRaised,
              border: Border.all(color: ChapterGrade.lobby.key),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BrandSpace.md),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: BrandType.body,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
