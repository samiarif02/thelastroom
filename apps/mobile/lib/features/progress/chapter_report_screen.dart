import 'package:brand/brand.dart';
import 'package:content/content.dart';
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
import '../debrief/debrief_facts.dart';
import 'chapter_report.dart';
import 'file_trouble.dart';
import 'progress_screen.dart';

/// The Chapter 1 report (brief 24, FR-41): the first try against the review, skill by skill,
/// with the radar, in honest words; then the next chapter's tease and its waitlist (D1), and the
/// way back to the tower. Before the review is played it says what opens it.
class ChapterReportScreen extends ConsumerStatefulWidget {
  const ChapterReportScreen({super.key});

  static const String title = 'Chapter 1 report';
  static const String back = 'Tower';
  static const String kicker = 'YOUR FIRST TRY VS YOUR REVIEW';
  static const String firstTry = 'First try';
  static const String now = 'Review';
  static const String skillsHeading = 'SKILL BY SKILL';
  static const String honestHeading = 'HOW TO READ THIS';
  static const String honest =
      'Both numbers come from the game\'s own scoring of the lines you chose and the reasons '
      'you gave, so they compare like for like. They show how your choices changed between '
      'Mission 1 and the review, not how a real interview would go, and they promise no offer.';
  static const String nextKicker = 'COMING NEXT';
  static const String nextLine =
      'Chapter 2 isn\'t in this version yet. Ask to hear when it opens: nothing is sent '
      'anywhere but your own file.';
  static const String join = 'Tell me when it opens';
  static const String joined = 'You\'re on the list';
  static const String backToTower = 'Back to the tower';
  static const String notYetTitle = 'Your report isn\'t ready yet';
  static String notYetLine(Mission review) =>
      'It opens when you finish Mission ${review.number}, “${review.title}”: the review that '
      'shows how far you\'ve come since Mission 1.';

  @override
  ConsumerState<ChapterReportScreen> createState() =>
      _ChapterReportScreenState();
}

class _ChapterReportScreenState extends ConsumerState<ChapterReportScreen> {
  @override
  void initState() {
    super.initState();
    ref.invalidate(chapterReportProvider);
    ref.read(analyticsProvider).track(AnalyticsEvent.progressReportViewed, {
      'source': const EventValue.name(ProgressSource.chapterReport),
    });
  }

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(chapterReportProvider);
    final state = reading.value;
    final name =
        (ref.watch(profileProvider).value ?? const PlayerProfile()).displayName;
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
                      child: switch (state) {
                        null when reading.hasError => FileTrouble(
                          onRetry: () => ref.invalidate(chapterReportProvider),
                        ),
                        null => const SizedBox.shrink(),
                        ReportNotYet(:final review) => _NotYet(review: review),
                        ReportReady(:final report) => _Report(
                          report: report,
                          name: name,
                        ),
                      },
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
            label: '‹  ${ChapterReportScreen.back}',
            primary: false,
            onPressed: onBack,
          ),
          const SizedBox(width: BrandSpace.md),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                ChapterReportScreen.title,
                style: BrandVividType.title,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A rounded card on the sky.
class _Card extends StatelessWidget {
  const _Card({required this.child, required this.colors, this.glow});

  final Widget child;
  final List<Color> colors;
  final Color? glow;

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BrandSpace.md),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
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
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.md + 4),
        child: child,
      ),
    ),
  );
}

/// The review isn't played yet: what opens the report, and the way back.
class _NotYet extends StatelessWidget {
  const _NotYet({required this.review});

  final Mission review;

  @override
  Widget build(BuildContext context) => _Card(
    colors: [BrandVivid.locked, BrandVivid.night],
    child: Column(
      children: [
        LockGlyph(color: BrandVivid.onDeepSoft, size: 28),
        const SizedBox(height: BrandSpace.md),
        Semantics(
          header: true,
          child: Text(
            ChapterReportScreen.notYetTitle,
            textAlign: TextAlign.center,
            style: BrandVividType.title,
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        Text(
          ChapterReportScreen.notYetLine(review),
          textAlign: TextAlign.center,
          style: BrandVividType.body,
        ),
        const SizedBox(height: BrandSpace.lg),
        VividButton(
          label: ChapterReportScreen.backToTower,
          expand: true,
          onPressed: () => context.go(Routes.tower()),
        ),
      ],
    ),
  );
}

class _Report extends ConsumerWidget {
  const _Report({required this.report, required this.name});

  final ChapterReport report;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const grade = ChapterGrade.lobby;
    final then = report.firstTry;
    final now = report.latest;
    final profile = ref.watch(profileProvider).value ?? const PlayerProfile();
    final next = chapters.where((c) => c.number == report.chapter.number + 1);
    var i = 0;
    Widget enter(Widget child) => StaggeredEntrance(index: i++, child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(
          _Card(
            colors: grade.cardGradient,
            glow: grade.glow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · ${ChapterReportScreen.kicker}',
                  style: BrandVividType.kicker,
                ),
                const SizedBox(height: BrandSpace.xs),
                Text(report.chapter.title, style: BrandVividType.hero),
                const SizedBox(height: BrandSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: _Big(
                        label: '${ChapterReportScreen.firstTry} · Mission 1',
                        value: then.total,
                      ),
                    ),
                    Text('→', style: BrandVividType.title),
                    const SizedBox(width: BrandSpace.md),
                    Expanded(
                      child: _Big(
                        label:
                            '${ChapterReportScreen.now} · Mission ${report.review.number}',
                        value: now.total,
                        lit: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BrandSpace.sm),
                Text(
                  changeWords(report.overall),
                  style: BrandVividType.row.copyWith(color: BrandVivid.accent),
                ),
              ],
            ),
          ),
        ),
        enter(
          _Card(
            colors: [BrandVivid.night, BrandVivid.skyMid],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ChapterReportScreen.skillsHeading,
                  style: BrandVividType.kicker.copyWith(
                    color: BrandVivid.accent,
                  ),
                ),
                const SizedBox(height: BrandSpace.sm),
                Center(
                  child: _ThenNowRadar(then: then, now: now),
                ),
                const SizedBox(height: BrandSpace.sm),
                const _Legend(),
                for (final d in Dimension.values)
                  _SkillRow(
                    label: dimensionLabel(d),
                    then: then.dimensions[d]!,
                    now: now.dimensions[d]!,
                    words: changeWords(report.skill(d)),
                  ),
              ],
            ),
          ),
        ),
        enter(
          _Card(
            colors: [BrandVivid.night, BrandVivid.locked],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChapterReportScreen.honestHeading,
                  style: BrandVividType.kicker,
                ),
                const SizedBox(height: BrandSpace.xs),
                Text(ChapterReportScreen.honest, style: BrandVividType.body),
              ],
            ),
          ),
        ),
        if (next.isNotEmpty)
          enter(
            _NextChapter(
              chapter: next.first,
              joined: profile.waitlistJoinedAt != null,
              onJoin: () => ref.read(profileProvider.notifier).joinWaitlist(),
            ),
          ),
        enter(
          VividButton(
            label: ChapterReportScreen.backToTower,
            expand: true,
            onPressed: () => context.go(Routes.tower()),
          ),
        ),
      ],
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value, this.lit = false});

  final String label;
  final int value;
  final bool lit;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value out of 100',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: BrandVividType.numeral.copyWith(
            color: lit ? BrandVivid.accent : BrandVivid.onDeep,
          ),
        ),
        Text(label.toUpperCase(), style: BrandVividType.kicker),
      ],
    ),
  );
}

/// The first try's shape under the review's, on one radar.
class _ThenNowRadar extends StatelessWidget {
  const _ThenNowRadar({required this.then, required this.now});

  final MissionScore then;
  final MissionScore now;

  @override
  Widget build(BuildContext context) {
    final labels = [for (final d in Dimension.values) dimensionLabel(d)];
    return Semantics(
      label: [
        for (final d in Dimension.values)
          '${dimensionLabel(d)}: ${then.dimensions[d]} then, ${now.dimensions[d]} now',
      ].join('. '),
      excludeSemantics: true,
      child: Stack(
        children: [
          SkillRadar(
            values: [for (final d in Dimension.values) then.dimensions[d]!],
            // The labels are drawn once, by the radar on top.
            labels: [for (final _ in labels) ''],
            color: BrandVivid.onDeepSoft,
            outline: BrandVivid.onDeepSoft,
          ),
          SkillRadar(
            values: [for (final d in Dimension.values) now.dimensions[d]!],
            labels: labels,
            color: ChapterGrade.lobby.glow,
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const double _dot = 10;

  @override
  Widget build(BuildContext context) {
    Widget key(Color c, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _dot,
          height: _dot,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: BrandSpace.xs),
        Text(text, style: BrandVividType.body),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: BrandSpace.lg,
        children: [
          key(BrandVivid.onDeepSoft, ChapterReportScreen.firstTry),
          key(ChapterGrade.lobby.glow, ChapterReportScreen.now),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.label,
    required this.then,
    required this.now,
    required this.words,
  });

  final String label;
  final int then;
  final int now;
  final String words;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BrandSpace.md),
    child: Semantics(
      label: '$label: $then then, $now now. $words.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: BrandVividType.kicker.copyWith(
                    color: ChapterGrade.lobby.glow,
                  ),
                ),
              ),
              Text('$then → $now', style: BrandVividType.row),
            ],
          ),
          Text(words, style: BrandVividType.body),
        ],
      ),
    ),
  );
}

/// The next chapter: what it holds, that it isn't here yet, and the waitlist (D1, FR-5).
class _NextChapter extends StatelessWidget {
  const _NextChapter({
    required this.chapter,
    required this.joined,
    required this.onJoin,
  });

  final Chapter chapter;
  final bool joined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final grade = ChapterGrade.values[chapter.number - 1];
    return _Card(
      colors: grade.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ChapterReportScreen.nextKicker} · CHAPTER ${chapter.number}',
            style: BrandVividType.kicker,
          ),
          const SizedBox(height: BrandSpace.xs),
          Text(chapter.title, style: BrandVividType.title),
          const SizedBox(height: BrandSpace.sm),
          Wrap(
            spacing: BrandSpace.xs,
            runSpacing: BrandSpace.xs,
            children: [
              for (final t in chapter.missionTitles)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandVivid.night.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(BrandRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BrandSpace.sm + 4,
                      vertical: BrandSpace.xs,
                    ),
                    child: Text(t, style: BrandVividType.body),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BrandSpace.md),
          Text(ChapterReportScreen.nextLine, style: BrandVividType.body),
          const SizedBox(height: BrandSpace.md),
          VividButton(
            label: joined
                ? ChapterReportScreen.joined
                : ChapterReportScreen.join,
            primary: !joined,
            expand: true,
            onPressed: joined ? null : onJoin,
          ),
        ],
      ),
    );
  }
}
