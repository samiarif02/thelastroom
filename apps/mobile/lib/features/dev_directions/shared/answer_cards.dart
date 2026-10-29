import 'package:flutter/widgets.dart';

import 'cue.dart';

/// The three answer cards' shared behaviour: which one is picked, and a stagger as they arrive.
/// Each direction draws its own card with [cardBuilder].
class AnswerCards extends StatefulWidget {
  const AnswerCards({
    super.key,
    required this.t,
    required this.answers,
    required this.cardBuilder,
    required this.arrive,
    this.gap = 10,
  });

  /// Arrival progress, 0–1.
  final double t;
  final List<String> answers;
  final Widget Function(int index, String answer, bool picked) cardBuilder;

  /// How a card moves in, given its own 0–1 progress.
  final Widget Function(double t, Widget card) arrive;
  final double gap;

  @override
  State<AnswerCards> createState() => _AnswerCardsState();
}

class _AnswerCardsState extends State<AnswerCards> {
  int? _picked;

  static const double _stagger = 0.18;

  @override
  Widget build(BuildContext context) {
    final n = widget.answers.length;
    final span = 1 - _stagger * (n - 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) SizedBox(height: widget.gap),
          widget.arrive(
            cue(widget.t, _stagger * i, _stagger * i + span),
            Semantics(
              button: true,
              selected: _picked == i,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _picked = i),
                child: widget.cardBuilder(i, widget.answers[i], _picked == i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
