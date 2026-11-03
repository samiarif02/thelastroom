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
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/daylight/daylight_radar.dart';
import '../debrief/debrief_facts.dart';
import '../debrief/then_now_slip.dart';
import 'chapter_report.dart';
import 'file_trouble.dart';
import 'progress_screen.dart';

/// The Chapter 1 report (brief 24, FR-41; Daylight in brief 48): the first try against the
/// review, skill by skill, with the radar, in honest words; then the next floor and its way in
/// (or its waitlist, D1), and the way back to the tower. On paper: a floor 1 hero with the two
/// totals, the radar with the first try drawn under the review, "Then and now" in the player's
/// own words, how to read it, and the next floor in its own colour. Before the review is
/// played it says what opens it.
class ChapterReportScreen extends ConsumerStatefulWidget {
  const ChapterReportScreen({super.key});

  static const String title = 'Chapter 1 report';
  static const String back = 'Back to the tower';
  static const String kicker = 'Your first try against your review';
  static const String firstTry = 'First try';
  static const String now = 'Review';
  static const String skillsHeading = 'Skill by skill';
  static const String honestHeading = 'How to read this';
  static const String honest =
      'Both numbers come from the game\'s own scoring of the lines you chose and the reasons '
      'you gave, so they compare like for like. They show how your choices changed between '
      'Mission 1 and the review, not how a real interview would go, and they promise no offer.';
  static const String nextKicker = 'Coming next';
  static const String nextLine =
      'Chapter 2 isn\'t in this version yet. Ask to hear when it opens: nothing is sent '
      'anywhere but your own file.';
  static const String join = 'Tell me when it opens';
  static const String upNextKicker = 'Up next';

  /// What an open next chapter says: how it's played (brief 39).
  static String openLine(Chapter next, List<Mission> itsMissions) {
    final voice = itsMissions
        .where((m) => m.answerMode == AnswerMode.voice)
        .length;
    final how = voice == itsMissions.length
        ? 'all answered out loud'
        : voice == 0
        ? 'answered by choosing your lines'
        : '$voice answered out loud, ${itsMissions.length - voice} by choosing your lines';
    return '${itsMissions.length} missions, $how.';
  }

  static String start(Chapter next) => 'Take the lift to floor ${next.number}';
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
    return DaylightGround(
      floor: DaylightFloors.one,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DaylightTopBar(
              leadingIcon: PhosphorBold.arrowLeft,
              leadingLabel: ChapterReportScreen.back,
              onLeading: () => context.go(Routes.tower()),
              kicker: name,
              title: ChapterReportScreen.title,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  DaylightSpace.s16,
                  DaylightSpace.s16,
                  DaylightSpace.s16,
                  DaylightSpace.s32 + MediaQuery.paddingOf(context).bottom,
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
                      ReportReady(:final report) => _Report(report: report),
                    },
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

/// The review isn't played yet: an arch with a lock, what opens the report, and the way back.
class _NotYet extends StatelessWidget {
  const _NotYet({required this.review});

  final Mission review;

  static const double _arch = 72;
  static const double _archHeight = 88;
  static const double _lock = 28;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DaylightPanel(
      padding: const EdgeInsets.all(DaylightSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _arch,
            height: _archHeight,
            child: ArchFrame(
              ground: f.tint,
              child: Icon(PhosphorBold.lockSimple, size: _lock, color: f.deep),
            ),
          ),
          const SizedBox(height: DaylightSpace.s16),
          Semantics(
            header: true,
            child: Text(
              ChapterReportScreen.notYetTitle,
              style: DaylightType.heading5,
            ),
          ),
          const SizedBox(height: DaylightSpace.s8),
          Text(
            ChapterReportScreen.notYetLine(review),
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
          const SizedBox(height: DaylightSpace.s24),
          TactileButton(
            label: ChapterReportScreen.backToTower,
            icon: PhosphorBold.arrowLeft,
            onPressed: () => context.go(Routes.tower()),
          ),
        ],
      ),
    );
  }
}

class _Report extends ConsumerWidget {
  const _Report({required this.report});

  final ChapterReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ChapterTint.floorOf(context);
    final then = report.firstTry;
    final now = report.latest;
    final profile = ref.watch(profileProvider).value ?? const PlayerProfile();
    final next = chapters.where((c) => c.number == report.chapter.number + 1);
    var i = 0;
    Widget enter(Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: DaylightSpace.s24),
      child: Entrance(index: i++, child: child),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(
          DaylightPanel(
            color: f.base,
            edge: f.deep,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChapterReportScreen.kicker,
                  style: DaylightType.caption3.copyWith(color: f.on),
                ),
                const SizedBox(height: DaylightSpace.s4),
                Semantics(
                  header: true,
                  child: Text(
                    report.chapter.title,
                    style: DaylightType.heading4.copyWith(
                      color: DaylightColors.raised,
                    ),
                  ),
                ),
                const SizedBox(height: DaylightSpace.s16),
                Row(
                  children: [
                    Expanded(
                      child: _Big(
                        label: '${ChapterReportScreen.firstTry} · room 1',
                        value: then.total,
                      ),
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    Icon(PhosphorBold.arrowRight, size: _arrow, color: f.on),
                    const SizedBox(width: DaylightSpace.s8),
                    Expanded(
                      child: _Big(
                        label:
                            '${ChapterReportScreen.now} · room ${report.review.number}',
                        value: now.total,
                        lit: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DaylightSpace.s12),
                Row(
                  children: [
                    const Icon(
                      PhosphorBold.trendUp,
                      size: DaylightSpace.s16,
                      color: DaylightColors.honey,
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    Expanded(
                      child: Text(
                        changeWords(report.overall),
                        style: DaylightType.body4.copyWith(
                          color: DaylightColors.raised,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        enter(
          _Block(
            title: ChapterReportScreen.skillsHeading,
            child: DaylightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _ThenNowRadar(then: then, now: now),
                  ),
                  const SizedBox(height: DaylightSpace.s8),
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
        ),
        if (report.firstDraft case final draft?)
          enter(
            ThenNowSlip(
              then: draft,
              now: report.latestAnswer,
              nowMission: report.review.number,
            ),
          ),
        enter(
          DaylightPanel(
            color: DaylightColors.sand,
            edge: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      PhosphorBold.bookOpen,
                      size: DaylightSpace.s16,
                      color: DaylightColors.ink2,
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    Text(
                      ChapterReportScreen.honestHeading,
                      style: DaylightType.body4,
                    ),
                  ],
                ),
                const SizedBox(height: DaylightSpace.s8),
                Text(
                  ChapterReportScreen.honest,
                  style: DaylightType.body6.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
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
              onStart: () => context.go(
                Routes.mission(
                  missions
                      .firstWhere((m) => m.chapter == next.first.number)
                      .number,
                ),
              ),
            ),
          ),
        Entrance(
          index: i,
          child: TactileButton(
            label: ChapterReportScreen.backToTower,
            tone: TactileTone.quiet,
            icon: PhosphorBold.arrowLeft,
            onPressed: () => context.go(Routes.tower()),
          ),
        ),
      ],
    );
  }

  static const double _arrow = 20;
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHead(title: title),
      const SizedBox(height: DaylightSpace.s12),
      child,
    ],
  );
}

/// One of the hero's two totals, on the floor's deep colour.
class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value, this.lit = false});

  final String label;
  final int value;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return Semantics(
      label: '$label: $value out of 100',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: lit ? DaylightColors.raised : f.deep,
          borderRadius: BorderRadius.circular(DaylightRadius.inner),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DaylightSpace.s12,
            DaylightSpace.s8,
            DaylightSpace.s12,
            DaylightSpace.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                style: DaylightType.caption4.copyWith(
                  color: lit ? f.deep : f.on,
                ),
              ),
              Text(
                '$value',
                style: DaylightType.tabular(DaylightType.heading2)
                    .copyWith(color: lit ? f.deep : DaylightColors.raised),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The first try's shape under the review's, on one radar.
class _ThenNowRadar extends StatelessWidget {
  const _ThenNowRadar({required this.then, required this.now});

  final MissionScore then;
  final MissionScore now;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DaylightRadar(
      semanticLabel: [
        for (final d in Dimension.values)
          '${dimensionLabel(d)}: ${then.dimensions[d]} then, ${now.dimensions[d]} now',
      ].join('. '),
      labels: [for (final d in Dimension.values) dimensionLabel(d)],
      layers: [
        RadarLayer(
          values: [for (final d in Dimension.values) then.dimensions[d]!],
          outline: DaylightColors.ink3,
        ),
        RadarLayer(
          values: [for (final d in Dimension.values) now.dimensions[d]!],
          fill: f.base,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const double _dot = 10;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    Widget key(Color c, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _dot,
          height: _dot,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(DaylightSpace.s2),
          ),
        ),
        const SizedBox(width: DaylightSpace.s8),
        Text(
          text,
          style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
        ),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: DaylightSpace.s24,
        children: [
          key(DaylightColors.ink3, ChapterReportScreen.firstTry),
          key(f.base, ChapterReportScreen.now),
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
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s16),
      child: Semantics(
        label: '$label: $then then, $now now. $words.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(label, style: DaylightType.title4)),
                Text(
                  '$then → $now',
                  style: DaylightType.tabular(DaylightType.body4),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s4),
            ProgressTrack(value: now / 100, fill: f.base),
            const SizedBox(height: DaylightSpace.s4),
            Text(
              words,
              style: DaylightType.caption4.copyWith(color: DaylightColors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

/// The next floor after the report, in its own colour: open (brief 39), it takes the lift
/// there; still locked, it offers the waitlist (D1).
class _NextChapter extends StatelessWidget {
  const _NextChapter({
    required this.chapter,
    required this.joined,
    required this.onJoin,
    required this.onStart,
  });

  final Chapter chapter;
  final bool joined;
  final VoidCallback onJoin;
  final VoidCallback onStart;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[chapter.number - 1].floor;
    return ChapterTint(
      floor: f,
      child: DaylightPanel(
        color: f.base,
        edge: f.deep,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _tile,
                  height: _tile,
                  decoration: BoxDecoration(
                    color: f.soft,
                    borderRadius: BorderRadius.circular(DaylightRadius.inner),
                  ),
                  child: Icon(
                    chapter.playable
                        ? PhosphorBold.lockSimpleOpen
                        : PhosphorBold.lockSimple,
                    size: DaylightSpace.s24,
                    color: f.deep,
                  ),
                ),
                const SizedBox(width: DaylightSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${chapter.playable ? ChapterReportScreen.upNextKicker : ChapterReportScreen.nextKicker} · floor ${chapter.number}',
                        style: DaylightType.caption3.copyWith(color: f.on),
                      ),
                      Text(
                        chapter.title,
                        style: DaylightType.heading5.copyWith(
                          color: DaylightColors.raised,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s12),
            Text(
              chapter.playable
                  ? ChapterReportScreen.openLine(chapter, [
                      for (final m in missions)
                        if (m.chapter == chapter.number) m,
                    ])
                  : ChapterReportScreen.nextLine,
              style: DaylightType.body5.copyWith(color: DaylightColors.raised),
            ),
            const SizedBox(height: DaylightSpace.s12),
            Wrap(
              spacing: DaylightSpace.s8,
              runSpacing: DaylightSpace.s8,
              children: [
                for (final t in chapter.missionTitles)
                  Tag(label: t, tone: TagTone.onFloor(f)),
              ],
            ),
            const SizedBox(height: DaylightSpace.s16),
            if (chapter.playable)
              TactileButton(
                label: ChapterReportScreen.start(chapter),
                icon: PhosphorBold.elevator,
                tone: TactileTone.floor,
                compact: true,
                onPressed: onStart,
              )
            else
              TactileButton(
                label: joined
                    ? ChapterReportScreen.joined
                    : ChapterReportScreen.join,
                icon: joined ? PhosphorBold.check : PhosphorBold.bell,
                tone: TactileTone.floor,
                compact: true,
                onPressed: joined ? null : onJoin,
              ),
          ],
        ),
      ),
    );
  }
}
