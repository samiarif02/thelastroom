import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';
import '../mission_lookup.dart';
import '../widgets/beat_timer.dart';

/// Stepping into a room (issue 76; it replaced the lift ride and the floor-coloured title
/// card, which a reviewer found confusing): one calm card on the floor's tint that says what
/// is about to happen, then waits. The interviewer greets you from their arch; the room is
/// named ("Room 5 · Something went wrong") with who's asking, what it trains, how you answer,
/// how many beats and whether a timer runs. Nothing starts by itself: [onStart] ("Start the
/// interview") is the one way in, and the arrow at the top goes back to the tower.
///
/// A room left part-way shows the same card with Resume and Start over ([onStartOver] set,
/// [beatsDone] how far it got). Under reduced motion nothing moves.
class RoomIntro extends StatelessWidget {
  const RoomIntro({
    super.key,
    required this.mission,
    required this.onStart,
    required this.onBack,
    this.calm = false,
    this.onStartOver,
    this.beatsDone = 0,
  });

  final Mission mission;

  /// Start the interview, or (with [onStartOver]) resume it.
  final VoidCallback onStart;

  /// Back to the tower; nothing was started, so nothing is kept.
  final VoidCallback onBack;

  /// The player's Calm mode: no answer timer on any room.
  final bool calm;

  /// Set on a room left part-way: drops the saved answers and starts from the first line.
  final VoidCallback? onStartOver;

  /// Beats locked in before the player left (resume only).
  final int beatsDone;

  bool get resuming => onStartOver != null;

  static const String start = 'Start the interview';
  static const String resume = 'Resume';
  static const String startOver = 'Start over';
  static const String back = 'Back to the tower';
  static const String trainsLabel = 'What this room trains';
  static const String answerLabel = 'How you answer';
  static const String choices = 'Choices';
  static const String outLoud = 'Out loud';
  static const String calmTag = 'Calm · no timer';
  static const String untimed = 'No timer';
  static const String choicesHow =
      'Pick the line you would say, then tell them why it works.';
  static const String outLoudHow =
      'Say your answer out loud, in your own words. Nobody else hears it.';

  /// "Floor 2 · room 11", the room's place in the tower (the in-room top bar's kicker too).
  static String kicker(Mission m) => 'Floor ${m.chapter} · room ${m.number}';

  /// "Room 5 · Something went wrong".
  static String heading(Mission m) => 'Room ${m.number} · ${m.title}';

  static String withWho(Interviewer lead) =>
      'with ${lead.name}, ${lead.role.toLowerCase()}';

  static String ready(Interviewer lead) =>
      '${lead.name} is ready when you are.';

  static String beats(int n) => '$n beats';
  static String answers(int n) => '$n answers';
  static String timed(Duration d) => 'Timed · ${d.inSeconds} s a beat';
  static String spoken(int seconds) => 'Up to $seconds s an answer';

  /// Where a left room stands.
  static String leftAt(int done, int of) => done == 0
      ? 'You left before your first answer. Pick up where you were, or start over.'
      : 'You left after beat $done of $of. Your answers so far are kept, in the same order.';

  /// The voice rooms ask twice: the question, then the follow-up.
  static const int _voiceAnswers = 2;
  static const double _maxWidth = 520;
  static const double _arch = 112;
  static const double _archHeight = 136;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final f = m.grade.floor;
    final lead = m.lead;
    final still = MediaQuery.disableAnimationsOf(context);
    final voice = m.answerMode == AnswerMode.voice;
    final practises = m.practises;
    final facts = <Widget>[
      Tag(
        label: voice ? outLoud : choices,
        icon: voice ? PhosphorBold.microphone : PhosphorBold.cards,
        tone: TagTone.floor(f),
      ),
      Tag(
        label: voice ? answers(_voiceAnswers) : beats(m.beats.length),
        icon: PhosphorBold.stack,
        tone: TagTone.floor(f),
      ),
      Tag(
        label: switch ((voice, calm, m.timed)) {
          (true, _, _) => spoken(m.voice?.maxSeconds ?? 0),
          (false, true, _) => calmTag,
          (false, false, true) => timed(BeatTimer.defaultDuration),
          (false, false, false) => untimed,
        },
        icon: !voice && (!m.timed || calm)
            ? PhosphorBold.moon
            : PhosphorBold.timer,
        tone: TagTone.floor(f),
      ),
    ];
    Widget label(String text) => Text(
      text,
      style: DaylightType.caption3.copyWith(color: DaylightColors.ink2),
    );
    final items = <Widget>[
      ArchPortrait(
        person: CastPeople.byId(lead.id),
        expression: CastExpression.smile,
        width: _arch,
        height: _archHeight,
        ground: f.soft,
        border: DaylightSpace.s4,
        sill: f.deep,
        idle: !still,
        semanticLabel: '${lead.name}, ${lead.role}',
      ),
      const SizedBox(height: DaylightSpace.s16),
      Text(kicker(m), style: DaylightType.caption3.copyWith(color: f.deep)),
      const SizedBox(height: DaylightSpace.s8),
      Semantics(
        header: true,
        child: Text(heading(m), style: DaylightType.heading5),
      ),
      const SizedBox(height: DaylightSpace.s4),
      Text(
        withWho(lead),
        style: DaylightType.body3.copyWith(color: DaylightColors.ink2),
      ),
      const SizedBox(height: DaylightSpace.s16),
      DaylightPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (practises != null) ...[
              label(trainsLabel),
              const SizedBox(height: DaylightSpace.s4),
              Text(practises, style: DaylightType.body2),
              const SizedBox(height: DaylightSpace.s16),
            ],
            label(answerLabel),
            const SizedBox(height: DaylightSpace.s4),
            Text(voice ? outLoudHow : choicesHow, style: DaylightType.body6),
            const SizedBox(height: DaylightSpace.s12),
            Wrap(
              spacing: DaylightSpace.s8,
              runSpacing: DaylightSpace.s8,
              children: facts,
            ),
          ],
        ),
      ),
      const SizedBox(height: DaylightSpace.s16),
      Text(
        resuming ? leftAt(beatsDone, m.beats.length) : ready(lead),
        style: DaylightType.body5.copyWith(color: DaylightColors.ink2),
      ),
    ];
    final actions = <Widget>[
      TactileButton(
        label: resuming ? resume : start,
        icon: PhosphorFill.play,
        onPressed: onStart,
      ),
      if (onStartOver case final over?) ...[
        const SizedBox(height: DaylightSpace.s8),
        TactileButton(
          label: startOver,
          icon: PhosphorBold.arrowCounterClockwise,
          tone: TactileTone.quiet,
          onPressed: over,
        ),
      ],
    ];
    Widget arrive(int i, Widget w) =>
        still ? w : Entrance(index: i ~/ 2, child: w);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DaylightGround(
      color: f.tint,
      floor: f,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DaylightTopBar(
              leadingIcon: PhosphorBold.arrowLeft,
              leadingLabel: back,
              onLeading: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DaylightSpace.s24,
                  DaylightSpace.s8,
                  DaylightSpace.s24,
                  DaylightSpace.s16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (i, w) in items.indexed) arrive(i, w),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                DaylightSpace.s24,
                DaylightSpace.s8,
                DaylightSpace.s24,
                bottom + DaylightSpace.s16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
