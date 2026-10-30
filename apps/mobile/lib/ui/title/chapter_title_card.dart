import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../film/cue.dart';
import '../film/timeline.dart';
import '../light/bokeh.dart';
import '../ornament/brass.dart';
import 'tracked_title.dart';

/// The chapter title card ("CHAPTER ONE · GET THROUGH THE DOOR"), and the app's own title.
/// Symmetrical, centred, engraved: the lamp warms the room from below, a brass frame draws
/// itself, the title tracks in from wide with a slow push (1.06 → 1), then the italic subtitle.
/// About [BrandMotion.titleCard] long.
///
/// [onTitleLanded] fires as the title settles (a chime, brief 09); [onFinished] at the end.
/// Under reduced motion it appears settled with a short fade. Not interactive: a screen wraps it
/// to skip or continue.
class ChapterTitleCard extends StatelessWidget {
  const ChapterTitleCard({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.grade = ChapterGrade.lobby,
    this.play = true,
    this.onTitleLanded,
    this.onFinished,
    this.footer,
  });

  /// Above the title, between brass rules: "CHAPTER ONE".
  final String eyebrow;

  /// In capitals. `\n` forces a line break; otherwise lines break between words only.
  final String title;

  /// The italic line beneath: "in which we meet Priya".
  final String? subtitle;
  final ChapterGrade grade;

  /// False shows the settled card without playing it.
  final bool play;
  final VoidCallback? onTitleLanded;
  final VoidCallback? onFinished;

  /// Shown under the subtitle once the card settles (a "tap to begin" on the home screen).
  final Widget? footer;

  static const double _pushFrom = 1.06;
  static const double _maxTitleScale = 1.5;
  static const double _subtitleSize = 20;

  // The cue sheet, as shares of the whole card.
  static const double _titleIn = 0.2;
  static const double _titleLands = 0.95;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandColors.void_,
      child: Timeline(
        duration: BrandMotion.titleCard,
        play: play,
        cues: [(at: _titleLands, fire: () => onTitleLanded?.call())],
        onFinished: onFinished,
        builder: (context, t, _) {
          final lamp = cue(t, 0, 0.6, BrandMotion.enter);
          final frame = cue(t, 0.1, 0.55, BrandMotion.camera);
          final titleT = cue(t, _titleIn, _titleLands, BrandMotion.dollyCurve);
          final subT = cue(t, 0.6, _titleLands, BrandMotion.enter);
          final foot = cue(t, 0.85, 1, BrandMotion.enter);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: lamp,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 1.2),
                      radius: 1.2,
                      colors: [
                        grade.tint.withValues(alpha: 0.9),
                        grade.shadow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: lamp * 0.7,
                child: Bokeh(
                  colors: [grade.key, grade.tint],
                  count: 14,
                  seed: 21,
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(BrandSpace.lg),
                child: CustomPaint(
                  painter: BrassFramePainter(color: grade.key, t: frame),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: _maxTitleScale,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(BrandSpace.lg),
                        child: Transform.scale(
                          scale: mix(_pushFrom, 1, titleT),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: frame,
                                child: BrassOrnament(
                                  text: eyebrow,
                                  grade: grade,
                                ),
                              ),
                              const SizedBox(height: BrandSpace.lg),
                              Semantics(
                                header: true,
                                label:
                                    '$eyebrow: ${title.replaceAll('\n', ' ')}',
                                child: ExcludeSemantics(
                                  child: Opacity(
                                    opacity: titleT,
                                    child: TrackedTitle(
                                      text: title,
                                      style: BrandType.titleCard,
                                      t: titleT,
                                    ),
                                  ),
                                ),
                              ),
                              if (subtitle case final line?) ...[
                                const SizedBox(height: BrandSpace.lg),
                                Opacity(
                                  opacity: subT,
                                  child: Text(
                                    line,
                                    textAlign: TextAlign.center,
                                    style: BrandType.display.copyWith(
                                      fontSize: _subtitleSize,
                                      color: BrandColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              if (footer case final f?) ...[
                                const SizedBox(height: BrandSpace.xl),
                                Opacity(opacity: foot, child: f),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
