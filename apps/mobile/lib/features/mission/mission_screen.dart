import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../ui/film_kit.dart';
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
    final attempt = ref.watch(missionControllerProvider(number));
    return switch (attempt) {
      // A mission left part-way: continue it, or start again.
      AsyncData(:final value) when value.saved != null => Stack(
        fit: StackFit.expand,
        children: [
          const _DarkRoom(),
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
      AsyncData() => MissionPlayer(
        key: ValueKey(number),
        number: number,
        // The Tower lights this room and shows the next one glowing (brief 13).
        onExit: () => context.go(Routes.tower(lit: number)),
        onLeave: () => context.go(Routes.tower()),
      ),
      AsyncError(:final error, :final stackTrace) => _LockedDoor(
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

/// Loading: the room before the lamp is fully on.
class _DarkRoom extends StatelessWidget {
  const _DarkRoom();

  static const double _lampWidth = 96;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: BrandVivid.night,
    child: Center(
      child: Semantics(
        label: 'The room is being prepared',
        child: const SizedBox(width: _lampWidth, child: BankersLamp()),
      ),
    ),
  );
}

/// The error state: a door that won't open, in the film's language. Never the exception's
/// text; that goes to the log.
class _LockedDoor extends StatefulWidget {
  const _LockedDoor({required this.onLog});

  final VoidCallback onLog;

  static const String title = 'THIS ROOM IS LOCKED';
  static const String line =
      'Something went wrong setting the scene. Your progress is safe on this device.';
  static const String back = 'Back to the tower';

  @override
  State<_LockedDoor> createState() => _LockedDoorState();
}

class _LockedDoorState extends State<_LockedDoor> {
  @override
  void initState() {
    super.initState();
    widget.onLog();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const VividBackdrop(),
      SafeArea(
        minimum: const EdgeInsets.all(BrandSpace.lg),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    _LockedDoor.title,
                    textAlign: TextAlign.center,
                    style: BrandVividType.kicker.copyWith(
                      color: ChapterGrade.lobby.glow,
                    ),
                  ),
                ),
                const SizedBox(height: BrandSpace.md),
                const Text(
                  _LockedDoor.line,
                  textAlign: TextAlign.center,
                  style: BrandVividType.title,
                ),
                const SizedBox(height: BrandSpace.lg),
                VividButton(
                  label: _LockedDoor.back,
                  onPressed: () => context.go(Routes.tower()),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// The first mission, where a new player starts after the intro.
int get firstMissionNumber => missions.first.number;
