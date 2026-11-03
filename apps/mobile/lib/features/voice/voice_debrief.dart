import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/game_sounds.dart';
import '../../core/progress/progress_repository.dart';
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
    return Stack(
      fit: StackFit.expand,
      children: [
        VividBackdrop(grade: grade),
        SafeArea(
          child: AnchoredScroll(
            alignment: MainAxisAlignment.center,
            padding: const EdgeInsets.all(BrandSpace.lg),
            children: [
              if (verdict != null)
                ScoreSourceLabel(ai: true, grade: grade)
              else
                const _SelfCheckLabel(),
              const SizedBox(height: BrandSpace.xs),
              Text(
                VoiceDebrief.contentOnly,
                textAlign: TextAlign.center,
                style: BrandVividType.kicker,
              ),
              const SizedBox(height: BrandSpace.sm),
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
              const SizedBox(height: BrandSpace.lg),
              AnimatedOpacity(
                opacity: _settled ? 1 : 0,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? BrandMotion.reducedMotionFade
                    : BrandMotion.cinematic,
                curve: BrandMotion.enter,
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
                      const SizedBox(height: BrandSpace.md),
                      if (verdict != null)
                        AiBasisSlip(score: verdict.score, grade: grade)
                      else
                        SelfCheckBasisSlip(
                          tallies: widget.score.tallies,
                          grade: grade,
                        ),
                      if (verdict != null) ...[
                        const SizedBox(height: BrandSpace.md),
                        HeardSlip(
                          answer: verdict.answerTranscript,
                          reply: verdict.replyTranscript,
                          grade: grade,
                        ),
                      ],
                      const SizedBox(height: BrandSpace.md),
                      PointsSlip(
                        voice: mission.voice!,
                        made: widget.made,
                        grade: grade,
                      ),
                      if (lesson != null) ...[
                        const SizedBox(height: BrandSpace.md),
                        VoiceLessonSlip(
                          lesson: lesson,
                          missedAny: _marked != null,
                          grade: grade,
                        ),
                      ],
                      const SizedBox(height: BrandSpace.lg),
                      VividButton(
                        label: mission.leadsToReport
                            ? DebriefView.reportLabel
                            : DebriefView.continueLabel,
                        expand: true,
                        onPressed: _settled ? widget.onContinue : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "SELF-CHECK" above the dossier: the player ticked the points, the engine scored them.
class _SelfCheckLabel extends StatelessWidget {
  const _SelfCheckLabel();

  static const double _alpha = 0.85;
  static const double _border = 0.4;

  @override
  Widget build(BuildContext context) => Center(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: BrandVivid.night.withValues(alpha: _alpha),
        borderRadius: BorderRadius.circular(BrandSpace.md),
        border: Border.all(color: BrandVivid.hairline(_border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.md,
          vertical: BrandSpace.xs,
        ),
        child: Text(
          VoiceDebrief.selfCheckLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: BrandVividType.kicker.copyWith(color: BrandVivid.onDeepSoft),
        ),
      ),
    ),
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

  static const String heading = 'WHY THESE SCORES';

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
            style: BrandType.label.copyWith(color: SlipInk.soft),
          ),
        ),
        for (final d in Dimension.values)
          Padding(
            padding: const EdgeInsets.only(top: BrandSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dimensionLabel(d).toUpperCase(),
                  style: BrandVividType.kicker.copyWith(color: grade.glow),
                ),
                const SizedBox(height: BrandSpace.xs),
                Text(
                  basis(d, tallies[d]!),
                  style: BrandType.body.copyWith(color: SlipInk.text),
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

  static const String heading = 'WHAT WE HEARD';
  static const String answerLabel = 'YOUR ANSWER';
  static const String replyLabel = 'YOUR REPLY';
  static const String nothing = '(nothing we could make out)';

  @override
  Widget build(BuildContext context) {
    Widget part(String label, String words) => Padding(
      padding: const EdgeInsets.only(top: BrandSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: BrandVividType.kicker.copyWith(color: grade.glow)),
          const SizedBox(height: BrandSpace.xs),
          Text(
            words.isEmpty ? nothing : '“$words”',
            style: BrandType.choice.copyWith(
              color: SlipInk.text,
              fontStyle: FontStyle.italic,
            ),
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
              style: BrandType.label.copyWith(color: SlipInk.soft),
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

  static const String madeHeading = 'POINTS YOU MADE';
  static const String missedHeading = 'POINTS YOU MISSED';
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
      padding: const EdgeInsets.only(top: BrandSpace.sm),
      child: Semantics(
        label: '${hit ? 'Made' : 'Missed'}: ${p.text}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: BrandSpace.xs),
              child: PointMark(
                made: hit,
                color: hit ? BrandVivid.accent : SlipInk.mark,
              ),
            ),
            const SizedBox(width: BrandSpace.sm),
            Expanded(
              child: Text(
                p.text,
                style: BrandType.body.copyWith(
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
      child: Text(text, style: BrandType.label.copyWith(color: SlipInk.soft)),
    );
    Widget empty() => Padding(
      padding: const EdgeInsets.only(top: BrandSpace.sm),
      child: Text(none, style: BrandType.body.copyWith(color: SlipInk.soft)),
    );
    return PaperSlip(
      grade: grade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(madeHeading),
          if (kept.isEmpty) empty(),
          for (final p in kept) line(p, hit: true),
          const SizedBox(height: BrandSpace.md),
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

  static const String heading = 'THE LESSON';
  static const double _titleSize = 24;

  @override
  Widget build(BuildContext context) => PaperSlip(
    grade: grade,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: BrandType.label.copyWith(color: SlipInk.soft)),
        const SizedBox(height: BrandSpace.xs),
        Semantics(
          header: true,
          child: Text(
            lesson.title,
            style: BrandType.display.copyWith(
              color: SlipInk.text,
              fontSize: _titleSize,
            ),
          ),
        ),
        if (missedAny) ...[
          const SizedBox(height: BrandSpace.sm),
          Text(
            lesson.flaw,
            style: BrandType.body.copyWith(color: SlipInk.mark),
          ),
        ],
        const SizedBox(height: BrandSpace.sm),
        Text(
          lesson.takeaway,
          style: BrandType.body.copyWith(color: SlipInk.text),
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
