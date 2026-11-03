import 'dart:async';
import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';
import '../widgets/voice_sheet.dart';
import 'take_recorder.dart';

/// The recorder under the room (brief 35; Daylight in brief 46, direction.md §4): the honey
/// record tile, a live waveform and the time against the cap, and a designed line for every
/// [RecorderPhase] (ready, recording, paused by silence, at the cap, the explainer, refused).
/// It draws [recorder]; the recorder holds the take.
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
  static const String readyLine = 'Tap to start. Take a breath first.';
  static const String recordingLine = 'Recording. Tap to pause.';
  static const String silenceLine =
      "Paused: you went quiet. Continue when you're ready.";
  static const String pausedLine = 'Paused. Continue when you\'re ready.';
  static String fullLine(Duration cap) =>
      "That's the limit (${clock(cap)}). Submit it, or delete it and try again.";
  static const String done = 'Done';
  static const String resume = 'Continue';
  static const String delete = 'Start again';
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
    builder: (context, _) => _body(context),
  );

  Widget _body(BuildContext context) => switch (recorder.phase) {
    RecorderPhase.checking => const _Note(line: checking),
    RecorderPhase.asking => const _Note(line: asking),
    RecorderPhase.explain => _Ask(
      icon: PhosphorBold.microphone,
      title: explainTitle,
      line: explainLine,
      primary: allow,
      onPrimary: () => unawaited(recorder.allow()),
      secondary: withoutRecording,
      onSecondary: onWithoutMicrophone,
    ),
    RecorderPhase.denied => _Ask(
      icon: PhosphorBold.microphoneSlash,
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
  Widget build(BuildContext context) => DaylightPanel(
    child: Semantics(
      liveRegion: true,
      child: Text(
        line,
        style: DaylightType.body5.copyWith(color: DaylightColors.ink2),
      ),
    ),
  );
}

/// A title, a line and one or two choices: the explainer and the refused state (direction.md
/// §4: an explanation, and a way on without the microphone).
class _Ask extends StatelessWidget {
  const _Ask({
    required this.icon,
    required this.title,
    required this.line,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String line;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  static const double _tile = 40;
  static const double _glyph = 20;

  @override
  Widget build(BuildContext context) {
    final secondary = this.secondary;
    final f = ChapterTint.floorOf(context);
    return DaylightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: _tile,
                height: _tile,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f.tint,
                  borderRadius: BorderRadius.circular(DaylightRadius.tile),
                ),
                child: Icon(icon, size: _glyph, color: f.deep),
              ),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: DaylightType.heading6),
                ),
              ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s12),
          Text(
            line,
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
          const SizedBox(height: DaylightSpace.s16),
          TactileButton(label: primary, compact: true, onPressed: onPrimary),
          if (secondary != null) ...[
            const SizedBox(height: DaylightSpace.s8),
            TactileButton(
              label: secondary,
              tone: TactileTone.quiet,
              compact: true,
              onPressed: onSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// The recorder itself (direction.md §4, mockup `04`): the floor's colour, r24, its deep edge.
/// The line for the state, then the time against the cap, the live waveform and the honey
/// record tile; under a rule, the take's actions: Continue (when paused), Start again, Done.
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

  static const double _rule = 0.18;

  /// The time's column: "0:47 / of 2:00" at its size; at large text it shrinks to fit.
  static const double _timeWidth = 96;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    final phase = recorder.phase;
    final paused = phase == RecorderPhase.paused;
    final full = phase == RecorderPhase.full;
    final silence = paused && recorder.pauseReason == PauseReason.silence;
    final elapsed = recorder.elapsed;
    final cap = recorder.maxLength;
    final share = cap.inMilliseconds == 0
        ? 0.0
        : elapsed.inMilliseconds / cap.inMilliseconds;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: f.base,
        borderRadius: BorderRadius.circular(DaylightRadius.panel),
        boxShadow: DaylightElevation.edgeOf(f.deep),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  if (phase == RecorderPhase.recording) ...[
                    const _LiveDot(),
                    const SizedBox(width: DaylightSpace.s8),
                  ] else if (silence || full) ...[
                    Icon(
                      full ? PhosphorBold.hourglass : PhosphorBold.pause,
                      size: DaylightSpace.s16,
                      color: DaylightColors.honey,
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                  ],
                  Expanded(
                    child: Text(
                      _line,
                      style: DaylightType.body5.copyWith(
                        color: silence || full ? DaylightColors.raised : f.on,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DaylightSpace.s12),
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _timeWidth),
                  child: Semantics(
                    label:
                        '${RecorderPanel.clock(elapsed)} of '
                        '${RecorderPanel.clock(cap)}',
                    excludeSemantics: true,
                    // At large text the time shrinks to fit beside the tile.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            RecorderPanel.clock(elapsed),
                            style: DaylightType.tabular(DaylightType.heading5)
                                .copyWith(color: DaylightColors.raised),
                          ),
                          Text(
                            'of ${RecorderPanel.clock(cap)}',
                            style: DaylightType.tabular(DaylightType.caption4)
                                .copyWith(color: f.on),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DaylightSpace.s16),
                Expanded(
                  child: Waveform(
                    level: recorder.level,
                    share: share,
                    live: phase == RecorderPhase.recording,
                  ),
                ),
                if (!full) ...[
                  const SizedBox(width: DaylightSpace.s16),
                  RecordButton(
                    phase: phase,
                    onPressed: () => unawaited(recorder.toggle()),
                  ),
                ],
              ],
            ),
            if (recorder.hasTake) ...[
              const SizedBox(height: DaylightSpace.s12),
              SizedBox(
                height: 1,
                child: ColoredBox(
                  color: DaylightColors.raised.withValues(alpha: _rule),
                ),
              ),
              const SizedBox(height: DaylightSpace.s4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  if (paused)
                    _Link(
                      label: RecorderPanel.resume,
                      icon: PhosphorBold.play,
                      onTap: () => unawaited(recorder.resume()),
                    ),
                  _Link(
                    label: RecorderPanel.delete,
                    icon: PhosphorBold.arrowCounterClockwise,
                    soft: true,
                    onTap: () => unawaited(recorder.askDelete()),
                  ),
                  _Link(
                    label: RecorderPanel.done,
                    icon: PhosphorBold.check,
                    onTap: recorder.canSubmit
                        ? () => unawaited(_submit())
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A text action on the recorder ("Start again", "Done"): white (or the floor's soft "on"
/// for the quieter one), a Phosphor glyph, a 48 target.
class _Link extends StatelessWidget {
  const _Link({
    required this.label,
    required this.icon,
    required this.onTap,
    this.soft = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool soft;

  static const double _icon = 18;
  static const double _off = 0.45;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final ink = soft ? f.on : DaylightColors.raised;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? _off : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: DaylightSize.hit),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: _icon, color: ink),
                  const SizedBox(width: DaylightSpace.s4),
                  Flexible(
                    child: Text(
                      label,
                      style: (soft ? DaylightType.body5 : DaylightType.body4)
                          .copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Recording" on the recorder: a honey dot (the clay one is the room's white tag; clay on
/// the floor's blue would not read).
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  static const double _size = 8;

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: _size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.honey,
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// The honey record tile (64, r16, its hard edge): a microphone to start or continue, a pause
/// while recording. One labelled target.
class RecordButton extends StatelessWidget {
  const RecordButton({super.key, required this.phase, required this.onPressed});

  final RecorderPhase phase;
  final VoidCallback onPressed;

  static const double size = 64;
  static const double _glyph = 28;

  bool get _recording => phase == RecorderPhase.recording;

  @override
  Widget build(BuildContext context) => Tactile(
    label: switch (phase) {
      RecorderPhase.recording => RecorderPanel.pauseLabel,
      RecorderPhase.paused => RecorderPanel.continueLabel,
      _ => RecorderPanel.recordLabel,
    },
    onTap: onPressed,
    style: TactileStyle(
      face: DaylightColors.honey,
      edge: DaylightColors.honeyEdge,
      radius: BorderRadius.circular(DaylightRadius.card),
    ),
    child: SizedBox.square(
      dimension: size,
      child: Icon(
        _recording ? PhosphorFill.pause : PhosphorFill.microphone,
        size: _glyph,
        color: DaylightColors.onHoney,
      ),
    ),
  );
}

/// The live waveform: white bars for what's been said (the newest from the live [level]),
/// the time still to go as faint bars at 28%. Decorative for screen readers: the state line
/// says whether it's recording.
class Waveform extends StatefulWidget {
  const Waveform({
    super.key,
    required this.level,
    required this.share,
    required this.live,
  });

  /// 0–1, now.
  final double level;

  /// How much of the cap is used, 0–1.
  final double share;
  final bool live;

  static const double height = 48;
  static const int bars = 24;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> {
  final List<double> _history = [];

  static const double _floor = 0.12;
  static const double _future = 0.28;

  @override
  void didUpdateWidget(Waveform old) {
    super.didUpdateWidget(old);
    if (widget.live && widget.level != old.level) {
      _history.add(widget.level);
      if (_history.length > Waveform.bars) _history.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        height: Waveform.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(
            history: List.of(_history),
            share: widget.share,
          ),
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.history, required this.share});

  final List<double> history;
  final double share;

  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = Waveform.bars;
    final w = (size.width - _gap * (bars - 1)) / bars;
    if (w <= 0) return;
    final said = (share * bars).ceil().clamp(0, bars);
    final heard = history.length;
    final paint = Paint();
    for (var i = 0; i < bars; i++) {
      final level = i < said && heard > 0
          ? history[(heard - said + i).clamp(0, heard - 1)]
          : 0.0;
      final h = size.height * math.max(_WaveformState._floor, level);
      paint.color = DaylightColors.raised.withValues(
        alpha: i < said ? 1 : _WaveformState._future,
      );
      final x = i * (w + _gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, w, h),
          Radius.circular(math.min(w / 2, 2)),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.share != share ||
      old.history.length != history.length ||
      (history.isNotEmpty && old.history.last != history.last);
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
