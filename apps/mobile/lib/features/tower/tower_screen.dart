import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/back_to_exit.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../core/notifications/reminder_primer.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/daylight/daylight_route.dart';
import '../../ui/daylight/daylight_sheet.dart';
import '../../ui/haptics.dart';
import '../mission/mission_lookup.dart';
import '../progression/progression.dart';
import '../progression/skills_shelf.dart';
import '../recall/recall_controller.dart';
import '../tips/tip_overlay.dart';
import '../tips/tips.dart';
import 'elevator.dart';
import 'floor_sheet.dart';
import 'northstar_tower.dart';
import 'tower_door.dart' show PlayCue;
import 'tower_extras.dart';
import 'tower_header.dart';
import 'tower_hero.dart';
import 'tower_rooms.dart';
import 'welcome_back.dart';
import 'welcome_back_card.dart';

/// Home (FR-31; Daylight Tower in brief 46, direction.md §1): on paper, top to bottom, the
/// date, the greeting and the weekly ring; XP and the interview countdown; the welcome-back
/// card after a day away; the Recall card; the up-next card with one button (one tap starts
/// the room); Northstar tower, the illustration that is the progress bar; the skills shelf.
/// The floating tab bar (Tower, Recall, Skills, You) sits over the bottom. [lit] is the
/// mission just finished: its window fills with honey as the tower opens (motion 5).
class TowerScreen extends ConsumerStatefulWidget {
  const TowerScreen({super.key, this.lit});

  final int? lit;

  /// The tab bar's labels. "Skills" opens the player's file (the skills, the scores, the
  /// report); "You" opens Settings.
  static const String towerTab = 'Tower';
  static const String recallTab = 'Recall';
  static const String progress = 'Skills';
  static const String settingsTab = 'You';
  static const String towerTitle = 'Northstar tower';

  /// By the hour on the player's clock ("Morning, Sami.").
  static String greeting(String name, int hour) =>
      TowerHeader.greeting(name, hour);
  static String lockedNotice(Mission before) =>
      'Finish “${before.title}” to open this room.';
  static String litNotice(Mission m) => 'Room ${m.number} is lit.';
  static String weekClosed(int goal) =>
      'Your week is done: $goal of $goal. Anything more is a bonus.';

  @override
  ConsumerState<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends ConsumerState<TowerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lighting = AnimationController(
    vsync: this,
    duration: _lightUp,
    value: widget.lit == null ? 1 : 0,
  );

  late final GameSounds _sounds = ref.read(gameSoundsProvider);
  bool _opened = false;

  /// The rooms once loaded, kept so the tower can open when it next becomes the visible route.
  List<TowerRoom>? _loaded;
  TowerRoom? _riding;

  /// The ride has arrived and the room is opening: the lift stays shut under the room's door
  /// transition (brief 50) until the tower is on top again.
  bool _departed = false;
  String? _notice;
  Timer? _noticeTimer;

  static const Duration _noticeHold = Duration(milliseconds: 3200);

  /// Motion 5: the window fills (700 ms), the ring flares (500 ms), the check lands.
  static const Duration _lightUp = Duration(milliseconds: 1200);

  /// Where the door to play is scrolled to under the tour: mid-screen, or near the top when
  /// the text is large (above [_largeText]).
  static const double _doorMiddle = 0.5;
  static const double _doorHigh = 0.12;
  static const double _largeText = 1.3;

  /// The week's sessions the tower last showed, so a mission that closes the week is seen as
  /// it happens (motion 6) and `weekly_goal_closed` fires once.
  int? _seenSessions;
  bool _weekJustClosed = false;

  void _say(String notice) {
    _noticeTimer?.cancel();
    setState(() => _notice = notice);
    _noticeTimer = Timer(_noticeHold, () {
      if (mounted) setState(() => _notice = null);
    });
  }

  /// Kept from the start: `dispose` hands back a tip still up, when `ref` can't be read.
  late final TipsController _tips = ref.read(tipsProvider.notifier);

  @override
  void initState() {
    super.initState();
    _tips;
    ref.invalidate(towerRoomsProvider);
  }

  /// The tips' targets: the door to play, the Recall tab, the Skills tab.
  final GlobalKey _nextDoor = GlobalKey();
  final GlobalKey _recallTab = GlobalKey();
  final GlobalKey _skillsTab = GlobalKey();

  /// The tip on screen and where its target is; one per visit at most, never a queue of them.
  Tip? _tip;
  Rect? _tipAt;
  bool _placing = false;
  bool _tipThisVisit = false;

  /// The reminder explainer may still come (back from room 1): no tip until it has.
  bool _primerPending = false;

  /// The tip due now, if nothing else is: no welcome-back card, no reminder explainer to come,
  /// no notice over the tab bar, no ride, the tower on top. In order: the door to play (not on a
  /// return from a room), the player's file once a room is played, then a Recall note due.
  Tip? _tipDue(
    List<TowerRoom>? rooms, {
    required bool welcomeUp,
    required int recallDue,
  }) {
    final tips = ref.read(tipsProvider);
    if (!tips.loaded ||
        rooms == null ||
        welcomeUp ||
        _riding != null ||
        !_isCurrent) {
      return null;
    }
    if (_tip case final up?) return up;
    if (_tipThisVisit || _primerPending || _notice != null) return null;
    final played = rooms.any((r) => r.state == RoomState.done);
    if (tips.due(Tip.towerDoor) &&
        widget.lit == null &&
        rooms.any((r) => r.state == RoomState.current)) {
      return Tip.towerDoor;
    }
    if (tips.due(Tip.yourFile) && played) return Tip.yourFile;
    if (tips.due(Tip.recallDue) && recallDue > 0) return Tip.recallDue;
    return null;
  }

  /// Brings [tip]'s target into view (the door scrolls; the tabs are always there), measures it
  /// for the spotlight, and puts the tip up. A target that isn't on screen skips the tip.
  void _placeTip(Tip tip) {
    if (_placing || _tip != null) return;
    _placing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Measure where the target rests, once the tower has arrived (brief 50's transitions).
      if (!mounted) return;
      await routeSettled(context);
      final key = switch (tip) {
        Tip.recallDue => _recallTab,
        Tip.yourFile => _skillsTab,
        _ => _nextDoor,
      };
      final target = key.currentContext;
      if (!mounted || target == null || !target.mounted) {
        _placing = false;
        return;
      }
      if (tip == Tip.towerDoor) {
        // Large text makes the bubble tall: the door goes near the top so the bubble has the
        // screen below it, "Got it" in view.
        final large = MediaQuery.textScalerOf(context).scale(1) > _largeText;
        await Scrollable.ensureVisible(
          target,
          alignment: large ? _doorHigh : _doorMiddle,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : DaylightMotion.move,
          curve: DaylightMotion.ease,
        );
        if (!mounted) return;
      }
      _placing = false;
      final at = tipTarget(key, context);
      if (at == null || !_tips.shown(tip)) {
        _tipThisVisit = true;
        return;
      }
      setState(() {
        _tip = tip;
        _tipThisVisit = true;
        // The door's spotlight takes in the play cue over it too.
        _tipAt = tip == Tip.towerDoor
            ? Rect.fromLTRB(
                at.left,
                at.top - PlayCue.size - DaylightSpace.s4,
                at.right,
                at.bottom,
              )
            : at;
      });
    });
  }

  void _endTip(TipAction action) {
    final tip = _tip;
    if (tip == null) return;
    setState(() {
      _tip = null;
      _tipAt = null;
    });
    unawaited(_tips.done(tip, action));
  }

  /// Whether the tower was the route on top at the last dependency change.
  bool _wasCurrent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _lighting.value = 1;
    // Back on top by any way at all (a mission's end, the report, the Recall Room, the file,
    // back): the rooms and the due cards are read again, so "up next", the chapter count and
    // the Recall Room never show what was true before (brief 30's playthrough).
    final current = _isCurrent;
    if (current && !_wasCurrent) {
      // Back from the room: the lift that took the player there is gone.
      if (_departed) {
        _riding = null;
        _departed = false;
      }
      // A new visit: it may bring a tip of its own.
      _tipThisVisit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
          ..invalidate(towerRoomsProvider)
          ..invalidate(recallDueCountProvider);
      });
    }
    _wasCurrent = current;
    // Depends on the route's status: runs again when a child (a mission, the file) is popped
    // and the tower is on top once more.
    if (_isCurrent && _loaded != null && !_opened) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(_loaded!));
    }
  }

  @override
  void didUpdateWidget(TowerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Back from a finished mission (`/tower?lit=N`): the same tower, now lighting room N.
    if (widget.lit != oldWidget.lit && widget.lit != null) {
      _opened = false;
      _tipThisVisit = false;
      _loaded = null;
      if (!MediaQuery.disableAnimationsOf(context)) _lighting.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(towerRoomsProvider);
      });
    }
  }

  /// Under a mission or the file (the tower's children) the tower is built but not seen: it
  /// opens (event, sound, reward) only when it's the route on top.
  bool get _isCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  @override
  void dispose() {
    if (_tip case final tip?) _tips.release(tip);
    _noticeTimer?.cancel();
    _lighting.dispose();
    super.dispose();
  }

  /// Once the rooms are known: the event, the sound, and the reward moment.
  void _open(List<TowerRoom> rooms) {
    _loaded = rooms;
    if (_opened || !mounted || !_isCurrent) return;
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
    if (widget.lit == 1) {
      // The explainer comes after the room lights up; the tips wait for it to be answered.
      _primerPending = true;
      unawaited(
        offerReminders(context, ref).whenComplete(() {
          if (mounted) setState(() => _primerPending = false);
        }),
      );
    }
  }

  /// The week's ring as the tower sees it: when a finished session takes it to the goal, the
  /// ring closes with its sparks and the event fires, once.
  void _watchWeek(Progression? p) {
    if (p == null) return;
    final before = _seenSessions;
    _seenSessions = p.sessionsThisWeek;
    if (before == null || before >= p.weeklyGoal || !p.goalMet) return;
    successTap();
    setState(() => _weekJustClosed = true);
    _say(TowerScreen.weekClosed(p.weeklyGoal));
    ref.read(analyticsProvider).track(AnalyticsEvent.weeklyGoalClosed, {
      'sessions': EventValue.count(p.sessionsThisWeek),
      'weekly_goal': EventValue.count(p.weeklyGoal),
    });
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

  /// A floor opened from the facade: its rooms, interviewers and how it's answered, open or
  /// not yet (the owner: "show the other chapters which are locked").
  Future<void> _showFloor(Chapter chapter, List<TowerRoom> rooms) async {
    if (_riding != null) return;
    _sounds.uiTap();
    final floor = [
      for (final r in rooms)
        if (r.mission.chapter == chapter.number) r,
    ];
    ref.read(analyticsProvider).track(AnalyticsEvent.floorPreviewed, {
      'chapter': EventValue.count(chapter.number),
      'open': EventValue.flag(floor.any((r) => r.state != RoomState.locked)),
    });
    TowerRoom? chosen;
    await showDaylightSheet<void>(
      context,
      label: NorthstarTower.floorLine(chapter),
      builder: (sheet) => FloorSheet(
        chapter: chapter,
        rooms: floor,
        onRoom: (r) {
          chosen = r;
          Navigator.of(sheet).pop();
        },
      ),
    );
    final room = chosen;
    if (room != null && mounted) _tapRoom(room, rooms);
  }

  void _arrived() {
    final room = _riding;
    if (room == null || _departed || !mounted) return;
    _departed = true;
    // Straight into the room: one tap from the tower (brief 17), through its door (brief 50).
    context.go(Routes.mission(room.mission.number), extra: _doorOf(room));
  }

  /// Where [room] grows from: the door that was tapped, else (the up-next button, the tour)
  /// the next room's door when it's on screen; null leaves the route its default door.
  DoorOrigin? _doorOf(TowerRoom room) {
    if (DaylightPageRoute.takeDoor(context) case final tapped?) return tapped;
    if (room.state != RoomState.current) return null;
    final next = _nextDoor.currentContext;
    final door = next == null ? null : DoorOrigin.of(next);
    if (door == null) return null;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    return screen.overlaps(door.rect) ? door : null;
  }

  void _tab(int i) {
    switch (i) {
      case 1:
        context.go(Routes.recall);
      case 2:
        context.go(Routes.progress);
      case 3:
        context.go(Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The last rooms stay on screen while fresh ones load: a refresh never blanks the tower.
    final rooms = ref.watch(towerRoomsProvider).value;
    final recallDue = ref.watch(recallDueCountProvider).value ?? 0;
    final progression = ref.watch(progressionProvider).value;
    final welcomeUp = ref.watch(welcomeBackProvider) != null;
    ref.watch(tipsProvider);
    final due = _tipDue(rooms, welcomeUp: welcomeUp, recallDue: recallDue);
    if (due != null) _placeTip(due);
    final tip = due == null ? null : _tip;
    if (due == null && _tip != null) {
      // Something else came first (a ride, a card, another screen): the tip goes, unseen, and
      // comes back on a later visit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final up = _tip;
        if (!mounted || up == null) return;
        _tips.release(up);
        setState(() {
          _tip = null;
          _tipAt = null;
        });
      });
    }
    final tipAt = _tipAt;
    final name =
        ref.watch(profileProvider).value?.displayName ??
        PlayerProfile.fallbackName;
    ref.listen(progressionProvider, (_, next) => _watchWeek(next.value));
    final bottom = MediaQuery.paddingOf(context).bottom;
    return BackToExit(
      child: DaylightGround(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (rooms case final value?)
              _Tower(
                // A new `lit` replays the arrival: scroll to the room, then open.
                key: ValueKey(widget.lit),
                rooms: value,
                name: name,
                progression: progression,
                recallDue: recallDue,
                welcomeUp: welcomeUp,
                weekJustClosed: _weekJustClosed,
                lighting: _lighting,
                lit: widget.lit,
                onReady: () {
                  _seenSessions ??= progression?.sessionsThisWeek;
                  _open(value);
                },
                onTapRoom: (r) => _tapRoom(r, value),
                onFloor: (c) => unawaited(_showFloor(c, value)),
                nextDoorKey: _nextDoor,
              )
            else
              const _TowerLoading(),
            Positioned(
              left: DaylightSpace.s16,
              right: DaylightSpace.s16,
              bottom: bottom + DaylightSpace.s16,
              child: FloatingTabBar(
                current: 0,
                onSelect: _tab,
                items: [
                  const TabItem(
                    icon: PhosphorFill.buildings,
                    label: TowerScreen.towerTab,
                  ),
                  TabItem(
                    icon: PhosphorRegular.cards,
                    label: TowerScreen.recallTab,
                    badge: recallDue,
                    anchor: _recallTab,
                  ),
                  TabItem(
                    icon: PhosphorRegular.medal,
                    label: TowerScreen.progress,
                    anchor: _skillsTab,
                  ),
                  const TabItem(
                    icon: PhosphorRegular.userCircle,
                    label: TowerScreen.settingsTab,
                  ),
                ],
              ),
            ),
            if (_notice case final notice?)
              _Notice(key: ValueKey(notice), text: notice),
            if ((tip, tipAt) case (final tip?, final at?))
              TipOverlay(
                key: ValueKey(tip),
                voice: TipVoice.priya,
                line: switch (tip) {
                  Tip.towerDoor
                      when rooms!.any((r) => r.state == RoomState.done) =>
                    Tip.nextDoorLine,
                  Tip.recallDue => Tip.recallDueLine(
                    recallDue,
                    recallMinutes(recallDue),
                  ),
                  _ => tip.line,
                },
                target: at,
                shape: tip == Tip.towerDoor ? TipShape.arch : TipShape.card,
                onTarget: () => _endTip(TipAction.followed),
                onDismiss: () => _endTip(TipAction.dismissed),
              ),
            if (_riding case final room?)
              Elevator(
                floor: room.mission.number,
                grade: room.mission.grade,
                onArrived: _arrived,
              ),
          ],
        ),
      ),
    );
  }
}

class _Tower extends StatefulWidget {
  const _Tower({
    super.key,
    required this.rooms,
    required this.name,
    required this.progression,
    required this.recallDue,
    required this.welcomeUp,
    required this.weekJustClosed,
    required this.lighting,
    required this.lit,
    required this.onReady,
    required this.onTapRoom,
    required this.onFloor,
    this.nextDoorKey,
  });

  final ValueChanged<Chapter> onFloor;

  /// On the door to play, for its first-time tip.
  final Key? nextDoorKey;
  final List<TowerRoom> rooms;
  final String name;
  final Progression? progression;
  final int recallDue;

  /// The welcome-back card is up: it names the cards due, so the Recall card isn't repeated,
  /// and the up-next card leaves its question out to keep its button above the fold.
  final bool welcomeUp;
  final bool weekJustClosed;
  final Animation<double> lighting;
  final int? lit;
  final VoidCallback onReady;
  final ValueChanged<TowerRoom> onTapRoom;

  @override
  State<_Tower> createState() => _TowerState();
}

class _TowerState extends State<_Tower> {
  final GlobalKey _litFloor = GlobalKey();

  static const double _maxWidth = 520;

  /// The height from which the up-next card has room for the interviewer's question.
  static const double _tallEnough = 760;

  /// Two or more notes due: the Recall card goes above the up-next card.
  static const int _recallFirstAt = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onReady();
      // A just-finished room: the tower eases down to its floor (motion 5).
      final target = _litFloor.currentContext;
      if (target != null) {
        unawaited(
          Scrollable.ensureVisible(
            target,
            alignment: 0.5,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : DaylightMotion.move,
            curve: DaylightMotion.ease,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hero = heroRoom(widget.rooms);
    final p = widget.progression ?? Progression.empty;
    final done = widget.rooms.where((r) => r.state == RoomState.done).length;
    final showRecall = !(widget.welcomeUp && widget.recallDue > 0);
    final recallFirst = widget.recallDue >= _recallFirstAt;
    var i = 0;
    Widget enter(Widget child, {double gap = DaylightSpace.s16}) => Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Entrance(index: i++, child: child),
    );
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DaylightSpace.s16,
          DaylightSpace.s8,
          DaylightSpace.s16,
          FloatingTabBar.height +
              DaylightSpace.s48 +
              MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                enter(
                  TowerHeader(
                    name: widget.name,
                    progression: p,
                    firstVisit: done == 0,
                    weekJustClosed: widget.weekJustClosed,
                  ),
                ),
                WelcomeBackCard(quiet: widget.lit != null),
                if (showRecall && recallFirst) enter(const RecallRoomCard()),
                if (hero != null)
                  enter(
                    TowerHero(
                      room: hero,
                      // On a short screen the question waits for the room, so the button
                      // is above the tab bar on the first screen.
                      quiet:
                          widget.welcomeUp ||
                          MediaQuery.sizeOf(context).height < _tallEnough,
                      onPlay: () => widget.onTapRoom(hero),
                    ),
                  ),
                if (showRecall && !recallFirst)
                  enter(const RecallRoomCard(), gap: DaylightSpace.s24),
                if (!showRecall || recallFirst)
                  const SizedBox(height: DaylightSpace.s8),
                enter(
                  SectionHead(
                    title: TowerScreen.towerTitle,
                    aside: NorthstarTower.litCount(done, widget.rooms.length),
                  ),
                  gap: DaylightSpace.s12,
                ),
                enter(
                  AnimatedBuilder(
                    animation: widget.lighting,
                    builder: (context, _) => NorthstarTower(
                      rooms: widget.rooms,
                      lit: widget.lit,
                      lighting: widget.lighting.value,
                      litKey: _litFloor,
                      nextDoorKey: widget.nextDoorKey,
                      onTapRoom: widget.onTapRoom,
                      onFloor: widget.onFloor,
                    ),
                  ),
                  gap: DaylightSpace.s24,
                ),
                enter(SkillsShelf(unlocked: p.unlocked)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tower before its rooms are read: a skeleton shaped like the screen (the header, the
/// up-next card, the tower), in sand, never a spinner.
class _TowerLoading extends StatelessWidget {
  const _TowerLoading();

  static const double _greeting = 36;
  static const double _card = 200;
  static const double _tower = 300;

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
      label: 'Opening the tower',
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DaylightSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(DaylightSpace.s16, width: 140),
              const SizedBox(height: DaylightSpace.s8),
              block(_greeting, width: 220),
              const SizedBox(height: DaylightSpace.s64),
              block(_card, radius: DaylightRadius.panel),
              const SizedBox(height: DaylightSpace.s24),
              block(_tower, radius: DaylightRadius.panel),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line over the tab bar for a few seconds (the Tower clears it).
class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Positioned(
    left: DaylightSpace.s16,
    right: DaylightSpace.s16,
    bottom:
        MediaQuery.paddingOf(context).bottom +
        FloatingTabBar.height +
        DaylightSpace.s32,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? DaylightMotion.colour
            : DaylightMotion.move,
        curve: DaylightMotion.ease,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              0,
              MediaQuery.disableAnimationsOf(context)
                  ? 0
                  : (1 - t) * DaylightSpace.s8,
            ),
            child: child,
          ),
        ),
        child: Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DaylightColors.ink,
              borderRadius: BorderRadius.circular(DaylightRadius.card),
              boxShadow: DaylightElevation.lift,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DaylightSpace.s16,
                vertical: DaylightSpace.s12,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: DaylightType.body5.copyWith(
                  color: DaylightColors.raised,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
