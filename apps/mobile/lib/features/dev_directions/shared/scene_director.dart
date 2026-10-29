import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'cue.dart';

/// Where the scene is, for one frame of its choreography.
class SceneState {
  const SceneState({
    required this.bars,
    required this.cut,
    required this.choices,
    required this.characters,
    required this.lineComplete,
  });

  /// Letterbox: 0 open, 1 fully in. It slides in for the scene and retracts for the choices.
  final double bars;

  /// Camera: 0 wide shot, 1 close-up.
  final double cut;

  /// The three answer cards: 0 hidden, 1 settled.
  final double choices;

  /// Characters of the line revealed by the typewriter.
  final int characters;

  final bool lineComplete;
}

/// Runs the Mission 1 scene on one clock, the same beats for every direction:
/// bars in (wide) → the line types → the question lands, camera cuts to close-up → bars retract
/// → three answer cards. A tap completes the line, or skips to the next beat.
///
/// Each direction draws the scene its own way from [SceneState]; only the timing comes from its
/// [DirectionMotion]. One clock, no timers, so tests can pump it deterministically.
class SceneDirector extends StatefulWidget {
  const SceneDirector({
    super.key,
    required this.motion,
    required this.line,
    required this.builder,
  });

  final DirectionMotion motion;
  final String line;
  final Widget Function(BuildContext context, SceneState scene) builder;

  @override
  State<SceneDirector> createState() => _SceneDirectorState();
}

class _SceneDirectorState extends State<SceneDirector>
    with SingleTickerProviderStateMixin {
  // Beats between the moves, so each one lands before the next starts.
  static const Duration _beforeLine = Duration(milliseconds: 350);
  static const Duration _questionLands = Duration(milliseconds: 650);
  static const Duration _beforeChoices = Duration(milliseconds: 500);
  static const Duration _choices = Duration(milliseconds: 1100);

  late AnimationController _clock;
  late List<double> _marks;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clock.duration != null) return;
    final still = MediaQuery.disableAnimationsOf(context);
    final m = widget.motion;
    final beats = [
      still ? BrandMotion.reducedMotionFade : m.letterbox,
      _beforeLine,
      m.perCharacter * widget.line.length,
      _questionLands,
      still ? BrandMotion.reducedMotionFade : m.cut,
      _beforeChoices,
      still ? BrandMotion.reducedMotionFade : _choices,
    ];
    final total = beats.fold(Duration.zero, (a, b) => a + b);
    var running = Duration.zero;
    _marks = [0];
    for (final b in beats) {
      running += b;
      _marks.add(running.inMicroseconds / total.inMicroseconds);
    }
    _clock
      ..duration = total
      ..forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// Completes the line if it's typing; otherwise jumps to the start of the next beat.
  void _advance() {
    final t = _clock.value;
    final next = _marks.firstWhere((m) => m > t + 1e-6, orElse: () => 1);
    _clock
      ..value = next
      ..forward();
  }

  SceneState _stateAt(double t) {
    final m = _marks;
    final barsIn = cue(t, m[0], m[1], widget.motion.letterboxCurve);
    final barsOut = cue(t, m[6], m[7], widget.motion.letterboxCurve);
    final typed = cue(t, m[2], m[3]);
    return SceneState(
      bars: barsIn * (1 - barsOut),
      cut: cue(t, m[4], m[5], widget.motion.cutCurve),
      choices: cue(t, m[6], m[7], BrandMotion.enter),
      characters: (typed * widget.line.length).round(),
      lineComplete: typed >= 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue the scene',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) =>
              widget.builder(context, _stateAt(_clock.value)),
        ),
      ),
    );
  }
}
