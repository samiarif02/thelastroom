import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/film_kit.dart';
import '../debrief/ai_score_store.dart';
import '../debrief/ai_verdict_cards.dart';
import '../debrief/debrief_facts.dart';
import '../mission/mission_lookup.dart';
import '../progression/progression_card.dart';
import '../tower/tower_hero.dart';
import '../tower/tower_rooms.dart';
import 'chapter_report.dart';
import 'chapter_report_screen.dart';
import 'file_trouble.dart';
import 'progress_facts.dart';

/// Where the progress file was opened from (`progress_report_viewed`'s `source`): "Your file"
/// from the tower, or the Chapter 1 report (brief 24).
enum ProgressSource { tower, chapterReport }

/// Progress (FR-16, FR-41), in the tower's language (brief 17): a pinned header with the way
/// back, then a summary card in Chapter 1's colour (missions done as a ring, the average, the
/// change since Mission 1), the skill radar, each mission as a colourful card with its stars,
/// best and latest, attempts and the lesson still to work on, and the two play settings.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  static const String title = 'Your file';
  static const String back = 'Tower';
  static const String notPlayed = 'Not played yet';
  static const String skills = 'YOUR SKILLS';
  static const String skillsEmpty = 'Play a mission to see your skills here.';
  static const String missions = 'MISSIONS';
  static const String workOn = 'STILL TO WORK ON';
  static const String settings = 'HOW YOU PLAY';
  static const String autoAdvance = 'Lines move on by themselves';
  static const String calmMode = 'Calm mode: no answer timer';

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    ref.invalidate(progressReportProvider);
    ref.read(analyticsProvider).track(AnalyticsEvent.progressReportViewed, {
      'source': const EventValue.name(ProgressSource.tower),
    });
  }

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(progressReportProvider);
    final report = reading.value;
    final aiScores =
        ref.watch(latestAiScoresProvider).value ??
        const <String, SavedAiScore>{};
    final profile = ref.watch(profileProvider).value ?? const PlayerProfile();
    final profiles = ref.read(profileProvider.notifier);
    var i = 0;
    Widget enter(Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: BrandSpace.md),
      child: StaggeredEntrance(index: i++, child: child),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        const VividBackdrop(grade: ChapterGrade.lobby),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(onBack: () => context.go(Routes.tower())),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    BrandSpace.md,
                    BrandSpace.md,
                    BrandSpace.md,
                    BrandSpace.lg + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (reading.hasError && report == null)
                            enter(
                              FileTrouble(
                                onRetry: () =>
                                    ref.invalidate(progressReportProvider),
                              ),
                            ),
                          if (report != null) ...[
                            enter(
                              _Summary(
                                report: report,
                                name: profile.displayName,
                              ),
                            ),
                            enter(_Skills(skills: report.skills)),
                            enter(
                              _ReportCard(
                                state: ref.watch(chapterReportProvider).value,
                              ),
                            ),
                            enter(const _Section(ProgressScreen.missions)),
                            for (final line in report.missions)
                              enter(
                                _MissionCard(
                                  line: line,
                                  ai: _aiFor(line, aiScores),
                                ),
                              ),
                            enter(const ProgressionCard()),
                          ],
                          enter(const _Section(ProgressScreen.settings)),
                          enter(
                            _Panel(
                              child: Column(
                                children: [
                                  VividToggle(
                                    label: ProgressScreen.autoAdvance,
                                    value: profile.autoAdvance,
                                    onChanged: (v) => profiles.change(
                                      (p) => p.copyWith(autoAdvance: v),
                                    ),
                                  ),
                                  VividToggle(
                                    label: ProgressScreen.calmMode,
                                    value: profile.calmMode,
                                    onChanged: (v) => profiles.change(
                                      (p) => p.copyWith(calmMode: v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// The back button and the title, on their own ground (nothing scrolls through them).
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: BrandVivid.skyTop,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.md,
        BrandSpace.sm,
        BrandSpace.md,
        BrandSpace.sm,
      ),
      child: Row(
        children: [
          VividButton(
            label: '‹  ${ProgressScreen.back}',
            primary: false,
            onPressed: onBack,
          ),
          const SizedBox(width: BrandSpace.md),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(ProgressScreen.title, style: BrandVividType.title),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Who, and Chapter 1 at a glance: the ring, the average, the change since Mission 1.
class _Summary extends StatelessWidget {
  const _Summary({required this.report, required this.name});

  final ProgressReport report;
  final String name;

  static const double _ring = 96;

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    final delta = report.sinceBaseline?.totalDelta;
    return _Panel(
      colors: grade.cardGradient,
      glow: grade.glow,
      child: Row(
        children: [
          ProgressRing(
            value: report.total == 0 ? 0 : report.done / report.total,
            color: BrandVivid.accent,
            size: _ring,
            stroke: 9,
            child: Semantics(
              label: '${report.done} of ${report.total} missions done',
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${report.done}/${report.total}',
                    style: BrandVividType.title,
                  ),
                  Text('DONE', style: BrandVividType.kicker),
                ],
              ),
            ),
          ),
          const SizedBox(width: BrandSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name · CHAPTER 1', style: BrandVividType.kicker),
                const SizedBox(height: BrandSpace.sm),
                Wrap(
                  spacing: BrandSpace.lg,
                  runSpacing: BrandSpace.sm,
                  children: [
                    _Stat(label: 'AVERAGE', value: '${report.average ?? '–'}'),
                    _Stat(
                      label: 'SINCE MISSION 1',
                      value: delta == null ? '–' : _signed(delta),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _signed(int n) => n > 0 ? '+$n' : '$n';

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  static const double _size = 34;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: BrandVividType.numeral.copyWith(fontSize: _size)),
        Text(label, style: BrandVividType.kicker),
      ],
    ),
  );
}

/// The four skills as a radar, averaged over the latest attempts.
class _Skills extends StatelessWidget {
  const _Skills({required this.skills});

  final Map<Dimension, int>? skills;

  @override
  Widget build(BuildContext context) {
    final s = skills;
    return _Panel(
      colors: [BrandVivid.night, BrandVivid.skyMid],
      glow: BrandVivid.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ProgressScreen.skills,
            style: BrandVividType.kicker.copyWith(color: BrandVivid.accent),
          ),
          const SizedBox(height: BrandSpace.sm),
          if (s == null)
            Text(ProgressScreen.skillsEmpty, style: BrandVividType.body)
          else
            Center(
              child: SkillRadar(
                values: [for (final d in Dimension.values) s[d] ?? 0],
                labels: [for (final d in Dimension.values) dimensionLabel(d)],
                color: ChapterGrade.lobby.glow,
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BrandSpace.sm, left: BrandSpace.xs),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: BrandVividType.kicker.copyWith(color: BrandVivid.accent),
      ),
    ),
  );
}

/// One mission: in its chapter's colour once played, slate before.
class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.line, this.ai});

  final MissionProgress line;

  /// The AI recruiter's verdict on the latest attempt, when there is one (brief 24); otherwise
  /// the card shows the engine's, labelled "Offline score", as the debrief does.
  final SavedAiScore? ai;

  @override
  Widget build(BuildContext context) {
    final m = line.mission;
    final grade = m.grade;
    final latest = line.latest;
    final lesson = line.lessonToWorkOn;
    final best = line.best;
    return _Panel(
      colors: latest == null
          ? [BrandVivid.locked, BrandVivid.night]
          : grade.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MISSION ${m.number}', style: BrandVividType.kicker),
                    Semantics(
                      header: true,
                      child: Text(m.title, style: BrandVividType.row),
                    ),
                  ],
                ),
              ),
              if (best != null) StarRow(stars: starsFor(best), best: best),
            ],
          ),
          if (latest == null) ...[
            const SizedBox(height: BrandSpace.xs),
            Text(ProgressScreen.notPlayed, style: BrandVividType.body),
          ] else ...[
            const SizedBox(height: BrandSpace.sm),
            _ScoreSource(ai: ai != null),
            const SizedBox(height: BrandSpace.xs),
            Wrap(
              spacing: BrandSpace.xs,
              runSpacing: BrandSpace.xs,
              children: [
                _Chip('LATEST', '${ai?.score.overall.score ?? latest.total}'),
                _Chip(
                  line.attemptCount == 1 ? 'ATTEMPT' : 'ATTEMPTS',
                  '${line.attemptCount}',
                ),
                for (final d in Dimension.values)
                  _Chip(
                    dimensionLabel(d).toUpperCase(),
                    '${ai?.score.dimensions[d]!.score ?? latest.dimensions[d]}',
                  ),
              ],
            ),
            if (ai case final verdict?) ...[
              const SizedBox(height: BrandSpace.xs),
              Text(verdict.score.overall.basis, style: BrandVividType.body),
            ],
            if (lesson != null) ...[
              const SizedBox(height: BrandSpace.sm),
              Container(
                padding: const EdgeInsets.all(BrandSpace.sm + 4),
                decoration: BoxDecoration(
                  color: grade.deeper,
                  borderRadius: BorderRadius.circular(BrandRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProgressScreen.workOn,
                      style: BrandVividType.kicker.copyWith(
                        color: BrandVivid.accent,
                      ),
                    ),
                    Text(lesson.title, style: BrandVividType.row),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The AI verdict for [line]'s latest attempt, if one was given after that attempt was played.
/// A later attempt played offline shows its own offline score instead.
SavedAiScore? _aiFor(MissionProgress line, Map<String, SavedAiScore> scores) {
  final saved = scores[line.mission.id];
  final latest = line.attempts.isEmpty ? null : line.attempts.last;
  if (saved == null || latest == null) return null;
  final played = latest.completedAt;
  return played == null || !saved.at.isBefore(played) ? saved : null;
}

/// Who scored a mission's latest attempt, labelled as the debrief labels it.
class _ScoreSource extends StatelessWidget {
  const _ScoreSource({required this.ai});

  final bool ai;

  @override
  Widget build(BuildContext context) => Text(
    (ai ? ScoreSourceLabel.aiLabel : ScoreSourceLabel.offlineLabel)
        .toUpperCase(),
    style: BrandVividType.kicker.copyWith(
      color: ai ? BrandVivid.accent : BrandVivid.onDeepSoft,
    ),
  );
}

/// The Chapter 1 report's way in: open once the review is played, otherwise what opens it.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.state});

  final ChapterReportState? state;

  static const String title = 'Chapter 1 report';
  static const String open =
      'Your first try against your review, skill by skill.';
  static const String openButton = 'Open the report';

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null) return const SizedBox.shrink();
    final ready = s is ReportReady;
    return _Panel(
      colors: ready
          ? [BrandVivid.skyMid, BrandVivid.night]
          : [BrandVivid.locked, BrandVivid.night],
      glow: ready ? BrandVivid.accent : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: BrandVividType.row),
                ),
                const SizedBox(height: BrandSpace.xs),
                Text(switch (s) {
                  ReportReady() => open,
                  ReportNotYet(:final review) => ChapterReportScreen.notYetLine(
                    review,
                  ),
                }, style: BrandVividType.body),
                if (ready) ...[
                  const SizedBox(height: BrandSpace.sm),
                  VividButton(
                    label: openButton,
                    onPressed: () => context.go(Routes.report),
                  ),
                ],
              ],
            ),
          ),
          if (!ready) ...[
            const SizedBox(width: BrandSpace.sm),
            LockGlyph(color: BrandVivid.onDeepSoft, size: 22),
          ],
        ],
      ),
    );
  }
}

/// "BEST 72": a label and its number in a translucent pill.
class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);

  final String label;
  final String value;

  static const double _alpha = 0.3;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: BrandVivid.night.withValues(alpha: _alpha),
        borderRadius: BorderRadius.circular(BrandRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.sm + 2,
          vertical: BrandSpace.xs,
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: BrandVividType.kicker.copyWith(letterSpacing: 1),
              ),
              TextSpan(
                text: value,
                style: BrandVividType.row.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A rounded card on the sky, in [colors] (night by default).
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this._colors, this.glow});

  final Widget child;
  final List<Color>? _colors;
  final Color? glow;

  /// The fill; the current theme's slate to night unless given.
  List<Color> get colors => _colors ?? [BrandVivid.locked, BrandVivid.night];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(BrandSpace.md),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(BrandRadius.card),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      border: Border.all(color: BrandVivid.hairline()),
      boxShadow: glow == null
          ? BrandVivid.cardShadow
          : BrandVivid.glowShadow(glow!),
    ),
    child: child,
  );
}
