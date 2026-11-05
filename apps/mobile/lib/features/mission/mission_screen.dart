import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/audio/game_sounds.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../voice/voice_controller.dart';
import '../voice/voice_player.dart';
import 'mission_controller.dart';
import 'mission_lookup.dart';
import 'mission_player.dart';
import 'scene/room_intro.dart';

/// The route for mission [number]: the scene once the attempt is ready, a dark room with the
/// lamp warming while it loads, and a locked door if it can't be played. Nothing here waits on
/// the network (NFR-4): an attempt loads from the device.
class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A room the tower hasn't opened yet (a deep link): say how it opens, never play it.
    final blocker = ref.watch(missionBlockerProvider(number));
    final mission = missionByNumber(
      number,
      catalog: ref.watch(missionCatalogProvider),
    );
    final loading = _DarkRoom(grade: mission?.grade ?? ChapterGrade.lobby);
    if (blocker.isLoading) return loading;
    if (blocker.value case final before?) {
      return _LockedDoor(
        title: _LockedDoor.notYetTitle,
        line: _LockedDoor.notYet(before),
      );
    }
    // A voice mission (brief 35) plays in the voice player: spoken lines, recorded answers.
    if (mission?.answerMode == AnswerMode.voice) {
      return switch (ref.watch(voiceControllerProvider(number))) {
        AsyncData() => VoicePlayer(
          key: ValueKey(number),
          number: number,
          onExit: () => context.go(
            _afterRoom(mission!, firstClear: _firstClear(ref, number)),
          ),
          onLeave: () => context.go(Routes.tower()),
        ),
        AsyncError(:final error, :final stackTrace) => _LockedDoor(
          title: _LockedDoor.brokenTitle,
          line: _LockedDoor.broken,
          onLog: () => ref
              .read(logProvider)
              .error(
                'voice mission failed to load',
                error: error,
                stackTrace: stackTrace,
              ),
        ),
        _ => loading,
      };
    }
    final attempt = ref.watch(missionControllerProvider(number));
    return switch (attempt) {
      // A mission left part-way: the room's intro, with Resume and Start over (issue 76).
      AsyncData(:final value) when value.saved != null => RoomIntro(
        mission: value.mission,
        calm: ref.watch(profileProvider).value?.calmMode ?? false,
        beatsDone: value.saved!.plays.length,
        onStart: () {
          ref.read(gameSoundsProvider).uiTap();
          ref.read(missionControllerProvider(number).notifier).resume();
        },
        onStartOver: () {
          ref.read(gameSoundsProvider).uiTap();
          unawaited(
            ref.read(missionControllerProvider(number).notifier).startAfresh(),
          );
        },
        onBack: () {
          ref.read(gameSoundsProvider).uiTap();
          context.go(Routes.tower());
        },
      ),
      AsyncData(:final value) => MissionPlayer(
        key: ValueKey(number),
        number: number,
        // The Tower lights this room and shows the next one glowing (brief 13); Chapter 1's
        // review opens its report instead (brief 24).
        onExit: () => context.go(
          _afterRoom(value.mission, firstClear: value.attemptNumber == 1),
        ),
        onLeave: () => context.go(Routes.tower()),
      ),
      AsyncError(:final error, :final stackTrace) => _LockedDoor(
        title: _LockedDoor.brokenTitle,
        line: _LockedDoor.broken,
        onLog: () => ref
            .read(logProvider)
            .error(
              'mission failed to load',
              error: error,
              stackTrace: stackTrace,
            ),
      ),
      _ => loading,
    };
  }
}

/// Where a finished room goes: the first clear of a floor's last room is celebrated (floor
/// cleared, brief 46, which leads on to Chapter 1's report); otherwise the tower, lighting the
/// room. A replay of the last room goes where it always did.
String _afterRoom(Mission mission, {required bool firstClear}) {
  if (mission.closesChapter && firstClear) {
    return Routes.floorCleared(mission.chapter);
  }
  return mission.leadsToReport
      ? Routes.report
      : Routes.tower(lit: mission.number);
}

/// Whether the voice attempt being played is the room's first.
bool _firstClear(WidgetRef ref, int number) =>
    ref.read(voiceControllerProvider(number)).value?.attemptNumber == 1;

/// Loading: the room's intro in sand shapes, on the floor's tint, before it fills in (a
/// skeleton shaped like what arrives, never a spinner). It's what the door opens onto for the
/// moment the attempt takes to read from the device.
class _DarkRoom extends StatelessWidget {
  const _DarkRoom({this.grade = ChapterGrade.lobby});

  final ChapterGrade grade;

  static const double _arch = 112;
  static const double _archHeight = 136;
  static const double _line = 16;
  static const double _title = 28;
  static const double _panel = 184;
  static const double _short = 120;
  static const double _long = 240;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    Widget block(
      double height,
      Color color, {
      double? width,
      BorderRadius? radius,
    }) => SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius ?? BorderRadius.circular(DaylightRadius.tile),
        ),
      ),
    );
    return DaylightGround(
      color: f.tint,
      floor: f,
      child: Semantics(
        label: 'The room is being prepared',
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              DaylightSpace.s24,
              DaylightSpace.s64,
              DaylightSpace.s24,
              DaylightSpace.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(
                  _archHeight,
                  f.soft,
                  width: _arch,
                  radius: DaylightRadius.arch,
                ),
                const SizedBox(height: DaylightSpace.s16),
                block(_line, f.soft, width: _short),
                const SizedBox(height: DaylightSpace.s8),
                block(_title, f.soft, width: _long),
                const SizedBox(height: DaylightSpace.s24),
                block(
                  _panel,
                  DaylightColors.raised,
                  radius: BorderRadius.circular(DaylightRadius.panel),
                ),
                const SizedBox(height: DaylightSpace.s24),
                block(
                  DaylightSize.button,
                  f.soft,
                  radius: BorderRadius.circular(DaylightRadius.card),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The error state: a door that won't open, said calmly. Never the exception's text; that goes
/// to the log.
class _LockedDoor extends StatefulWidget {
  const _LockedDoor({required this.title, required this.line, this.onLog});

  final String title;
  final String line;

  /// Logs the error behind a broken room; null for a room that's simply not open yet.
  final VoidCallback? onLog;

  static const String brokenTitle = 'This room is locked';
  static const String broken =
      'Something went wrong setting the scene. Your progress is safe on this device.';
  static const String notYetTitle = 'This room is still locked';
  static String notYet(Mission before) =>
      'Finish “${before.title}” to open this room.';
  static const String back = 'Back to the tower';

  @override
  State<_LockedDoor> createState() => _LockedDoorState();
}

class _LockedDoorState extends State<_LockedDoor> {
  static const double _tile = 56;
  static const double _glyph = 28;

  @override
  void initState() {
    super.initState();
    widget.onLog?.call();
  }

  @override
  Widget build(BuildContext context) => DaylightGround(
    child: SafeArea(
      minimum: const EdgeInsets.all(DaylightSpace.s24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _tile,
                height: _tile,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DaylightColors.sand,
                  borderRadius: BorderRadius.circular(DaylightRadius.card),
                ),
                child: const Icon(
                  PhosphorBold.lockSimple,
                  size: _glyph,
                  color: DaylightColors.ink2,
                ),
              ),
              const SizedBox(height: DaylightSpace.s16),
              Semantics(
                header: true,
                child: Text(widget.title, style: DaylightType.heading5),
              ),
              const SizedBox(height: DaylightSpace.s8),
              Text(
                widget.line,
                style: DaylightType.body3.copyWith(color: DaylightColors.ink2),
              ),
              const SizedBox(height: DaylightSpace.s24),
              TactileButton(
                label: _LockedDoor.back,
                icon: PhosphorBold.buildings,
                onPressed: () => context.go(Routes.tower()),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The first mission, where a new player starts after the intro.
int get firstMissionNumber => missions.first.number;
