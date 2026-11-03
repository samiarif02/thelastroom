import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/game_sounds.dart';
import '../../core/progress/progress_repository.dart';
import '../../ui/daylight/daylight_kit.dart'
    show ChapterTint, DaylightGround, Tag, TactileButton;
import '../../ui/film_kit.dart';
import '../debrief/ai_verdict_cards.dart';
import '../debrief/debrief_facts.dart';
import '../debrief/debrief_view.dart';
import '../debrief/red_pen_slip.dart';
import '../mission/mission_lookup.dart';
import '../progression/debrief_rewards.dart';
import 'voice_scoring.dart';
import 'widgets/point_mark.dart';

/// A voice mission's debrief (brief 35), in the Chapter 1 dossier's look: the four scores with
/// one sentence of basis each, what was heard, the points made and missed, and the one lesson.
class VoiceDebrief extends ConsumerStatefulWidget {
  const VoiceDebrief({
    super.key,
    required this.mission,
    required this.score,
    required this.source,
    required this.made,
    required this.onContinue,
    this.verdict,
  });

  final Mission mission;

  /// The engine's score from the points made: shown on a self-check, kept for progress always.
  final VoiceScore score;
  final VoiceScoreSource source;

  /// Ids of the points made.
  final Set<String> made;

  /// The AI's verdict, when it scored: its numbers and basis are the ones shown.
  final VoiceVerdict? verdict;
  final VoidCallback onContinue;

  static const String title = 'Candidate assessment';
  static const String selfCheckLabel = 'Self-check';
  static const String contentOnly =
      'We score what you said, not how you sound.';

  @override
  ConsumerState<VoiceDebrief> createState() => _VoiceDebriefState();
}

class _VoiceDebriefState extends ConsumerState<VoiceDebrief> {
  bool _settled = false;
  bool _resulted = false;

  GameSounds get _sounds => ref.read(gameSoundsProvider);

  @override
  void initState() {
    super.initState();
    _sounds.dossierSlides();
  }

  int get _total =>
      widget.verdict?.score.overall.score ?? widget.score.score.total;

  void _result() {
    if (_resulted) return;
    _resulted = true;
    _sounds.result(strong: _total >= DebriefFacts.strongFrom);
  }

  late final ({int? marked, String? note}) _pen = voiceRedPen(
    mission: widget.mission,
    byCost: widget.score.score.optionIdsByCost,
    made: widget.made,
  );

  int? get _marked => _pen.marked;
  String? get _note => _pen.note;

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final grade = mission.grade;
    final verdict = widget.verdict;
    final lesson = lessonById(mission.voice!.lessonId);
    // Daylight around the kept sheet (owner, 2026-11-03).
    return DaylightGround(
      floor: grade.floor,
      child: SafeArea(
        child: AnchoredScroll(
          alignment: MainAxisAlignment.center,
          padding: const EdgeInsets.all(DaylightSpace.s16),
          children: [
            Text(
              DebriefView.kicker(mission),
              style: DaylightType.caption4.copyWith(color: DaylightColors.ink2),
            ),
            Semantics(
              header: true,
              child: Text(mission.title, style: DaylightType.heading5),
            ),
            const SizedBox(height: DaylightSpace.s12),
            Align(
              alignment: Alignment.centerLeft,
              child: verdict != null
                  ? ScoreSourceLabel(ai: true, grade: grade)
                  : const _SelfCheckLabel(),
            ),
            const SizedBox(height: DaylightSpace.s8),
            Row(
              children: [
                const Icon(
                  PhosphorBold.ear,
                  size: DaylightSpace.s16,
                  color: DaylightColors.ink2,
                ),
                const SizedBox(width: DaylightSpace.s4),
                Expanded(
                  child: Text(
                    VoiceDebrief.contentOnly,
                    style: DaylightType.caption4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s8),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: DebriefView.maxSheetTextScale,
              child: Dossier(
                title: VoiceDebrief.title,
                subtitle: '${mission.title} · with ${mission.lead.name}',
                scores: [
                  for (final d in Dimension.values)
                    DossierScore(
                      label: dimensionLabel(d),
                      value:
                          verdict?.score.dimensions[d]!.score ??
                          widget.score.score.dimensions[d]!,
                    ),
                ],
                total: _total,
                note: _note,
                markedIndex: _marked,
                onStamp: (_) => _sounds.scoreStamped(),
                onSeal: _result,
                onFinished: () {
                  _result();
                  if (mounted) setState(() => _settled = true);
                },
              ),
            ),
            const SizedBox(height: DaylightSpace.s24),
            AnimatedOpacity(
              opacity: _settled ? 1 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? DaylightMotion.colour
                  : DaylightMotion.move,
              curve: DaylightMotion.ease,
              child: IgnorePointer(
                ignoring: !_settled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DebriefRewards(
                      mission: mission,
                      grade: grade,
                      ready: _settled,
                    ),
                    const SizedBox(height: DaylightSpace.s16),
                    if (verdict != null)
                      AiBasisSlip(score: verdict.score, grade: grade)
                    else
                      SelfCheckBasisSlip(
                        tallies: widget.score.tallies,
                        grade: grade,
                      ),
                    if (verdict != null) ...[
                      const SizedBox(height: DaylightSpace.s16),
                      HeardSlip(
                        answer: verdict.answerTranscript,
                        reply: verdict.replyTranscript,
                        grade: grade,
                      ),
                    ],
                    const SizedBox(height: DaylightSpace.s16),
                    PointsSlip(
                      voice: mission.voice!,
                      made: widget.made,
                      grade: grade,
                    ),
                    if (lesson != null) ...[
                      const SizedBox(height: DaylightSpace.s16),
                      VoiceLessonSlip(
                        lesson: lesson,
                        missedAny: _marked != null,
                        grade: grade,
                      ),
                    ],
                    const SizedBox(height: DaylightSpace.s24),
                    TactileButton(
                      label: mission.leadsToReport
                          ? DebriefView.reportLabel
                          : DebriefView.continueLabel,
                      icon: PhosphorBold.buildings,
                      onPressed: _settled ? widget.onContinue : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Self-check" above the dossier: the player ticked the points, the engine scored them.
class _SelfCheckLabel extends StatelessWidget {
  const _SelfCheckLabel();

  @override
  Widget build(BuildContext context) => const Tag(
    label: VoiceDebrief.selfCheckLabel,
    icon: PhosphorBold.checkCircle,
  );
}

/// On a self-check, why each number is what it is: the points ticked behind it.
class SelfCheckBasisSlip extends StatelessWidget {
  const SelfCheckBasisSlip({
    super.key,
    required this.tallies,
    this.grade = ChapterGrade.lobby,
  });

  final Map<Dimension, PointTally> tallies;
  final ChapterGrade grade;

  static const String heading = 'Why these scores';

  static String basis(Dimension d, PointTally t) {
    final name = d.name;
    // "1 point that earns", "2 points that earn" (brief 44: it said "1 point that earn").
    final points = t.of == 1 ? 'point that earns' : 'points that earn';
    return t.direct
        ? 'You ticked ${t.made} of the ${t.of} $points $name.'
        : 'No point earns $name on its own here, so it takes your share of all '
              'points: ${t.made} of ${t.of}.';
  }

  @override
  Widget build(BuildContext context) => PaperSlip(
    grade: grade,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            heading,
            style: SlipType.label.copyWith(color: SlipInk.soft),
          ),
        ),
        for (final d in Dimension.values)
          Padding(
            padding: const EdgeInsets.only(top: DaylightSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dimensionLabel(d),
                  style: DaylightType.caption3.copyWith(
                    color: grade.floor.deep,
                  ),
                ),
                const SizedBox(height: DaylightSpace.s4),
                Text(
                  basis(d, tallies[d]!),
                  style: SlipType.body.copyWith(color: SlipInk.text),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// "What we heard": the AI's transcript of the answer and the reply. The audio itself is gone.
class HeardSlip extends StatelessWidget {
  const HeardSlip({
    super.key,
    required this.answer,
    required this.reply,
    this.grade = ChapterGrade.lobby,
  });

  final String answer;
  final String reply;
  final ChapterGrade grade;

  static const String heading = 'What we heard';
  static const String answerLabel = 'Your answer';
  static const String replyLabel = 'Your reply';
  static const String nothing = '(nothing we could make out)';

  @override
  Widget build(BuildContext context) {
    Widget part(String label, String words) => Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: DaylightType.caption3.copyWith(color: grade.floor.deep),
          ),
          const SizedBox(height: DaylightSpace.s4),
          Text(
            words.isEmpty ? nothing : '“$words”',
            style: SlipType.quote.copyWith(color: SlipInk.text),
          ),
        ],
      ),
    );
    return PaperSlip(
      grade: grade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              heading,
              style: SlipType.label.copyWith(color: SlipInk.soft),
            ),
          ),
          part(answerLabel, answer),
          part(replyLabel, reply),
        ],
      ),
    );
  }
}

/// The points the mission listened for: the ones made, then the ones missed in red pen.
class PointsSlip extends StatelessWidget {
  const PointsSlip({
    super.key,
    required this.voice,
    required this.made,
    this.grade = ChapterGrade.lobby,
  });

  final VoicePrompt voice;
  final Set<String> made;
  final ChapterGrade grade;

  static const String madeHeading = 'Points you made';
  static const String missedHeading = 'Points you missed';
  static const String none = 'None this time.';

  @override
  Widget build(BuildContext context) {
    final all = [...voice.listenFor, ...voice.followUpListenFor];
    final kept = [
      for (final p in all)
        if (made.contains(p.id)) p,
    ];
    final missed = [
      for (final p in all)
        if (!made.contains(p.id)) p,
    ];
    Widget line(ListenFor p, {required bool hit}) => Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s8),
      child: Semantics(
        label: '${hit ? 'Made' : 'Missed'}: ${p.text}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: DaylightSpace.s4),
              child: PointMark(
                made: hit,
                color: hit ? ChapterTint.floorOf(context).base : SlipInk.mark,
              ),
            ),
            const SizedBox(width: DaylightSpace.s8),
            Expanded(
              child: Text(
                p.text,
                style: SlipType.body.copyWith(
                  color: hit ? SlipInk.text : SlipInk.mark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Widget heading(String text) => Semantics(
      header: true,
      child: Text(text, style: SlipType.label.copyWith(color: SlipInk.soft)),
    );
    Widget empty() => Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s8),
      child: Text(none, style: SlipType.body.copyWith(color: SlipInk.soft)),
    );
    return PaperSlip(
      grade: grade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(madeHeading),
          if (kept.isEmpty) empty(),
          for (final p in kept) line(p, hit: true),
          const SizedBox(height: DaylightSpace.s16),
          heading(missedHeading),
          if (missed.isEmpty) empty(),
          for (final p in missed) line(p, hit: false),
        ],
      ),
    );
  }
}

/// The one lesson the mission teaches: its flaw when a point was missed, and what to do.
class VoiceLessonSlip extends StatelessWidget {
  const VoiceLessonSlip({
    super.key,
    required this.lesson,
    required this.missedAny,
    this.grade = ChapterGrade.lobby,
  });

  final Lesson lesson;
  final bool missedAny;
  final ChapterGrade grade;

  static const String heading = 'The lesson';
  static const double _titleSize = 24;

  @override
  Widget build(BuildContext context) => PaperSlip(
    grade: grade,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: SlipType.label.copyWith(color: SlipInk.soft)),
        const SizedBox(height: DaylightSpace.s4),
        Semantics(
          header: true,
          child: Text(
            lesson.title,
            style: SlipType.title.copyWith(
              color: SlipInk.text,
              fontSize: _titleSize,
            ),
          ),
        ),
        if (missedAny) ...[
          const SizedBox(height: DaylightSpace.s8),
          Text(lesson.flaw, style: SlipType.body.copyWith(color: SlipInk.mark)),
        ],
        const SizedBox(height: DaylightSpace.s8),
        Text(
          lesson.takeaway,
          style: SlipType.body.copyWith(color: SlipInk.text),
        ),
      ],
    ),
  );
}

/// The red pen on a voice mission's dossier: which dimension it underlines and the margin note
/// beside it. The underline is the costliest missed point's dimension, unless a point on the
/// mission's lesson dimension was missed too: then it marks that one, so the note and the line
/// say the same thing (brief 44's playthrough: they pointed at different dimensions). The note
/// is the lesson's title, only beside its own dimension, and never on a run with nothing
/// missed. The lesson itself is always on the slip under the sheet. Pure, so it's tested.
({int? marked, String? note}) voiceRedPen({
  required Mission mission,
  required List<String> byCost,
  required Set<String> made,
}) {
  final voice = mission.voice!;
  final points = [...voice.listenFor, ...voice.followUpListenFor];
  int? costliest;
  for (final id in byCost) {
    if (made.contains(id)) break;
    final p = points.where((p) => p.id == id).firstOrNull;
    if (p != null) {
      costliest = Dimension.values.indexOf(p.dimension);
      break;
    }
  }
  if (costliest == null) return (marked: null, note: null);
  final lesson = lessonById(voice.lessonId);
  final lessonDim = lesson?.flag.lowers;
  if (lesson == null || lessonDim == null) {
    return (marked: costliest, note: null);
  }
  final missedOnLesson = points.any(
    (p) => !made.contains(p.id) && p.dimension == lessonDim,
  );
  if (!missedOnLesson) return (marked: costliest, note: null);
  return (marked: Dimension.values.indexOf(lessonDim), note: lesson.title);
}
