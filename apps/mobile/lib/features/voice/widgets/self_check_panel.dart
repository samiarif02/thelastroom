import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../../debrief/red_pen_slip.dart';
import '../recorder/take_recorder.dart';
import '../voice_scoring.dart';
import 'point_mark.dart';

/// The self-check (brief 35): when the AI can't listen (offline, no backend, a timeout, the
/// day's scores spent, no microphone), the player listens back and ticks the points they made.
/// The engine scores the ticks, labelled "Self-check", and the room lights either way.
class SelfCheckPanel extends StatefulWidget {
  const SelfCheckPanel({
    super.key,
    required this.reason,
    required this.voice,
    required this.onListen,
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

  /// Plays a take back.
  final ValueChanged<Take> onListen;

  /// "Score my answer", with the ticked point ids.
  final ValueChanged<Set<String>> onScore;
  final ChapterGrade grade;

  static const String kicker = 'SELF-CHECK';
  static const String title = 'Tick what you said';
  static const String answerHeading = 'YOUR ANSWER';
  static const String replyHeading = 'YOUR REPLY TO THE FOLLOW-UP';
  static const String listenAnswer = 'Listen to your answer';
  static const String listenReply = 'Listen to your reply';
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

  void _flip(ListenFor point) => setState(
    () => _ticked.contains(point.id)
        ? _ticked.remove(point.id)
        : _ticked.add(point.id),
  );

  @override
  Widget build(BuildContext context) {
    final answer = widget.answer;
    final reply = widget.reply;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SelfCheckPanel.kicker,
          textAlign: TextAlign.center,
          style: BrandVividType.kicker.copyWith(color: widget.grade.glow),
        ),
        const SizedBox(height: BrandSpace.xs),
        Semantics(
          header: true,
          child: Text(
            SelfCheckPanel.title,
            textAlign: TextAlign.center,
            style: BrandVividType.title,
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        Text(
          SelfCheckPanel.reasonLine(widget.reason),
          textAlign: TextAlign.center,
          style: BrandVividType.body,
        ),
        const SizedBox(height: BrandSpace.md),
        PaperSlip(
          grade: widget.grade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading(SelfCheckPanel.answerHeading),
              if (answer != null)
                _Listen(
                  label: SelfCheckPanel.listenAnswer,
                  onPressed: () => widget.onListen(answer),
                ),
              for (final p in widget.voice.listenFor)
                TickRow(
                  text: p.text,
                  ticked: _ticked.contains(p.id),
                  grade: widget.grade,
                  onTap: () => _flip(p),
                ),
              const SizedBox(height: BrandSpace.md),
              const _Heading(SelfCheckPanel.replyHeading),
              if (reply != null)
                _Listen(
                  label: SelfCheckPanel.listenReply,
                  onPressed: () => widget.onListen(reply),
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
        const SizedBox(height: BrandSpace.md),
        VividButton(
          label: SelfCheckPanel.score,
          expand: true,
          onPressed: () => widget.onScore(Set.of(_ticked)),
        ),
        const SizedBox(height: BrandSpace.sm),
        Text(
          SelfCheckPanel.contentOnly,
          textAlign: TextAlign.center,
          style: BrandVividType.kicker,
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: BrandType.label.copyWith(color: SlipInk.soft)),
  );
}

class _Listen extends StatelessWidget {
  const _Listen({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BrandSpace.sm),
    child: VividButton(
      label: label,
      primary: false,
      expand: true,
      onPressed: () => unawaited(Future.sync(onPressed)),
    ),
  );
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BrandSpace.sm),
    child: Semantics(
      checked: ticked,
      label: text,
      excludeSemantics: true,
      child: Pressable(
        label: text,
        onTap: onTap,
        selected: ticked,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
          child: Row(
            children: [
              Container(
                width: _box,
                height: _box,
                decoration: BoxDecoration(
                  color: ticked ? BrandVivid.accent : null,
                  borderRadius: BorderRadius.circular(BrandRadius.md),
                  border: Border.all(
                    color: ticked ? BrandVivid.accent : SlipInk.soft,
                    width: _border,
                  ),
                ),
                alignment: Alignment.center,
                child: ticked
                    ? PointMark(made: true, color: BrandVivid.onAccent)
                    : null,
              ),
              const SizedBox(width: BrandSpace.md),
              Expanded(
                child: Text(
                  text,
                  style: BrandType.body.copyWith(color: SlipInk.text),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
