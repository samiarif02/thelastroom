import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../voice/voice_controller.dart';
import '../voice/voice_player.dart';
import 'mission_controller.dart';
import 'mission_lookup.dart';
import 'mission_player.dart';
import 'widgets/scene_notes.dart';

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
    if (blocker.isLoading) return const _DarkRoom();
    if (blocker.value case final before?) {
      return _LockedDoor(
        title: _LockedDoor.notYetTitle,
        line: _LockedDoor.notYet(before),
      );
    }
    // A voice mission (brief 35) plays in the voice player: spoken lines, recorded answers.
    final mission = missionByNumber(
      number,
      catalog: ref.watch(missionCatalogProvider),
    );
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
        _ => const _DarkRoom(),
      };
    }
    final attempt = ref.watch(missionControllerProvider(number));
    return switch (attempt) {
      // A mission left part-way: continue it, or start again.
      AsyncData(:final value) when value.saved != null => Stack(
        fit: StackFit.expand,
        children: [
          _DarkRoom(grade: value.mission.grade),
          ResumeSheet(
            grade: value.mission.grade,
            onContinue: ref
                .read(missionControllerProvider(number).notifier)
                .resume,
            onRestart: () => ref
                .read(missionControllerProvider(number).notifier)
                .startAfresh(),
          ),
        ],
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
      _ => const _DarkRoom(),
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

/// Loading: the room's shape in the floor's colours before it fills in (a skeleton shaped
/// like the screen, never a spinner).
class _DarkRoom extends StatelessWidget {
  const _DarkRoom({this.grade = ChapterGrade.lobby});

  final ChapterGrade grade;

  static const double _bubble = 88;
  static const double _card = 72;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    Widget block(double height, Color color, double radius) => SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
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
              DaylightSpace.s16,
              DaylightSpace.s64,
              DaylightSpace.s16,
              DaylightSpace.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                block(RoomStage.defaultHeight, f.soft, DaylightRadius.panel),
                const SizedBox(height: DaylightSpace.s16),
                block(_bubble, DaylightColors.raised, DaylightRadius.card),
                const SizedBox(height: DaylightSpace.s24),
                for (var i = 0; i < 3; i++) ...[
                  block(_card, DaylightColors.raised, DaylightRadius.card),
                  const SizedBox(height: DaylightSpace.s8),
                ],
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
