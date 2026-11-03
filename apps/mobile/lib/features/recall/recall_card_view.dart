import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../../ui/haptics.dart';
import '../mission/mission_lookup.dart';
import 'recall_controller.dart';
import 'recall_deck.dart';

/// One note of a round (direction.md §7, mockup `07`): Priya welcomes the player back and names
/// who caught them, the note itself on taped paper (what they fell for, what it led to, the
/// day of the schedule), then "What holds up better?" and the choices as pick cards. One tap
/// answers; then what it meant and "Next". The tape presses down as the note arrives (motion
/// 7).
class RecallCardView extends StatelessWidget {
  const RecallCardView({
    super.key,
    required this.playing,
    required this.onAnswer,
    required this.onNext,
    this.playerName = 'there',
  });

  final RecallPlaying playing;
  final String playerName;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;

  static const String next = 'Next';
  static const String finish = 'Finish';
  static const String known = 'Right. This note moves up a box.';
  static const String guessed =
      "Right, but that was a guess. It'll come back tomorrow.";
  static const String missed = "Not quite. Here's the one that holds.";
  static const String trapAsk = 'What holds up better?';
  static const String noHints = 'No hints this time';

  static String verdictLine(RecallVerdict verdict) => switch (verdict) {
    RecallVerdict.known => known,
    RecallVerdict.guessed => guessed,
    RecallVerdict.missed => missed,
  };

  /// Priya's welcome, naming who caught the player when it was a trap.
  static String hello(String name, String? caughtBy) {
    final who = name.replaceAll(RegExp(r'[\s.!?]+$'), '');
    if (caughtBy == null) {
      return 'Welcome back, $who. One to keep fresh. Want another go?';
    }
    final by = interviewerById(caughtBy).name;
    return 'Welcome back, $who. $by caught you on this one. Want another go?';
  }

  /// "Day 3 of 7": where the note is on its schedule.
  static String day(LeitnerBox? box) => switch (box) {
    LeitnerBox.one || null => 'Day 1 of 7',
    LeitnerBox.three => 'Day 3 of 7',
    LeitnerBox.seven => 'Day 7 of 7',
  };

  PickState _stateOf(RecallQuestion q, RecallChoice choice) {
    if (!playing.answered) return PickState.idle;
    // The right answer alone is locked in; a wrong pick dims with the rest, so the two never
    // look alike (brief 23).
    if (choice.id == q.correctChoiceId) return PickState.locked;
    return PickState.dimmed;
  }

  static const double _face = 96;
  static const double _faceHeight = 116;

  @override
  Widget build(BuildContext context) {
    final q = playing.question;
    final last = playing.index == playing.round.length - 1;
    final verdict = playing.verdict;
    return Column(
      key: ValueKey(q.cardId),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const ArchPortrait(
                person: CastPeople.priya,
                expression: CastExpression.smile,
                width: _face,
                height: _faceHeight,
                ground: DaylightColors.recallSoft,
                semanticLabel: 'Priya, the recruiter',
              ),
              const SizedBox(width: DaylightSpace.s16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DaylightSpace.s8),
                  child: SpeechBubble(
                    speaker: 'Priya',
                    line: hello(playerName, q.caughtBy),
                    tail: BubbleTail.left,
                    lineStyle: DaylightType.body2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DaylightSpace.s24),
        Entrance(
          index: 1,
          child: _Note(question: q, box: playing.box),
        ),
        const SizedBox(height: DaylightSpace.s24),
        Semantics(
          header: true,
          child: Text(
            q.kind == RecallCardKind.trap ? trapAsk : q.ask,
            style: DaylightType.title3.copyWith(
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation.weight(600)],
            ),
          ),
        ),
        const SizedBox(height: DaylightSpace.s8),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DaylightSpace.s8),
            child: Entrance(
              index: i + 2,
              child: PickCard(
                letter: String.fromCharCode(_a + i),
                lockedIcon: PhosphorBold.check,
                text: q.choices[i].text,
                state: _stateOf(q, q.choices[i]),
                onTap: playing.answered
                    ? null
                    : () {
                        if (q.choices[i].id == q.correctChoiceId) successTap();
                        onAnswer(q.choices[i].id);
                      },
              ),
            ),
          ),
        if (verdict != null) ...[
          const SizedBox(height: DaylightSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(
              verdictLine(verdict),
              style: DaylightType.heading6.copyWith(
                color: verdict == RecallVerdict.known
                    ? DaylightColors.recallDeep
                    : DaylightColors.ink,
              ),
            ),
          ),
          if (q.takeaway case final takeaway?) ...[
            const SizedBox(height: DaylightSpace.s4),
            Text(
              takeaway,
              style: DaylightType.body3.copyWith(color: DaylightColors.ink2),
            ),
          ],
          const SizedBox(height: DaylightSpace.s16),
          TactileButton(
            label: last ? finish : next,
            icon: last ? PhosphorBold.check : PhosphorBold.arrowRight,
            tone: TactileTone.recall,
            onPressed: onNext,
          ),
        ],
      ],
    );
  }

  static const int _a = 65;
}

/// The note: warm paper at −1.5°, honey tape that presses down as it lands, "You fell for"
/// in clay (the trap's colour), the misconception in Heading 6, what it led to, and the day.
class _Note extends StatelessWidget {
  const _Note({required this.question, required this.box});

  final RecallQuestion question;
  final LeitnerBox? box;

  static const double _tilt = -0.026; // about −1.5°
  static const double _tape = 88;
  static const double _tapeHeight = 24;
  static const double _tapeTilt = 0.035;
  static const double _tapeFrom = 0.6;
  static const double _paper = 0.25;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final trap = q.kind == RecallCardKind.trap;
    final still = MediaQuery.disableAnimationsOf(context);
    final note = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          DaylightColors.honeyTint.withValues(alpha: _paper),
          DaylightColors.raised,
        ),
        borderRadius: BorderRadius.circular(DaylightRadius.inner),
        boxShadow: DaylightElevation.lift,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DaylightSpace.s16,
          DaylightSpace.s24,
          DaylightSpace.s16,
          DaylightSpace.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trap ? PhosphorBold.pushPin : PhosphorBold.notebook,
                  size: DaylightSpace.s16,
                  color: trap ? DaylightColors.trap : DaylightColors.recall,
                ),
                const SizedBox(width: DaylightSpace.s4),
                Expanded(
                  child: Text(
                    q.kicker,
                    style: DaylightType.caption3.copyWith(
                      color: trap ? DaylightColors.trap : DaylightColors.recall,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s8),
            Semantics(
              header: true,
              child: Text(
                trap ? '“${q.prompt}”' : q.prompt,
                style: DaylightType.heading6,
              ),
            ),
            if (q.quote case final quote?) ...[
              const SizedBox(height: DaylightSpace.s8),
              Text(
                'It led you to: “$quote”',
                style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
              ),
            ],
            const SizedBox(height: DaylightSpace.s12),
            const _Dashes(),
            const SizedBox(height: DaylightSpace.s12),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: DaylightSpace.s8,
                children: [
                  Text(
                    RecallCardView.day(box),
                    style: DaylightType.tabular(DaylightType.caption4)
                        .copyWith(color: DaylightColors.ink2),
                  ),
                  Text(
                    RecallCardView.noHints,
                    style: DaylightType.caption4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final tape = SizedBox(
      width: _tape,
      height: _tapeHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DaylightColors.honey.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(DaylightSpace.s2),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s8),
      child: Transform.rotate(
        angle: _tilt,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            note,
            Positioned(
              top: -_tapeHeight / 2,
              child: Transform.rotate(
                angle: _tapeTilt,
                child: still
                    ? tape
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: _tapeFrom, end: 1),
                        duration: DaylightMotion.colour,
                        curve: DaylightMotion.ease,
                        builder: (context, y, child) => Transform.scale(
                          scaleY: y,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                        child: tape,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The note's dashed rule.
class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _DashPainter()),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DaylightColors.sand2
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += _dash + _gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + _dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
