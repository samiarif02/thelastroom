import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../ui/film_kit.dart';
import '../mission/widgets/cue_button.dart';

/// One frame of the intro: a line in the serif, and a quieter line beneath it.
typedef IntroFrame = ({String title, String line});

/// The intro (FR-1): three frames, each a slow push on one line, before the player meets their
/// character. "Skip" works from the first frame; finishing or skipping fires `intro_completed`
/// once, then the character card.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  static const List<IntroFrame> frames = [
    (
      title: 'One room left.',
      line:
          'Every interview comes down to a few minutes in a room like this one, '
          'across the desk from someone deciding.',
    ),
    (
      title: 'You build the answer.',
      line:
          'Line by line: how you open, the evidence, how you land. Then they push '
          'back, and you answer that too.',
    ),
    (
      title: 'Every line counts.',
      line:
          'The line that cost you most is marked in red, with what to do next '
          'time. Then you go again, better.',
    ),
  ];

  static const String skip = 'Skip';
  static const String next = 'Continue';
  static const String last = 'Meet your candidate';

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  int _frame = 0;
  bool _done = false;

  void _advance() {
    if (_frame < IntroScreen.frames.length - 1) {
      setState(() => _frame++);
    } else {
      _finish(skipped: false);
    }
  }

  void _finish({required bool skipped}) {
    if (_done) return;
    _done = true;
    ref.read(analyticsProvider).track(AnalyticsEvent.introCompleted, {
      'skipped': EventValue.flag(skipped),
    });
    context.go(Routes.character);
  }

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    final frame = IntroScreen.frames[_frame];
    final isLast = _frame == IntroScreen.frames.length - 1;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: BrandColors.void_),
        FilmOverlay(
          grain: 0,
          vignetteColor: grade.shadow,
          child: Opacity(
            opacity: 0.5,
            child: Bokeh(colors: [grade.key, grade.tint], count: 12, seed: 3),
          ),
        ),
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _advance),
        SafeArea(
          minimum: const EdgeInsets.all(BrandSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CueButton(
                  label: IntroScreen.skip,
                  quiet: true,
                  onPressed: () => _finish(skipped: true),
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _Frame(
                        key: ValueKey(_frame),
                        index: _frame,
                        frame: frame,
                      ),
                    ),
                  ),
                ),
              ),
              _Dots(count: IntroScreen.frames.length, at: _frame, grade: grade),
              const SizedBox(height: BrandSpace.md),
              CueButton(
                label: isLast ? IntroScreen.last : IntroScreen.next,
                onPressed: _advance,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One frame: the eyebrow, the line pushing in slowly, the quieter line fading up under it.
class _Frame extends StatelessWidget {
  const _Frame({super.key, required this.index, required this.frame});

  final int index;
  final IntroFrame frame;

  static const List<String> _numerals = ['I', 'II', 'III'];
  static const double _pushFrom = 1.05;

  @override
  Widget build(BuildContext context) => Timeline(
    duration: BrandMotion.titleCard,
    builder: (context, t, _) {
      final rise = cue(t, 0, 0.5, BrandMotion.enter);
      final push = cue(t, 0, 1, BrandMotion.dollyCurve);
      final line = cue(t, 0.3, 0.75, BrandMotion.enter);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: rise,
            child: BrassOrnament(text: _numerals[index]),
          ),
          const SizedBox(height: BrandSpace.lg),
          Opacity(
            opacity: rise,
            child: Transform.scale(
              scale: mix(_pushFrom, 1, push),
              child: Semantics(
                header: true,
                child: Text(
                  frame.title,
                  textAlign: TextAlign.center,
                  style: BrandType.display,
                ),
              ),
            ),
          ),
          const SizedBox(height: BrandSpace.md),
          Opacity(
            opacity: line,
            child: Text(
              frame.line,
              textAlign: TextAlign.center,
              style: BrandType.body.copyWith(color: BrandColors.textSecondary),
            ),
          ),
        ],
      );
    },
  );
}

/// Where in the intro the player is: three small brass diamonds.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.at, required this.grade});

  final int count;
  final int at;
  final ChapterGrade grade;

  static const double _size = 6;
  static const double _quarterTurn = 0.785398;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Frame ${at + 1} of $count',
    excludeSemantics: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BrandSpace.xs),
            child: Transform.rotate(
              angle: _quarterTurn,
              child: SizedBox.square(
                dimension: _size,
                child: ColoredBox(
                  color: grade.key.withValues(alpha: i == at ? 1 : 0.3),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
