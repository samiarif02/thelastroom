import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/vivid/vivid_button.dart';
import 'ai_score.dart';
import 'debrief_facts.dart';
import 'red_pen_slip.dart';

/// Who scored this verdict: `score_basis_viewed`'s `source`.
enum ScoreSource { ai, offline }

/// "How we scored this", opened from the debrief (brief 36). The reviewer asked on what basis
/// the AI scores and how we know it scores well: this answers both, for this one answer, in
/// plain words. What the mission practised, who scored it, the four dimensions and their
/// weights, the AI's number beside the game's own, what the AI is told and never told, and how
/// the AI recruiter is tested.
class ScoringBasisSheet extends StatelessWidget {
  const ScoringBasisSheet({
    super.key,
    required this.mission,
    required this.engine,
    required this.ai,
    required this.onClose,
    this.grade = ChapterGrade.lobby,
  });

  final Mission mission;

  /// The game's own score for this answer (always there).
  final MissionScore engine;

  /// The recruiter's verdict, or null when the dossier shows the offline score.
  final AiScore? ai;
  final VoidCallback onClose;
  final ChapterGrade grade;

  static const String title = 'How we scored this';
  static const String open = 'How we scored this';
  static const String close = 'Close';
  static const String practisedHeading = 'WHAT THIS MISSION PRACTISED';
  static const String whoHeading = 'WHO SCORED IT';
  static const String aiWho =
      'An AI senior recruiter (Google Gemini) read your answer the way an interviewer would, '
      'and gave each of the four dimensions a score from 0 to 100 with one sentence saying why. '
      'It scores; it never coaches.';
  static const String offlineWho =
      "The AI recruiter wasn't reachable, so this is the game's own score: every line you could "
      'pick was scored 0–3 on each dimension by the content author, and the engine adds them up '
      'with the weights below. Same answer, same score, every time.';
  static const String dimensionsHeading = 'THE FOUR DIMENSIONS';
  static const String compareHeading = "THE RECRUITER'S SCORE AND THE GAME'S";
  static const String compareLine =
      'Two readings of the same answer. Your progress over time (your first try, the Chapter 1 '
      "report, skills) uses the game's score, so it stays comparable from day to day.";
  static const String seesHeading = 'WHAT THE RECRUITER IS TOLD';
  static const String sees =
      'The question, the lines you chose, the reason you gave for each, whether a line was '
      'picked too fast to have been read, and your reply to the follow-up.';
  static const String neverSees =
      'Never your name, never anything you typed, never who you are. In voice missions, we '
      'score what you said, not how you sound.';
  static const String testedHeading = 'HOW WE CHECK THE RECRUITER';
  static const String tested =
      'We run it on a test set of strong, weak and guessed answers from every Chapter 1 mission, '
      'several times each, and publish how often it lands where the author intended, how much '
      "the same answer's score moves between runs, and how closely it agrees with the game's "
      'score. The method and the latest results are in the project (docs/scoring-eval.md).';

  /// What each dimension asks of an answer.
  static const Map<Dimension, String> asks = {
    Dimension.relevance: 'Does it answer the question that was asked?',
    Dimension.specificity:
        'Concrete facts, your own part, a result you can point to.',
    Dimension.structure:
        'An opening, the evidence, a close: in that order, without rambling.',
    Dimension.adaptability:
        'When the interviewer pushes back, do you answer the challenge?',
  };

  @override
  Widget build(BuildContext context) {
    final ai = this.ai;
    final soft = BrandType.label.copyWith(color: SlipInk.soft);
    final body = BrandType.body.copyWith(color: SlipInk.text);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: BrandSpace.lg, bottom: BrandSpace.xs),
      child: Semantics(header: true, child: Text(text, style: soft)),
    );
    return PaperSlip(
      grade: grade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: BrandType.display.copyWith(color: SlipInk.text),
            ),
          ),
          if (mission.practises case final practised?) ...[
            heading(practisedHeading),
            Text(practised, style: body),
          ],
          heading(whoHeading),
          Text(ai == null ? offlineWho : aiWho, style: body),
          heading(dimensionsHeading),
          for (final d in Dimension.values)
            Padding(
              padding: const EdgeInsets.only(bottom: BrandSpace.sm),
              child: Semantics(
                label:
                    '${dimensionLabel(d)}, ${d.weightPercent} percent of the score. ${asks[d]}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dimensionLabel(d)} · ${d.weightPercent} %',
                      style: BrandType.choice.copyWith(color: SlipInk.text),
                    ),
                    Text(asks[d]!, style: body),
                  ],
                ),
              ),
            ),
          if (ai != null) ...[
            heading(compareHeading),
            Semantics(
              label:
                  "The recruiter scored ${ai.overall.score}; the game's own score is ${engine.total}.",
              excludeSemantics: true,
              child: Text(
                'Recruiter ${ai.overall.score}  ·  Game ${engine.total}',
                style: BrandType.choice.copyWith(color: SlipInk.text),
              ),
            ),
            Text(compareLine, style: body),
          ],
          heading(seesHeading),
          Text(sees, style: body),
          const SizedBox(height: BrandSpace.xs),
          Text(neverSees, style: body),
          heading(testedHeading),
          Text(tested, style: body),
          const SizedBox(height: BrandSpace.lg),
          VividButton(label: close, expand: true, onPressed: onClose),
        ],
      ),
    );
  }

  /// Opens the sheet over the debrief: a dimmed backdrop, the sheet scrolling in the middle.
  /// No Material: a general dialog with the brand's own sheet.
  static Future<void> show(
    BuildContext context, {
    required Mission mission,
    required MissionScore engine,
    required AiScore? ai,
    ChapterGrade grade = ChapterGrade.lobby,
  }) => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: close,
    barrierColor: BrandVivid.night.withValues(alpha: _scrim),
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? BrandMotion.reducedMotionFade
        : BrandMotion.standard,
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BrandSpace.lg),
            child: ScoringBasisSheet(
              mission: mission,
              engine: engine,
              ai: ai,
              grade: grade,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  static const double _scrim = 0.8;
  static const double _maxWidth = 560;
}
