import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/film_kit.dart';
import '../mission/mission_lookup.dart';
import '../mission/widgets/trust_meter.dart';
import 'ai_score.dart';
import 'ai_verdict_cards.dart';
import 'debrief_facts.dart';
import 'first_try_slip.dart';
import 'reasoning_slip.dart';
import 'red_pen_slip.dart';

/// The debrief (FR-15): the candidate file slides across the walnut into the lamp's pool, the
/// four scores are stamped, the total sealed in wax, and the pen marks the line that cost the
/// most. Under it, the interviewer's slip: that line quoted in red, and the one lesson.
class DebriefView extends ConsumerStatefulWidget {
  const DebriefView({
    super.key,
    required this.mission,
    required this.score,
    required this.trust,
    required this.onContinue,
    this.firstTry,
    this.reasoning = const [],
    this.scoreRequest,
  });

  final Mission mission;
  final MissionScore score;

  /// Where the trust meter ended (the engine's `trustAfter`).
  final int trust;
  final VoidCallback onContinue;

  /// The player's own words from the draft-first step, shown beside a stronger version.
  final String? firstTry;

  /// Each beat's line and the reasoning the player gave (empty: the slip isn't shown).
  final List<BeatReasoning> reasoning;

  /// The answer for the AI recruiter (brief 22). Null: the engine's score, as "Offline score".
  final ScoreRequest? scoreRequest;

  static const String title = 'Candidate assessment';
  static const String continueLabel = 'Back to the tower';

  /// The dossier sheet's largest text scale (the slip and buttons below take the full 2x).
  static const double maxSheetTextScale = 1.5;

  @override
  ConsumerState<DebriefView> createState() => _DebriefViewState();
}

class _DebriefViewState extends ConsumerState<DebriefView> {
  late final DebriefFacts _facts = DebriefFacts.of(
    widget.mission,
    widget.score,
  );
  bool _settled = false;
  bool _resulted = false;

  /// The AI's verdict or the offline fallback; null while the panel deliberates.
  AiVerdict? _verdict;

  GameSounds get _sounds => ref.read(gameSoundsProvider);
  Analytics get _analytics => ref.read(analyticsProvider);

  @override
  void initState() {
    super.initState();
    final request = widget.scoreRequest;
    final scorer = ref.read(aiScorerProvider);
    final unavailable = request == null
        ? AiFallbackReason.noBackend
        : scorer.unavailable;
    if (unavailable != null) {
      // Known at once (the zero-setup run): straight to the offline score, no waiting.
      _show(AiOffline(unavailable));
      return;
    }
    _analytics.track(AnalyticsEvent.aiScoreRequested, {
      'mission_id': EventValue.id(widget.mission),
    });
    unawaited(
      scorer.score(request!).then((verdict) {
        if (mounted) setState(() => _show(verdict));
      }),
    );
  }

  void _show(AiVerdict verdict) {
    _verdict = verdict;
    switch (verdict) {
      case AiScored(:final score):
        _analytics.track(AnalyticsEvent.aiScoreShown, {
          'mission_id': EventValue.id(widget.mission),
          'score_bucket': EventValue.name(ScoreBucket.of(score.overall.score)),
        });
      case AiOffline(:final reason):
        _analytics.track(AnalyticsEvent.aiScoreFallback, {
          'mission_id': EventValue.id(widget.mission),
          'reason': EventValue.name(reason),
        });
    }
    _sounds.dossierSlides();
  }

  /// The total the dossier shows: the AI's when it scored, else the engine's.
  int get _shownTotal => switch (_verdict) {
    AiScored(:final score) => score.overall.score,
    _ => _facts.total,
  };

  void _result() {
    if (_resulted) return;
    _resulted = true;
    _sounds.result(strong: _shownTotal >= DebriefFacts.strongFrom);
  }

  @override
  Widget build(BuildContext context) {
    final grade = widget.mission.grade;
    final lesson = _facts.lesson;
    final verdict = _verdict;
    if (verdict == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          VividBackdrop(grade: grade),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(BrandSpace.lg),
                child: DeliberatingCard(grade: grade),
              ),
            ),
          ),
        ],
      );
    }
    final ai = verdict is AiScored ? verdict.score : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Walnut, and the lamp's warm pool on it.
        // The evening sky in the chapter's colour (brief 17), the file and the slips on it.
        VividBackdrop(grade: grade),
        SafeArea(
          child: AnchoredScroll(
            alignment: MainAxisAlignment.center,
            padding: const EdgeInsets.all(BrandSpace.lg),
            children: [
              ScoreSourceLabel(ai: ai != null, grade: grade),
              const SizedBox(height: BrandSpace.sm),
              // The kit's ledger row has no room for a three-digit stamp at 2x text (its score
              // doesn't shrink), so the sheet clamps its own text, as the title card does.
              // Asked of 06b in docs/status/10.md.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: DebriefView.maxSheetTextScale,
                child: Dossier(
                  title: DebriefView.title,
                  subtitle:
                      '${widget.mission.title} · with ${widget.mission.lead.name}',
                  scores: [
                    for (final d in _facts.dimensions)
                      DossierScore(
                        label: dimensionLabel(d.dimension),
                        value: ai?.dimensions[d.dimension]!.score ?? d.value,
                      ),
                  ],
                  total: _shownTotal,
                  note: lesson?.title,
                  markedIndex: _facts.markedDimensionIndex,
                  onStamp: (_) => _sounds.scoreStamped(),
                  onSeal: _result,
                  onFinished: () {
                    _result();
                    if (mounted) setState(() => _settled = true);
                  },
                ),
              ),
              const SizedBox(height: BrandSpace.lg),
              _Arrive(
                shown: _settled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TrustMeter(trust: widget.trust, grade: grade),
                    const SizedBox(height: BrandSpace.md),
                    if (ai != null) ...[
                      AiBasisSlip(score: ai, grade: grade),
                      const SizedBox(height: BrandSpace.md),
                    ],
                    if (_facts.markedLine case final line?)
                      RedPenSlip(
                        line: line.text,
                        lesson: lesson!,
                        play: _settled,
                      )
                    else if (widget.score.guessed)
                      GuessedSlip(beats: widget.score.guessedBeats)
                    else
                      const CleanRunSlip(),
                    if (widget.reasoning.any(
                      (b) => b.guessed || b.given != null,
                    )) ...[
                      const SizedBox(height: BrandSpace.md),
                      ReasoningSlip(beats: widget.reasoning),
                    ],
                    if (widget.firstTry case final words?) ...[
                      const SizedBox(height: BrandSpace.md),
                      FirstTrySlip(
                        firstTry: words,
                        stronger: strongestOpening(widget.mission).text,
                      ),
                    ],
                    const SizedBox(height: BrandSpace.lg),
                    VividButton(
                      label: DebriefView.continueLabel,
                      expand: true,
                      onPressed: _settled ? widget.onContinue : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fades its child up once [shown]; until then it holds its space, so the dossier doesn't jump.
class _Arrive extends StatelessWidget {
  const _Arrive({required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: shown ? 1 : 0,
    duration: MediaQuery.disableAnimationsOf(context)
        ? BrandMotion.reducedMotionFade
        : BrandMotion.cinematic,
    curve: BrandMotion.enter,
    child: IgnorePointer(ignoring: !shown, child: child),
  );
}
