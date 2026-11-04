import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';
import '../audio/listen_back.dart';

/// One take in the self-check's player: a round play / pause key, what a tap does ("Listen to
/// your answer", "Pause", "Play from 0:07"), a track with elapsed and total time, and while it
/// plays the tile takes the floor's tint and a small level moves (still under reduced motion).
/// The whole tile is the target; a screen reader hears the action, then where the clip is.
class ListenTile extends StatelessWidget {
  const ListenTile({
    super.key,
    required this.label,
    required this.clip,
    required this.state,
    required this.position,
    required this.length,
    required this.onToggle,
    this.grade = ChapterGrade.lobby,
  });

  /// The idle label: "Listen to your answer".
  final String label;

  /// What's played, for a screen reader: "your answer".
  final String clip;
  final ListenState state;
  final Duration position;
  final Duration length;
  final VoidCallback onToggle;
  final ChapterGrade grade;

  static const String pause = 'Pause';
  static String playFrom(Duration at) => 'Play from ${clock(at)}';
  static const String playing = 'Playing';
  static const String paused = 'Paused';

  /// m:ss.
  static String clock(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ Duration.secondsPerMinute}:'
        '${(s % Duration.secondsPerMinute).toString().padLeft(2, '0')}';
  }

  /// What a tap does, on the tile.
  String get action => switch (state) {
    ListenState.idle => label,
    ListenState.playing => pause,
    ListenState.paused => playFrom(position),
  };

  /// The screen reader's whole line: the action, then the state and the time.
  String get semantics => switch (state) {
    ListenState.idle => '$label, ${clock(length)}',
    ListenState.playing =>
      'Pause $clip. $playing, ${clock(position)} of ${clock(length)}',
    ListenState.paused =>
      'Play $clip from ${clock(position)}. $paused, '
          '${clock(position)} of ${clock(length)}',
  };

  static const double _key = 40;
  static const double _glyph = 20;
  static const double _track = 4;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    final active = state != ListenState.idle;
    final total = length.inMilliseconds;
    final value = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);
    final time = DaylightType.tabular(DaylightType.caption4)
        .copyWith(color: DaylightColors.ink2);
    return Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s8),
      child: Tactile(
        label: semantics,
        onTap: onToggle,
        style: TactileStyle(
          face: active ? f.tint : DaylightColors.sand,
          edge: active ? f.soft : DaylightColors.sand2,
          radius: BorderRadius.circular(DaylightRadius.tile),
          depth: DaylightSize.edgeSmall,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DaylightSpace.s8),
          child: Row(
            children: [
              Container(
                width: _key,
                height: _key,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f.base,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state == ListenState.playing
                      ? PhosphorFill.pause
                      : PhosphorFill.play,
                  size: _glyph,
                  color: DaylightColors.raised,
                ),
              ),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            action,
                            style: DaylightType.body4.copyWith(
                              color: active ? f.deep : DaylightColors.ink,
                            ),
                          ),
                        ),
                        if (state == ListenState.playing) Level(colour: f.base),
                      ],
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    ProgressTrack(
                      value: value,
                      animate: false,
                      height: _track,
                      fill: f.base,
                      track: active
                          ? DaylightColors.raised
                          : DaylightColors.sand2,
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(clock(position), style: time),
                        Text(clock(length), style: time),
                      ],
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

/// The small level beside "Pause": three bars that rise and fall while a take plays. Reduced
/// motion: the same bars, still. It repaints on its own layer and rebuilds nothing.
class Level extends StatefulWidget {
  const Level({super.key, required this.colour});

  final Color colour;

  static const double width = 16;
  static const double height = 14;

  @override
  State<Level> createState() => _LevelState();
}

class _LevelState extends State<Level> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _period,
  );

  static const Duration _period = Duration(milliseconds: 900);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: const Size(Level.width, Level.height),
      painter: _LevelPainter(_c, widget.colour),
    ),
  );
}

class _LevelPainter extends CustomPainter {
  _LevelPainter(this._t, this._colour) : super(repaint: _t);

  final Animation<double> _t;
  final Color _colour;

  static const int _bars = 3;
  static const double _gap = 2;
  static const double _low = 0.3;

  /// Each bar's place in the wave, so the bars move apart (and the still level isn't flat).
  static const List<double> _phase = [0, 0.35, 0.7];

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width - _gap * (_bars - 1)) / _bars;
    final paint = Paint()..color = _colour;
    for (var i = 0; i < _bars; i++) {
      // A sine from 0 to 1 over the period, lifted so a bar never vanishes.
      final sine = (1 + math.sin(2 * math.pi * (_t.value + _phase[i]))) / 2;
      final h = size.height * (_low + (1 - _low) * sine);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (w + _gap), size.height - h, w, h),
          Radius.circular(w / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelPainter old) => old._colour != _colour;
}
