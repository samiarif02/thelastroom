import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../core/audio/game_sounds.dart';
import '../../../ui/daylight/daylight_kit.dart';
import '../../../ui/subtitle/typewriter_subtitle.dart';
import '../mission_lookup.dart';
import '../widgets/next_control.dart';

/// The chapter's cliffhanger (FR-30): after Mission 7's debrief and before the Chapter 1 report,
/// [lines] play as a short scene. Daylight (brief 48): the corridor in the floor's tint, the
/// speaker in the room's stage, talking, and each line typing out in the speech bubble under
/// them; the cliffhanger sting plays. A tap on the scene shows the rest of a line; "Next" moves
/// on; after the last line [doneLabel] (honey) leads to [onDone].
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

  static const String kicker = 'Later, in the corridor';

  /// What a screen reader hears for a tap on the scene.
  static const String showLine = 'Show the whole line';

  /// The stage's share of the screen's height (the bubble and the dock take the rest).
  static const double _stage = 0.36;

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
    final f = widget.grade.floor;
    final speaker = interviewerById(line.speakerId);
    final height = MediaQuery.sizeOf(context).height;
    final large =
        MediaQuery.textScalerOf(context).scale(DaylightSpace.s16) >
        DaylightSpace.s16 * _largeAt;
    return DaylightGround(
      color: f.tint,
      floor: f,
      child: Stack(
        fit: StackFit.expand,
        children: [
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
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              DaylightSpace.s16,
              DaylightSpace.s16,
              DaylightSpace.s16,
              DaylightSpace.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorBold.door,
                      size: DaylightSpace.s16,
                      color: f.deep,
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    Expanded(
                      child: Text(
                        EpilogueScene.kicker,
                        style: DaylightType.caption3.copyWith(color: f.deep),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DaylightSpace.s12),
                IgnorePointer(
                  child: RoomStage(
                    person: CastPeople.byId(speaker.id),
                    expression: _typed
                        ? CastExpression.neutral
                        : CastExpression.talk,
                    height: large
                        ? RoomStage.compactHeight
                        : (height * EpilogueScene._stage).clamp(
                            RoomStage.compactHeight,
                            _stageMax,
                          ),
                    semanticLabel: speaker.name,
                  ),
                ),
                const SizedBox(height: DaylightSpace.s16),
                Expanded(
                  child: SingleChildScrollView(
                    child: TypewriterSubtitle(
                      key: ValueKey(_line),
                      speaker: speaker.name,
                      line: line.text,
                      grade: widget.grade,
                      daylight: true,
                      floor: f,
                      controller: _typer,
                      onCharacter: (c, _) =>
                          widget.sounds.subtitleCharacter(line.speakerId, c),
                      onComplete: () => setState(() => _typed = true),
                    ),
                  ),
                ),
                const SizedBox(height: DaylightSpace.s16),
                if (_typed && _last)
                  TactileButton(
                    label: widget.doneLabel,
                    icon: PhosphorBold.arrowRight,
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
      ),
    );
  }

  static const double _stageMax = 240;
  static const double _largeAt = 1.3;
}
