import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';
import '../../../ui/haptics.dart';
import '../audio/listen_back.dart';
import '../audio/take_playback.dart';
import '../recorder/take_recorder.dart';
import '../voice_scoring.dart';
import 'listen_tile.dart';
import 'point_mark.dart';

/// The self-check (brief 35): when the AI can't listen (offline, no backend, a timeout, the
/// day's scores spent, no microphone), the player listens back and ticks the points they made.
/// The engine scores the ticks, labelled "Self-check", and the room lights either way. Each take
/// plays in a [ListenTile] (one at a time, pause and resume); the sound stops when the panel goes.
class SelfCheckPanel extends StatefulWidget {
  const SelfCheckPanel({
    super.key,
    required this.reason,
    required this.voice,
    required this.playback,
    required this.onScore,
    this.answer,
    this.reply,
    this.grade = ChapterGrade.lobby,
  });

  final SelfCheckReason reason;
  final VoicePrompt voice;

  /// The takes to listen back to; null when there's no recording.
  final Take? answer;
  final Take? reply;

  /// Plays the takes back.
  final TakePlayback playback;

  /// "Score my answer", with the ticked point ids.
  final ValueChanged<Set<String>> onScore;
  final ChapterGrade grade;

  static const String kicker = 'Self-check';
  static const String title = 'Tick what you said';
  static const String answerHeading = 'Your answer';
  static const String replyHeading = 'Your reply to the follow-up';
  static const String listenAnswer = 'Listen to your answer';
  static const String listenReply = 'Listen to your reply';
  static const String answerClip = 'your answer';
  static const String replyClip = 'your reply';
  static const String score = 'Score my answer';
  static const String contentOnly =
      'We score what you said, not how you sound.';

  static String reasonLine(SelfCheckReason reason) => switch (reason) {
    SelfCheckReason.noBackend => 'Scoring runs on this device. Listen back if you like, then tick each point you made.',
    SelfCheckReason.noSession => "You're offline, so you're the judge this time: tick each point you made.",
    SelfCheckReason.timeout => 'The recruiter took too long to answer. Tick each point you made yourself.',
    SelfCheckReason.limited => "Today's AI scores are used up. Tick each point you made: it counts just the same.",
    SelfCheckReason.error => "The recruiter couldn't score this one. Tick each point you made yourself.",
    SelfCheckReason.noMicrophone =>
      'No recording this time. Tick each point you said out loud.',
  };

  @override
  State<SelfCheckPanel> createState() => _SelfCheckPanelState();
}

class _SelfCheckPanelState extends State<SelfCheckPanel> {
  final Set<String> _ticked = {};
  late final ListenBack _player = ListenBack(widget.playback)
    ..addListener(_heard);

  void _heard() => setState(() {});

  @override
  void dispose() {
    _player
      ..removeListener(_heard)
      ..dispose();
    super.dispose();
  }

  Widget _listen(Take take, String label, String clip) => ListenTile(
    label: label,
    clip: clip,
    state: _player.stateOf(take),
    position: _player.positionOf(take),
    length: take.length,
    grade: widget.grade,
    onToggle: () => unawaited(_player.toggle(take)),
  );

  void _flip(ListenFor point) => setState(
    () => _ticked.contains(point.id)
        ? _ticked.remove(point.id)
        : _ticked.add(point.id),
  );

  @override
  Widget build(BuildContext context) {
    final answer = widget.answer;
    final reply = widget.reply;
    final f = widget.grade.floor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SelfCheckPanel.kicker,
          style: DaylightType.caption3.copyWith(color: f.deep),
        ),
        const SizedBox(height: DaylightSpace.s4),
        Semantics(
          header: true,
          child: Text(SelfCheckPanel.title, style: DaylightType.heading4),
        ),
        const SizedBox(height: DaylightSpace.s8),
        Text(
          SelfCheckPanel.reasonLine(widget.reason),
          style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
        ),
        const SizedBox(height: DaylightSpace.s16),
        DaylightPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading(SelfCheckPanel.answerHeading),
              if (answer != null)
                _listen(
                  answer,
                  SelfCheckPanel.listenAnswer,
                  SelfCheckPanel.answerClip,
                ),
              for (final p in widget.voice.listenFor)
                TickRow(
                  text: p.text,
                  ticked: _ticked.contains(p.id),
                  grade: widget.grade,
                  onTap: () => _flip(p),
                ),
              const SizedBox(height: DaylightSpace.s16),
              const _Heading(SelfCheckPanel.replyHeading),
              if (reply != null)
                _listen(
                  reply,
                  SelfCheckPanel.listenReply,
                  SelfCheckPanel.replyClip,
                ),
              for (final p in widget.voice.followUpListenFor)
                TickRow(
                  text: p.text,
                  ticked: _ticked.contains(p.id),
                  grade: widget.grade,
                  onTap: () => _flip(p),
                ),
            ],
          ),
        ),
        const SizedBox(height: DaylightSpace.s16),
        TactileButton(
          label: SelfCheckPanel.score,
          icon: PhosphorBold.check,
          onPressed: () {
            unawaited(_player.stop());
            widget.onScore(Set.of(_ticked));
          },
        ),
        const SizedBox(height: DaylightSpace.s12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              PhosphorBold.lockSimple,
              size: DaylightSpace.s16,
              color: DaylightColors.ink2,
            ),
            const SizedBox(width: DaylightSpace.s8),
            Expanded(
              child: Text(
                SelfCheckPanel.contentOnly,
                style: DaylightType.caption4.copyWith(
                  color: DaylightColors.ink2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(text, style: DaylightType.body1));
}

/// One point to tick: the whole row is the target, and a screen reader hears a checkbox.
class TickRow extends StatelessWidget {
  const TickRow({
    super.key,
    required this.text,
    required this.ticked,
    required this.onTap,
    this.grade = ChapterGrade.lobby,
  });

  final String text;
  final bool ticked;
  final VoidCallback onTap;
  final ChapterGrade grade;

  static const double _box = 24;
  static const double _border = 2;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    return Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s8),
      child: Semantics(
        checked: ticked,
        label: text,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            choiceTick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: DaylightSize.hit),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: DaylightMotion.press,
                  curve: DaylightMotion.ease,
                  width: _box,
                  height: _box,
                  decoration: BoxDecoration(
                    color: ticked ? f.base : DaylightColors.raised,
                    borderRadius: BorderRadius.circular(DaylightRadius.tag),
                    border: Border.all(
                      color: ticked ? f.base : DaylightColors.sand2,
                      width: _border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: ticked
                      ? const PointMark(
                          made: true,
                          color: DaylightColors.raised,
                        )
                      : null,
                ),
                const SizedBox(width: DaylightSpace.s12),
                Expanded(child: Text(text, style: DaylightType.body5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
