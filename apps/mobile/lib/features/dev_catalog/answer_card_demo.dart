import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';
import 'sample_mission.dart';

/// The answer cards as the mission player uses them: tap one to select it, tap it again to lock
/// it in (the rest disable). A long press anywhere on the cards resets.
class AnswerCardDemo extends StatefulWidget {
  const AnswerCardDemo({super.key, required this.grade});

  final ChapterGrade grade;

  @override
  State<AnswerCardDemo> createState() => _AnswerCardDemoState();
}

class _AnswerCardDemoState extends State<AnswerCardDemo> {
  int? _picked;
  bool _locked = false;

  void _pick(int i) => setState(() {
    if (_picked == i) {
      _locked = true;
    } else {
      _picked = i;
    }
  });

  AnswerCardState _stateOf(int i) {
    if (_locked) {
      return i == _picked ? AnswerCardState.locked : AnswerCardState.disabled;
    }
    return i == _picked ? AnswerCardState.selected : AnswerCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => setState(() {
        _picked = null;
        _locked = false;
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < SampleMission.answers.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : BrandSpace.sm),
              child: AnswerCard(
                numeral: AnswerCard.numeralFor(i),
                text: SampleMission.answers[i],
                state: _stateOf(i),
                grade: widget.grade,
                onTap: () => _pick(i),
              ),
            ),
        ],
      ),
    );
  }
}
