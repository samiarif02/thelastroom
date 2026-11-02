import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../../debrief/red_pen_slip.dart';
import '../widgets/voice_sheet.dart';
import 'take_recorder.dart';

/// The recorder in the lower third (brief 35): a large record button, a live level meter and
/// the elapsed time, and a designed line for every [RecorderPhase]. It draws [recorder]; the
/// recorder holds the take.
class RecorderPanel extends StatelessWidget {
  const RecorderPanel({
    super.key,
    required this.recorder,
    required this.onDone,
    required this.onWithoutMicrophone,
    this.grade = ChapterGrade.lobby,
  });

  final TakeRecorder recorder;

  /// "Done": the take is submitted.
  final ValueChanged<Take> onDone;

  /// No microphone (refused, or the player chose not to record): say it out loud, tick it after.
  final VoidCallback onWithoutMicrophone;
  final ChapterGrade grade;

  static const String explainTitle = 'Answer out loud';
  static const String explainLine =
      'Your microphone records your answer so the recruiter can score it. We score what you '
      'said, not how you sound, and the recording is never kept.';
  static const String allow = 'Allow the microphone';
  static const String withoutRecording = 'Answer without recording';
  static const String checking = 'Getting the microphone ready…';
  static const String asking =
      'Waiting for your answer to the microphone request…';
  static const String deniedTitle = 'No microphone';
  static const String deniedLine =
      "That's fine. Say your answer out loud anyway, then tick the points you made.";
  static const String deniedAction = 'Answer out loud, then tick';
  static const String readyLine = 'Tap the button and answer out loud.';
  static const String recordingLine = 'Recording. Tap to pause.';
  static const String silenceLine =
      "Paused: you went quiet. Continue when you're ready.";
  static const String pausedLine = 'Paused. Continue when you\'re ready.';
  static String fullLine(Duration cap) =>
      "That's the limit (${clock(cap)}). Submit it, or delete it and try again.";
  static const String done = 'Done';
  static const String resume = 'Continue';
  static const String delete = 'Delete';
  static const String recordLabel = 'Record your answer';
  static const String pauseLabel = 'Pause recording';
  static const String continueLabel = 'Continue recording';

  /// "1:05": minutes and seconds.
  static String clock(Duration d) {
    final seconds = d.inSeconds;
    return '${seconds ~/ Duration.secondsPerMinute}:'
        '${(seconds % Duration.secondsPerMinute).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: recorder,
    builder: (context, _) => PaperSlip(grade: grade, child: _body(context)),
  );

  Widget _body(BuildContext context) => switch (recorder.phase) {
    RecorderPhase.checking => const _Note(line: checking),
    RecorderPhase.asking => const _Note(line: asking),
    RecorderPhase.explain => _Ask(
      title: explainTitle,
      line: explainLine,
      primary: allow,
      onPrimary: () => unawaited(recorder.allow()),
      secondary: withoutRecording,
      onSecondary: onWithoutMicrophone,
    ),
    RecorderPhase.denied => _Ask(
      title: deniedTitle,
      line: deniedLine,
      primary: deniedAction,
      onPrimary: onWithoutMicrophone,
    ),
    _ => _Recording(recorder: recorder, grade: grade, onDone: onDone),
  };
}

/// One line while something outside the game happens (checking, the OS dialog).
class _Note extends StatelessWidget {
  const _Note({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      line,
      textAlign: TextAlign.center,
      style: BrandType.body.copyWith(color: SlipInk.text),
    ),
  );
}

/// A title, a line and one or two choices: the explainer and the refused state.
class _Ask extends StatelessWidget {
  const _Ask({
    required this.title,
    required this.line,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
  });

  final String title;
  final String line;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = this.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: BrandVividType.title,
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        Text(
          line,
          textAlign: TextAlign.center,
          style: BrandType.body.copyWith(color: SlipInk.text),
        ),
        const SizedBox(height: BrandSpace.md),
        VividButton(label: primary, expand: true, onPressed: onPrimary),
        if (secondary != null) ...[
          const SizedBox(height: BrandSpace.sm),
          VividButton(
            label: secondary,
            primary: false,
            expand: true,
            onPressed: onSecondary,
          ),
        ],
      ],
    );
  }
}

/// The recorder itself: the line for the state, the button, the meter, the time, the actions.
class _Recording extends StatelessWidget {
  const _Recording({
    required this.recorder,
    required this.grade,
    required this.onDone,
  });

  final TakeRecorder recorder;
  final ChapterGrade grade;
  final ValueChanged<Take> onDone;

  Future<void> _submit() async {
    final take = await recorder.submit();
    if (take != null) onDone(take);
  }

  String get _line => switch (recorder.phase) {
    RecorderPhase.recording => RecorderPanel.recordingLine,
    RecorderPhase.paused when recorder.pauseReason == PauseReason.silence =>
      RecorderPanel.silenceLine,
    RecorderPhase.paused => RecorderPanel.pausedLine,
    RecorderPhase.full => RecorderPanel.fullLine(recorder.maxLength),
    _ => RecorderPanel.readyLine,
  };

  @override
  Widget build(BuildContext context) {
    final phase = recorder.phase;
    final paused = phase == RecorderPhase.paused;
    final full = phase == RecorderPhase.full;
    final silence = paused && recorder.pauseReason == PauseReason.silence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            _line,
            textAlign: TextAlign.center,
            style: BrandType.body.copyWith(
              color: silence || full ? SlipInk.mark : SlipInk.text,
            ),
          ),
        ),
        const SizedBox(height: BrandSpace.md),
        Row(
          children: [
            if (!full)
              RecordButton(
                phase: phase,
                onPressed: () => unawaited(recorder.toggle()),
              ),
            if (!full) const SizedBox(width: BrandSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LevelMeter(level: recorder.level),
                  const SizedBox(height: BrandSpace.sm),
                  Semantics(
                    label:
                        '${RecorderPanel.clock(recorder.elapsed)} of '
                        '${RecorderPanel.clock(recorder.maxLength)}',
                    excludeSemantics: true,
                    child: Text(
                      '${RecorderPanel.clock(recorder.elapsed)} / '
                      '${RecorderPanel.clock(recorder.maxLength)}',
                      style: BrandVividType.row.copyWith(color: SlipInk.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (recorder.hasTake) ...[
          const SizedBox(height: BrandSpace.md),
          if (paused) ...[
            VividButton(
              label: RecorderPanel.resume,
              expand: true,
              onPressed: () => unawaited(recorder.resume()),
            ),
            const SizedBox(height: BrandSpace.sm),
          ],
          Row(
            children: [
              Expanded(
                child: VividButton(
                  label: RecorderPanel.delete,
                  primary: false,
                  expand: true,
                  onPressed: () => unawaited(recorder.askDelete()),
                ),
              ),
              const SizedBox(width: BrandSpace.sm),
              Expanded(
                child: VividButton(
                  label: RecorderPanel.done,
                  primary: !paused,
                  expand: true,
                  onPressed: recorder.canSubmit
                      ? () => unawaited(_submit())
                      : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The large record button: a red-pen dot to start, two bars while recording, the dot again
/// to continue. One labelled target, at least 72 pt.
class RecordButton extends StatelessWidget {
  const RecordButton({super.key, required this.phase, required this.onPressed});

  final RecorderPhase phase;
  final VoidCallback onPressed;

  static const double size = 76;
  static const double _dot = 26;
  static const double _bar = 8;
  static const double _barHeight = 26;
  static const double _ring = 3;

  bool get _recording => phase == RecorderPhase.recording;

  @override
  Widget build(BuildContext context) => Pressable(
    label: switch (phase) {
      RecorderPhase.recording => RecorderPanel.pauseLabel,
      RecorderPhase.paused => RecorderPanel.continueLabel,
      _ => RecorderPanel.recordLabel,
    },
    onTap: onPressed,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandVivid.night,
        border: Border.all(color: BrandVivid.accent, width: _ring),
        boxShadow: _recording
            ? BrandVivid.glowShadow(BrandVivid.horizon)
            : BrandVivid.cardShadow,
      ),
      alignment: Alignment.center,
      child: _recording
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Bar(),
                SizedBox(width: _bar),
                _Bar(),
              ],
            )
          : Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandVivid.horizon,
              ),
            ),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) => Container(
    width: RecordButton._bar,
    height: RecordButton._barHeight,
    decoration: BoxDecoration(
      color: BrandVivid.onDeep,
      borderRadius: BorderRadius.circular(BrandRadius.sm),
    ),
  );
}

/// The live level, as a bar that fills with the voice. Decorative for screen readers: the state
/// line says whether it's recording.
class LevelMeter extends StatelessWidget {
  const LevelMeter({super.key, required this.level});

  /// 0–1.
  final double level;

  static const double height = 10;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: BrandVivid.hairline(),
          borderRadius: BorderRadius.circular(BrandRadius.pill),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: level.clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              color: BrandVivid.accent,
              borderRadius: BorderRadius.circular(BrandRadius.pill),
            ),
          ),
        ),
      ),
    ),
  );
}

/// "Delete this take?": shown over the scene while [TakeRecorder.confirmingDelete].
class DeleteTakeSheet extends StatelessWidget {
  const DeleteTakeSheet({
    super.key,
    required this.recorder,
    this.grade = ChapterGrade.lobby,
  });

  final TakeRecorder recorder;
  final ChapterGrade grade;

  static const String title = 'Delete this take?';
  static const String line =
      'It\'s thrown away, and you start this answer again from the beginning.';
  static const String keep = 'Keep it';
  static const String delete = 'Delete';

  @override
  Widget build(BuildContext context) => VoiceSheet(
    title: title,
    line: line,
    primary: keep,
    onPrimary: recorder.cancelDelete,
    secondary: delete,
    onSecondary: () => unawaited(recorder.confirmDelete()),
    grade: grade,
  );
}
