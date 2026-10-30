import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/audio/audio_settings_section.dart';
import '../audio_providers.dart';
import '../audio_service.dart';
import '../cue.dart';
import 'sound_board_typing.dart';
import 'sound_board_widgets.dart';

/// `/dev/sound`: every cue, the typing voices, the room tones and their cross-fade, the duck,
/// and the settings. The owner approves the sound set by ear here (brief 09). Debug and profile
/// builds only.
class SoundBoardScreen extends ConsumerStatefulWidget {
  const SoundBoardScreen({super.key});

  static const String heading = 'Sound board';

  @override
  ConsumerState<SoundBoardScreen> createState() => _SoundBoardScreenState();
}

class _SoundBoardScreenState extends ConsumerState<SoundBoardScreen> {
  final List<Timer> _sequence = [];

  // The elevator between missions, as brief 13 will play it: (seconds from the start, cue).
  static const List<(double, Cue)> _elevator = [
    (0, Cue.elevatorDoorsClose),
    (0.9, Cue.elevatorRide),
    (1.6, Cue.elevatorFloorTick),
    (2.2, Cue.elevatorFloorTick),
    (2.8, Cue.elevatorFloorTick),
    (3.9, Cue.elevatorChime),
    (4.6, Cue.elevatorDoorsOpen),
  ];

  static const List<Cue> _loops = [
    Cue.ambienceLobby,
    Cue.ambienceCorridor,
    Cue.ambienceBoardroom,
    Cue.recallPad,
  ];

  @override
  void dispose() {
    _cancelSequence();
    super.dispose();
  }

  void _cancelSequence() {
    for (final t in _sequence) {
      t.cancel();
    }
    _sequence.clear();
  }

  void _playSequence(AudioService audio, List<(double, Cue)> steps) {
    _cancelSequence();
    for (final (at, cue) in steps) {
      _sequence.add(
        Timer(
          Duration(milliseconds: (at * Duration.millisecondsPerSecond).round()),
          () => audio.play(cue),
        ),
      );
    }
  }

  // The board shows the service's state, which isn't a provider of its own: rebuild after acting.
  void _act(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioServiceProvider);
    final sounds = ref.watch(audioGameSoundsProvider);
    return ColoredBox(
      color: BrandColors.void_,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.lg,
            BrandSpace.xl,
            BrandSpace.lg,
            BrandSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('DEV · BRIEF 09', style: BrandType.label),
              const SizedBox(height: BrandSpace.sm),
              Semantics(
                header: true,
                child: const Text(
                  SoundBoardScreen.heading,
                  style: BrandType.display,
                ),
              ),
              const SizedBox(height: BrandSpace.sm),
              ValueListenableBuilder(
                valueListenable: audio.statusListenable,
                builder: (context, status, _) => _Status(status: status),
              ),
              const SizedBox(height: BrandSpace.xl),
              const BoardSection(
                title: 'SETTINGS',
                note: 'The section the Settings screen embeds. Defaults: on, ambience 35%, effects 60%.',
                child: AudioSettingsSection(),
              ),
              BoardSection(
                title: 'ROOM TONE',
                note: 'Switch rooms to hear the 1.5 s cross-fade. Duck drops the room 40%, as when a question lands.',
                child: BoardButtons(
                  children: [
                    for (final cue in _loops)
                      BoardButton(
                        label: cue.name,
                        active: audio.currentLoop == cue,
                        onTap: () => _act(() => audio.startLoop(cue)),
                      ),
                    BoardButton(
                      label: audio.isDucked ? 'Unduck' : 'Duck',
                      active: audio.isDucked,
                      onTap: () =>
                          _act(audio.isDucked ? audio.unduck : audio.duck),
                    ),
                    BoardButton(
                      label: 'Stop room',
                      onTap: () => _act(audio.stopAmbience),
                    ),
                  ],
                ),
              ),
              const BoardSection(
                title: 'TYPING VOICES',
                note: 'A tick every 2nd–3rd letter, ±6% pitch, max 18 a second, silent on spaces and punctuation, a softer tick on "…". Tap the line to complete it.',
                child: SoundBoardTyping(),
              ),
              BoardSection(
                title: 'MOMENTS',
                note: 'The mission player\'s calls (GameSounds), and the elevator as the tower will play it.',
                child: BoardButtons(
                  children: [
                    BoardButton(
                      label: 'Question lands',
                      onTap: () => _act(sounds.questionLands),
                    ),
                    BoardButton(
                      label: 'Answer locked',
                      onTap: () => _act(sounds.answerLocked),
                    ),
                    BoardButton(
                      label: 'Follow-up (Lena)',
                      onTap: () => _act(() => sounds.followUpChallenge('lena')),
                    ),
                    BoardButton(
                      label: 'Score stamped',
                      onTap: sounds.scoreStamped,
                    ),
                    BoardButton(
                      label: 'Elevator',
                      onTap: () => _playSequence(audio, _elevator),
                    ),
                    BoardButton(
                      label: 'Stop all',
                      onTap: () => _act(() {
                        _cancelSequence();
                        sounds.stopAll();
                      }),
                    ),
                  ],
                ),
              ),
              BoardSection(
                title: 'EVERY CUE',
                note: 'One button per Cue. Loops start as room tone (stop them above).',
                child: BoardButtons(
                  children: [
                    for (final cue in Cue.values)
                      BoardButton(
                        label: cue.name,
                        onTap: () => _act(() {
                          if (cue.loops) {
                            audio.startLoop(cue);
                          } else {
                            audio.play(cue);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});

  final AudioStatus status;

  static String describe(AudioStatus status) => switch (status) {
    AudioStatus.idle =>
      'Sound starts on your first tap (browsers block it until then).',
    AudioStatus.starting => 'Starting sound…',
    AudioStatus.ready => 'Sound is on. Every cue below plays.',
    AudioStatus.silent => 'Sound could not start on this device; the game plays silently (see the log).',
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      describe(status),
      style: BrandType.body.copyWith(color: BrandColors.textSecondary),
    );
  }
}
