import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../core/audio/game_sounds.dart';
import '../../../ui/film_kit.dart';
import '../mission_lookup.dart';
import '../widgets/next_control.dart';

/// The chapter's cliffhanger (FR-30): after Mission 7's debrief and before the Chapter 1 report,
/// [lines] play as a short film beat. The bars come in, the cliffhanger sting plays, and each
/// line types out like the scene's subtitles. A tap on the scene shows the rest of a line;
/// "Next" moves on; after the last line [doneLabel] leads to [onDone].
class EpilogueScene extends StatefulWidget {
  const EpilogueScene({
    super.key,
    required this.lines,
    required this.grade,
    required this.sounds,
    required this.doneLabel,
    required this.onDone,
  });

  /// Already addressed to the player.
  final List<SceneLine> lines;
  final ChapterGrade grade;
  final GameSounds sounds;
  final String doneLabel;
  final VoidCallback onDone;

  static const String kicker = 'LATER, IN THE CORRIDOR';

  /// What a screen reader hears for a tap on the scene.
  static const String showLine = 'Show the whole line';

  /// The share of the screen each letterbox bar covers.
  static const double _bar = 0.11;

  @override
  State<EpilogueScene> createState() => _EpilogueSceneState();
}

class _EpilogueSceneState extends State<EpilogueScene> {
  final TypewriterController _typer = TypewriterController();
  int _line = 0;
  bool _typed = false;

  @override
  void initState() {
    super.initState();
    widget.sounds.cliffhanger();
  }

  bool get _last => _line == widget.lines.length - 1;

  void _tapScene() {
    if (!_typer.isComplete) _typer.complete();
  }

  void _next() {
    if (_last) {
      widget.onDone();
      return;
    }
    setState(() {
      _line++;
      _typed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.lines[_line];
    final height = MediaQuery.sizeOf(context).height;
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        VividBackdrop(grade: widget.grade),
        ColoredBox(color: BrandVivid.night.withValues(alpha: 0.55)),
        Semantics(
          button: true,
          label: EpilogueScene.showLine,
          excludeSemantics: true,
          onTap: _tapScene,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tapScene,
          ),
        ),
        // The film's bars: this is a cut, not the interview.
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: SizedBox(
              height: height * EpilogueScene._bar,
              width: double.infinity,
              child: ColoredBox(color: BrandVivid.night),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: SizedBox(
              height: height * EpilogueScene._bar,
              width: double.infinity,
              child: ColoredBox(color: BrandVivid.night),
            ),
          ),
        ),
        Positioned(
          top: height * EpilogueScene._bar + insets.top + BrandSpace.md,
          left: 0,
          right: 0,
          child: Text(
            EpilogueScene.kicker,
            textAlign: TextAlign.center,
            style: BrandVividType.kicker.copyWith(color: widget.grade.glow),
          ),
        ),
        Positioned(
          left: insets.left + BrandSpace.lg,
          right: insets.right + BrandSpace.lg,
          bottom: height * EpilogueScene._bar + insets.bottom + BrandSpace.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TypewriterSubtitle(
                key: ValueKey(_line),
                speaker: interviewerById(line.speakerId).name,
                line: line.text,
                grade: widget.grade,
                controller: _typer,
                onCharacter: (c, _) =>
                    widget.sounds.subtitleCharacter(line.speakerId, c),
                onComplete: () => setState(() => _typed = true),
              ),
              const SizedBox(height: BrandSpace.md),
              if (_typed && _last)
                VividButton(
                  label: widget.doneLabel,
                  expand: true,
                  onPressed: widget.onDone,
                )
              else if (_typed)
                NextControl(grade: widget.grade, onPressed: _next)
              else
                const SizedBox(height: NextControl.height),
            ],
          ),
        ),
      ],
    );
  }
}
