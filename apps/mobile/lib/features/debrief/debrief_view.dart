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
import '../../ui/daylight/daylight_kit.dart'
    show DaylightGround, TactileButton, TactileTone, TrustPips;
import '../../ui/film_kit.dart';
import '../mission/mission_lookup.dart';
import '../progression/debrief_rewards.dart';
import 'ai_score.dart';
import 'ai_score_store.dart';
import 'ai_verdict_cards.dart';
import 'debrief_facts.dart';
import 'first_try_slip.dart';
import 'reasoning_slip.dart';
import 'red_pen_slip.dart';
import 'scoring_basis_sheet.dart';
import 'then_now_slip.dart';

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
    this.baselineDraft,
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

  /// The player's Mission 1 draft, on the mission that closes the chapter: "Then / Now" sets it
  /// beside this answer (FR-41). Null elsewhere, or when the draft was skipped.
  final String? baselineDraft;

  static const String title = 'Candidate assessment';
  static const String continueLabel = 'Back to the tower';

  /// Chapter 1's review leads to its report instead (brief 24).
  /// "Debrief · floor 1 · room 4".
  static String kicker(Mission m) =>
      'Debrief · floor ${m.chapter} · room ${m.number}';
  static const String reportLabel = 'See your Chapter 1 report';

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

  /// The scorer's verdicts: the offline score may be followed by a late verdict.
  StreamSubscription<AiVerdict>? _verdicts;

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
    _verdicts = scorer.verdicts(request!).listen((verdict) {
      if (mounted) setState(() => _show(verdict));
    });
  }

  @override
  void dispose() {
    unawaited(_verdicts?.cancel());
    super.dispose();
  }

  void _show(AiVerdict verdict) {
    final late = verdict is AiScored && _verdict is AiOffline;
    _verdict = verdict;
    switch (verdict) {
      case AiScored(:final score):
        // Kept for "Your file" (brief 24); a store failure never touches the dossier.
        unawaited(
          ref
              .read(aiScoreStoreProvider)
              .save(
                SavedAiScore(
                  missionId: widget.mission.id,
                  at: DateTime.now().toUtc(),
                  score: score,
                ),
              )
              .catchError((Object _) {}),
        );
        _analytics.track(AnalyticsEvent.aiScoreShown, {
          'mission_id': EventValue.id(widget.mission),
          'score_bucket': EventValue.name(ScoreBucket.of(score.overall.score)),
          'late': EventValue.flag(late),
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
      return DaylightGround(
        floor: grade.floor,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DaylightSpace.s24),
              child: DeliberatingCard(grade: grade),
            ),
          ),
        ),
      );
    }
    final ai = verdict is AiScored ? verdict.score : null;
    // Daylight around the kept sheet (owner, 2026-11-03): the paper ground, the room named at
    // the top, the score's source and its basis, then the Candidate assessment exactly as it
    // was, then the cards under it.
    return DaylightGround(
      floor: grade.floor,
      child: SafeArea(
        child: AnchoredScroll(
          alignment: MainAxisAlignment.center,
          padding: const EdgeInsets.all(DaylightSpace.s16),
          children: [
            Text(
              DebriefView.kicker(widget.mission),
              style: DaylightType.caption4.copyWith(color: DaylightColors.ink2),
            ),
            Semantics(
              header: true,
              child: Text(widget.mission.title, style: DaylightType.heading5),
            ),
            const SizedBox(height: DaylightSpace.s12),
            Wrap(
              spacing: DaylightSpace.s8,
              runSpacing: DaylightSpace.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ScoreSourceLabel(ai: ai != null, grade: grade),
                // Brief 36: on what basis, and how we know it's sound (the reviewer's questions).
                TactileButton(
                  label: ScoringBasisSheet.open,
                  icon: PhosphorBold.bookOpen,
                  tone: TactileTone.quiet,
                  compact: true,
                  expand: false,
                  onPressed: () {
                    _analytics.track(AnalyticsEvent.scoreBasisViewed, {
                      'mission_id': EventValue.id(widget.mission),
                      'source': EventValue.name(
                        ai == null ? ScoreSource.offline : ScoreSource.ai,
                      ),
                    });
                    unawaited(
                      ScoringBasisSheet.show(
                        context,
                        mission: widget.mission,
                        engine: widget.score,
                        ai: ai,
                        grade: grade,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s16),
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
            const SizedBox(height: DaylightSpace.s24),
            _Arrive(
              shown: _settled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrustLine(trust: widget.trust),
                  const SizedBox(height: DaylightSpace.s16),
                  DebriefRewards(
                    mission: widget.mission,
                    grade: grade,
                    ready: _settled,
                  ),
                  const SizedBox(height: DaylightSpace.s16),
                  if (ai != null) ...[
                    AiBasisSlip(score: ai, grade: grade),
                    const SizedBox(height: DaylightSpace.s16),
                  ],
                  if (_facts.markedLine case final line?)
                    RedPenSlip(line: line.text, lesson: lesson!, play: _settled)
                  else if (widget.score.guessed)
                    GuessedSlip(beats: widget.score.guessedBeats)
                  else if (CostSlip.applies(widget.reasoning))
                    CostSlip(beats: widget.reasoning)
                  else
                    const CleanRunSlip(),
                  if (widget.reasoning.any(
                    (b) => b.guessed || b.given != null,
                  )) ...[
                    const SizedBox(height: DaylightSpace.s16),
                    ReasoningSlip(beats: widget.reasoning),
                  ],
                  if (widget.firstTry case final words?) ...[
                    const SizedBox(height: DaylightSpace.s16),
                    FirstTrySlip(
                      firstTry: words,
                      stronger: strongestOpening(widget.mission).text,
                    ),
                  ],
                  if (widget.baselineDraft case final then?) ...[
                    const SizedBox(height: DaylightSpace.s16),
                    ThenNowSlip(
                      then: then,
                      now: [for (final b in widget.reasoning) b.line.text]
                          .join(' '),
                      nowMission: widget.mission.number,
                    ),
                  ],
                  const SizedBox(height: DaylightSpace.s24),
                  TactileButton(
                    label: widget.mission.leadsToReport
                        ? DebriefView.reportLabel
                        : DebriefView.continueLabel,
                    icon: widget.mission.leadsToReport
                        ? PhosphorBold.bookOpen
                        : PhosphorBold.buildings,
                    onPressed: _settled ? widget.onContinue : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        ? DaylightMotion.colour
        : DaylightMotion.move,
    curve: DaylightMotion.ease,
    child: IgnorePointer(ignoring: !shown, child: child),
  );
}

/// Where trust ended, as the room's pips (no longer the film's heartbeat line).
class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.trust});

  final int trust;

  static const String label = 'Trust at the end';
  static const int _perPip = 20;
  static const int _pips = 5;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: DaylightType.caption3.copyWith(color: DaylightColors.ink2),
        ),
      ),
      TrustPips(
        trust: (trust / _perPip).round().clamp(0, _pips),
        icon: PhosphorFill.handshake,
      ),
    ],
  );
}
