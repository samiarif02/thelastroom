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
import '../debrief/ai_score_store.dart';
import '../debrief/debrief_facts.dart';
import '../mission/mission_lookup.dart';
import '../progression/progression.dart';
import '../progression/progression_card.dart';
import '../progression/skill_badges.dart' show SkillCopy;
import '../progression/skills_shelf.dart';
import 'chapter_report.dart';
import 'chapter_report_screen.dart';
import 'file_trouble.dart';
import 'progress_facts.dart';

/// Where the progress file was opened from (`progress_report_viewed`'s `source`): "Your file"
/// from the tower, or the Chapter 1 report (brief 24).
enum ProgressSource { tower, chapterReport }

/// Your file (FR-16, FR-41; Daylight in brief 48), the tower's Skills tab: a profile you'd want
/// to open. On paper, from the top: the progress hero (XP, the weekly ring, rooms lit, the
/// average and the change since room 1), the skills shelf with the next one to earn, the four
/// scores as a radar, the Chapter 1 report, every room grouped by floor in its floor's colour
/// (a played room shows its latest score and opens its last result), and how you play. Every
/// state is drawn: loading (a skeleton of the hero and rooms), nothing played (an empty hero
/// with "Start room 1"), part played, everything played, and a file that won't read. It's all
/// read from this phone, so it's the same offline.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  static const String title = 'Your file';
  static const String kicker = 'Skills';
  static const String back = 'Back to the tower';
  static const String notPlayed = 'Not played yet';
  static const String upNext = 'Up next';
  static const String skillsEmpty =
      'Your four scores show here after your first room.';
  static const String scoresTitle = 'Your four scores';
  static const String scoresAside = 'Your latest try at each room';
  static const String roomsTitle = 'Rooms';
  static String roomsAside(int done, int of) => '$done of $of played';
  static const String settings = 'How you play';
  static const String autoAdvance = 'Lines move on by themselves';
  static const String calmMode = 'Calm mode: no answer timer';
  static const String aiScored = 'AI score';
  static const String offline = 'Offline score';
  static const String emptyLine =
      'Your file fills in as you play. Room 1 takes about five minutes.';
  static String start(int room) => 'Start room $room';
  static String roomsLit(int done, int of) => '$done of $of rooms lit';
  static String opensAfter(int room) => 'Opens after room $room';
  static String nextSkill(Skill s) => 'Next: ${SkillCopy.name(s)}';
  static String earnIt(Skill s) =>
      'Earn it in ${SkillCopy.where(s).toLowerCase()}, with no hints.';
  static const String allSkills = 'All four skills earned.';
  static String tries(int n) => n == 1 ? '1 try' : '$n tries';

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

  static final List<String> _labels = [
    for (final d in Dimension.values) dimensionLabel(d),
  ];

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(progressReportProvider);
    final report = reading.value;
    final aiScores =
        ref.watch(latestAiScoresProvider).value ??
        const <String, SavedAiScore>{};
    final profile = ref.watch(profileProvider).value ?? const PlayerProfile();
    final unlocked =
        ref.watch(progressionProvider).value?.unlocked ?? const <Skill>{};
    final profiles = ref.read(profileProvider.notifier);
    var i = 0;
    Widget enter(Widget child, {double gap = DaylightSpace.s24}) => Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Entrance(index: i++, child: child),
    );
    final List<Widget> body;
    if (report == null && reading.hasError) {
      body = [
        enter(
          FileTrouble(onRetry: () => ref.invalidate(progressReportProvider)),
        ),
      ];
    } else if (report == null) {
      body = [const _Skeleton()];
    } else {
      final skills = report.skills;
      body = [
        enter(_Hero(report: report)),
        enter(_Skills(unlocked: unlocked)),
        enter(
          _Section(
            title: ProgressScreen.scoresTitle,
            aside: skills == null ? null : ProgressScreen.scoresAside,
            child: DaylightPanel(
              child: Column(
                children: [
                  Center(
                    child: skills == null
                        ? DaylightRadar.empty(labels: _labels)
                        : DaylightRadar(
                            labels: _labels,
                            layers: [
                              RadarLayer(
                                values: [
                                  for (final d in Dimension.values) skills[d]!,
                                ],
                                fill: DaylightFloors.one.base,
                              ),
                            ],
                          ),
                  ),
                  if (skills == null) ...[
                    const SizedBox(height: DaylightSpace.s8),
                    Text(
                      ProgressScreen.skillsEmpty,
                      textAlign: TextAlign.center,
                      style: DaylightType.body6.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        enter(_ReportCard(state: ref.watch(chapterReportProvider).value)),
        enter(
          _Section(
            title: ProgressScreen.roomsTitle,
            aside: ProgressScreen.roomsAside(report.done, report.total),
            child: _Rooms(report: report, aiScores: aiScores),
          ),
        ),
        enter(
          _Section(
            title: ProgressScreen.settings,
            child: DaylightPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: DaylightSpace.s16,
                vertical: DaylightSpace.s4,
              ),
              child: Column(
                children: [
                  SwitchRow(
                    label: ProgressScreen.autoAdvance,
                    value: profile.autoAdvance,
                    onChanged: (v) =>
                        profiles.change((p) => p.copyWith(autoAdvance: v)),
                  ),
                  SwitchRow(
                    label: ProgressScreen.calmMode,
                    value: profile.calmMode,
                    onChanged: (v) =>
                        profiles.change((p) => p.copyWith(calmMode: v)),
                  ),
                ],
              ),
            ),
          ),
          gap: 0,
        ),
      ];
    }
    return DaylightGround(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DaylightTopBar(
              leadingIcon: PhosphorBold.arrowLeft,
              leadingLabel: ProgressScreen.back,
              onLeading: () => context.go(Routes.tower()),
              kicker: ProgressScreen.kicker,
              title: ProgressScreen.title,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: body,
                    ),
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

String _signed(int n) => n > 0 ? '+$n' : '$n';

/// The hero: the progression card with the file's three numbers under it, and on an empty
/// file the way into room 1.
class _Hero extends StatelessWidget {
  const _Hero({required this.report});

  final ProgressReport report;

  static const String litLabel = 'Rooms lit';
  static const String averageLabel = 'Average';
  static const String sinceLabel = 'Since room 1';
  static const String none = '–';
  static const String noneYet = 'none yet';

  @override
  Widget build(BuildContext context) {
    final delta = report.sinceBaseline?.totalDelta;
    final average = report.average;
    final first = missions.first.number;
    return ProgressionCard(
      stats: [
        HeroStat(
          label: litLabel,
          value: '${report.done}',
          after: 'of ${report.total}',
          semanticLabel: ProgressScreen.roomsLit(report.done, report.total),
        ),
        HeroStat(
          label: averageLabel,
          value: average == null ? none : '$average',
          semanticLabel: '$averageLabel: ${average ?? noneYet}',
        ),
        HeroStat(
          label: sinceLabel,
          value: delta == null ? none : _signed(delta),
          semanticLabel:
              '$sinceLabel: ${delta == null ? noneYet : _signed(delta)}',
        ),
      ],
      footer: report.done > 0
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ProgressScreen.emptyLine,
                  style: DaylightType.body5.copyWith(
                    color: DaylightColors.raised,
                  ),
                ),
                const SizedBox(height: DaylightSpace.s12),
                TactileButton(
                  label: ProgressScreen.start(first),
                  icon: PhosphorFill.play,
                  tone: TactileTone.floor,
                  compact: true,
                  onPressed: () => context.go(Routes.mission(first)),
                ),
              ],
            ),
    );
  }
}

/// A section on the paper: its head, then its content 12 below.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.aside});

  final String title;
  final String? aside;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHead(title: title, aside: aside),
      const SizedBox(height: DaylightSpace.s12),
      child,
    ],
  );
}

/// The skills shelf (the tower's, with real names: earned, next, locked), and what the next
/// one asks of you.
class _Skills extends StatelessWidget {
  const _Skills({required this.unlocked});

  final Set<Skill> unlocked;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final upcoming = SkillsShelf.next(unlocked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkillsShelf(unlocked: unlocked),
        const SizedBox(height: DaylightSpace.s16),
        DaylightPanel(
          color: DaylightColors.honeyTint,
          edge: null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: DaylightColors.honey,
                  borderRadius: BorderRadius.circular(DaylightRadius.inner),
                ),
                child: Icon(
                  upcoming == null
                      ? PhosphorFill.trophy
                      : SkillCopy.icon(upcoming),
                  size: DaylightSpace.s24,
                  color: DaylightColors.onHoney,
                ),
              ),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: upcoming == null
                    ? Text(ProgressScreen.allSkills, style: DaylightType.body1)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ProgressScreen.nextSkill(upcoming),
                            style: DaylightType.body1,
                          ),
                          const SizedBox(height: DaylightSpace.s2),
                          Text(
                            SkillCopy.meaning(upcoming),
                            style: DaylightType.body6,
                          ),
                          const SizedBox(height: DaylightSpace.s4),
                          Text(
                            ProgressScreen.earnIt(upcoming),
                            style: DaylightType.caption4.copyWith(
                              color: DaylightColors.honeyInk,
                            ),
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

/// The Chapter 1 report's way in: open once the review is played (white, a button), until then
/// a flat sand card with a lock that says what opens it.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.state});

  final ChapterReportState? state;

  static const String title = 'Chapter 1 report';
  static const String open =
      'Your first try against your review, skill by skill.';
  static const String openButton = 'Open the report';
  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null) return const SizedBox.shrink();
    final ready = s is ReportReady;
    const f = DaylightFloors.one;
    return DaylightPanel(
      color: ready ? DaylightColors.raised : DaylightColors.sand,
      edge: ready ? DaylightColors.sand2 : null,
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
                  color: ready ? f.tint : DaylightColors.sand2,
                  borderRadius: BorderRadius.circular(DaylightRadius.inner),
                ),
                child: Icon(
                  ready ? PhosphorBold.trendUp : PhosphorBold.lockSimple,
                  size: DaylightSpace.s24,
                  color: ready ? f.deep : DaylightColors.ink2,
                ),
              ),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: DaylightType.heading6),
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Text(
                      switch (s) {
                        ReportReady() => open,
                        ReportNotYet(:final review) =>
                          ChapterReportScreen.notYetLine(review),
                      },
                      style: DaylightType.body6.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ready) ...[
            const SizedBox(height: DaylightSpace.s16),
            TactileButton(
              label: openButton,
              compact: true,
              icon: PhosphorBold.arrowRight,
              onPressed: () => context.go(Routes.report),
            ),
          ],
        ],
      ),
    );
  }
}

/// How a room stands in the file.
enum _RoomStand { played, next, locked }

/// Every room, grouped by floor in its floor's colour. A floor with a room open lists its
/// rooms; a floor not reached yet folds into one flat card that names its rooms and what opens
/// it.
class _Rooms extends StatelessWidget {
  const _Rooms({required this.report, required this.aiScores});

  final ProgressReport report;
  final Map<String, SavedAiScore> aiScores;

  @override
  Widget build(BuildContext context) {
    // The first room not played is next; every one after it is still locked.
    final stands = <String, _RoomStand>{};
    var nextGiven = false;
    for (final line in report.missions) {
      if (line.played) {
        stands[line.mission.id] = _RoomStand.played;
      } else if (!nextGiven) {
        stands[line.mission.id] = _RoomStand.next;
        nextGiven = true;
      } else {
        stands[line.mission.id] = _RoomStand.locked;
      }
    }
    final floors = <int, List<MissionProgress>>{};
    for (final line in report.missions) {
      (floors[line.mission.chapter] ??= []).add(line);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, c) in chapters.indexed)
          if (floors[c.number] case final lines?) ...[
            if (i > 0) const SizedBox(height: DaylightSpace.s24),
            _FloorGroup(
              chapter: c,
              lines: lines,
              stands: stands,
              aiScores: aiScores,
            ),
          ],
      ],
    );
  }
}

class _FloorGroup extends StatelessWidget {
  const _FloorGroup({
    required this.chapter,
    required this.lines,
    required this.stands,
    required this.aiScores,
  });

  final Chapter chapter;
  final List<MissionProgress> lines;
  final Map<String, _RoomStand> stands;
  final Map<String, SavedAiScore> aiScores;

  static const double _swatchW = 16;
  static const double _swatchH = 20;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[chapter.number - 1].floor;
    final played = lines.where((l) => l.played).length;
    final reached = lines.any((l) => stands[l.mission.id] != _RoomStand.locked);
    final previousLast = missions
        .where((m) => m.chapter < chapter.number)
        .lastOrNull;
    return ChapterTint(
      floor: f,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Container(
                  width: _swatchW,
                  height: _swatchH,
                  decoration: BoxDecoration(
                    color: f.base,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DaylightRadius.archTop),
                      bottom: Radius.circular(DaylightSpace.s2),
                    ),
                  ),
                ),
                const SizedBox(width: DaylightSpace.s8),
                Expanded(
                  child: Text(
                    'Floor ${chapter.number} · ${chapter.title}',
                    style: DaylightType.title3.copyWith(color: f.deep),
                  ),
                ),
                const SizedBox(width: DaylightSpace.s8),
                Text(
                  '$played of ${lines.length}',
                  style: DaylightType.tabular(DaylightType.body6)
                      .copyWith(color: DaylightColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: DaylightSpace.s12),
          if (reached)
            for (final (i, line) in lines.indexed) ...[
              if (i > 0) const SizedBox(height: DaylightSpace.s8),
              switch (stands[line.mission.id]!) {
                _RoomStand.played => _PlayedRoom(
                  line: line,
                  ai: aiFor(line, aiScores),
                ),
                _RoomStand.next => _NextRoom(mission: line.mission),
                _RoomStand.locked => _LockedRoom(mission: line.mission),
              },
            ]
          else
            _LockedFloor(lines: lines, opensAfter: previousLast?.number),
        ],
      ),
    );
  }
}

/// The room's number in a small arch: honey once played, the floor's colour for the room up
/// next, sand with a lock for one still closed.
class _RoomArch extends StatelessWidget {
  const _RoomArch({required this.number, required this.stand});

  final int number;
  final _RoomStand stand;

  static const double _w = 36;
  static const double _h = 44;
  static const double _lock = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final (ground, ink) = switch (stand) {
      _RoomStand.played => (DaylightColors.honey, DaylightColors.onHoney),
      _RoomStand.next => (f.base, DaylightColors.raised),
      _RoomStand.locked => (DaylightColors.sand2, DaylightColors.ink2),
    };
    return SizedBox(
      width: _w,
      height: _h,
      child: ArchFrame(
        ground: ground,
        bottomRadius: DaylightRadius.tag,
        child: Align(
          alignment: const Alignment(0, 0.4),
          child: stand == _RoomStand.locked
              ? Icon(PhosphorBold.lockSimple, size: _lock, color: ink)
              : Text(
                  '$number',
                  style: DaylightType.tabular(DaylightType.body4)
                      .copyWith(color: ink),
                ),
        ),
      ),
    );
  }
}

/// A played room: a white card on its edge that opens the room's last result. Its latest
/// score (the AI's when it scored that try) sits in the floor's tint, with the best, the tries
/// and who scored it under the title.
class _PlayedRoom extends StatelessWidget {
  const _PlayedRoom({required this.line, this.ai});

  final MissionProgress line;
  final SavedAiScore? ai;

  static const double _score = 48;
  static const double _caret = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final m = line.mission;
    final latest = ai?.score.overall.score ?? line.latest!.total;
    final source = ai == null
        ? ProgressScreen.offline
        : ProgressScreen.aiScored;
    final meta =
        'Best ${line.best} · ${ProgressScreen.tries(line.attemptCount)}';
    return Tactile(
      label:
          'Room ${m.number}, ${m.title}. Latest $latest, $meta, $source. '
          'Opens your last result.',
      onTap: () => context.go(Routes.result(m.number)),
      style: TactileStyle(
        face: DaylightColors.raised,
        edge: DaylightColors.sand2,
        radius: BorderRadius.circular(DaylightRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Row(
          children: [
            _RoomArch(number: m.number, stand: _RoomStand.played),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title, style: DaylightType.body1),
                  const SizedBox(height: DaylightSpace.s2),
                  Text(
                    meta,
                    style: DaylightType.tabular(DaylightType.caption4)
                        .copyWith(color: DaylightColors.ink2),
                  ),
                  const SizedBox(height: DaylightSpace.s4),
                  Tag(
                    label: source,
                    icon: ai == null
                        ? PhosphorRegular.wifiSlash
                        : PhosphorFill.sparkle,
                    tone: ai == null ? TagTone.sand : TagTone.floor(f),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DaylightSpace.s8),
            Container(
              constraints: const BoxConstraints(minWidth: _score),
              padding: const EdgeInsets.all(DaylightSpace.s8),
              decoration: BoxDecoration(
                color: f.tint,
                borderRadius: BorderRadius.circular(DaylightRadius.inner),
              ),
              alignment: Alignment.center,
              child: Text(
                '$latest',
                style: DaylightType.tabular(DaylightType.heading6)
                    .copyWith(color: f.deep),
              ),
            ),
            const SizedBox(width: DaylightSpace.s4),
            const Icon(
              PhosphorBold.caretRight,
              size: _caret,
              color: DaylightColors.ink2,
            ),
          ],
        ),
      ),
    );
  }
}

/// The room up next: the floor's ring round a white card, and the way in.
class _NextRoom extends StatelessWidget {
  const _NextRoom({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return Tactile(
      label:
          'Room ${mission.number}, ${mission.title}. ${ProgressScreen.upNext}. '
          '${ProgressScreen.start(mission.number)}.',
      onTap: () => context.go(Routes.mission(mission.number)),
      style: TactileStyle(
        face: DaylightColors.raised,
        edge: f.base,
        radius: BorderRadius.circular(DaylightRadius.card),
        ring: f.base,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Row(
          children: [
            _RoomArch(number: mission.number, stand: _RoomStand.next),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mission.title, style: DaylightType.body1),
                  const SizedBox(height: DaylightSpace.s2),
                  Text(
                    '${ProgressScreen.notPlayed} · with ${mission.lead.name}',
                    style: DaylightType.caption4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DaylightSpace.s8),
            Tag(
              label: ProgressScreen.upNext,
              icon: PhosphorFill.play,
              tone: TagTone.floor(f),
            ),
          ],
        ),
      ),
    );
  }
}

/// A room on an open floor that isn't open yet: flat sand, no edge, a lock.
class _LockedRoom extends StatelessWidget {
  const _LockedRoom({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final before = missions
        .where((m) => m.number < mission.number)
        .lastOrNull
        ?.number;
    return Semantics(
      label:
          'Room ${mission.number}, ${mission.title}. ${ProgressScreen.notPlayed}. '
          '${before == null ? '' : ProgressScreen.opensAfter(before)}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DaylightColors.sand,
          borderRadius: BorderRadius.circular(DaylightRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DaylightSpace.s12),
          child: Row(
            children: [
              _RoomArch(number: mission.number, stand: _RoomStand.locked),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: DaylightType.body2.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                    if (before != null)
                      Text(
                        ProgressScreen.opensAfter(before),
                        style: DaylightType.caption4.copyWith(
                          color: DaylightColors.ink2,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A floor not reached yet: one flat card, a lock, what opens it, and its rooms by name.
class _LockedFloor extends StatelessWidget {
  const _LockedFloor({required this.lines, required this.opensAfter});

  final List<MissionProgress> lines;
  final int? opensAfter;

  static const double _number = 24;

  @override
  Widget build(BuildContext context) {
    final after = opensAfter;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.sand,
        borderRadius: BorderRadius.circular(DaylightRadius.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  PhosphorBold.lockSimple,
                  size: DaylightSpace.s16,
                  color: DaylightColors.ink2,
                ),
                const SizedBox(width: DaylightSpace.s8),
                Expanded(
                  child: Text(
                    after == null
                        ? ProgressScreen.notPlayed
                        : ProgressScreen.opensAfter(after),
                    style: DaylightType.body4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: DaylightSpace.s4),
                child: Semantics(
                  label:
                      'Room ${line.mission.number}, ${line.mission.title}. '
                      '${ProgressScreen.notPlayed}',
                  excludeSemantics: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: _number,
                        child: Text(
                          '${line.mission.number}',
                          style: DaylightType.tabular(DaylightType.caption3)
                              .copyWith(color: DaylightColors.ink2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line.mission.title,
                          style: DaylightType.body6.copyWith(
                            color: DaylightColors.ink2,
                          ),
                        ),
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

/// While the file reads: the hero and three rooms as sand shapes, not a spinner.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  static const String label = 'Opening your file';
  static const double _hero = 216;
  static const double _head = 24;
  static const double _room = 68;
  static const double _headShare = 0.4;
  static const int _rooms = 3;

  @override
  Widget build(BuildContext context) {
    Widget block(double h, double r) => Container(
      height: h,
      decoration: BoxDecoration(
        color: DaylightColors.sand,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(_hero, DaylightRadius.panel),
          const SizedBox(height: DaylightSpace.s24),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _headShare,
            child: block(_head, DaylightRadius.tag),
          ),
          for (var i = 0; i < _rooms; i++) ...[
            const SizedBox(height: DaylightSpace.s12),
            block(_room, DaylightRadius.card),
          ],
        ],
      ),
    );
  }
}

/// The AI verdict for [line]'s latest attempt, if one was given after that attempt was played.
/// A later attempt played offline shows its own offline score instead.
SavedAiScore? aiFor(MissionProgress line, Map<String, SavedAiScore> scores) {
  final saved = scores[line.mission.id];
  final latest = line.attempts.isEmpty ? null : line.attempts.last;
  if (saved == null || latest == null) return null;
  final played = latest.completedAt;
  return played == null || !saved.at.isBefore(played) ? saved : null;
}
