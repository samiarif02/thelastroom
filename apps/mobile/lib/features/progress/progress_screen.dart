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
import '../debrief/debrief_facts.dart';
import '../mission/mission_lookup.dart';
import '../tower/tower_hero.dart';
import '../tower/tower_rooms.dart';
import 'progress_facts.dart';

/// Where the progress file was opened from (`progress_report_viewed`'s `source`).
enum ProgressSource { tower }

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
  static const String on = 'On';
  static const String off = 'Off';

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
    final report = ref.watch(progressReportProvider).value;
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
                          if (report != null) ...[
                            enter(
                              _Summary(
                                report: report,
                                name: profile.displayName,
                              ),
                            ),
                            enter(_Skills(skills: report.skills)),
                            enter(const _Section(ProgressScreen.missions)),
                            for (final line in report.missions)
                              enter(_MissionCard(line: line)),
                          ],
                          enter(const _Section(ProgressScreen.settings)),
                          enter(
                            _Panel(
                              child: Column(
                                children: [
                                  _Setting(
                                    label: ProgressScreen.autoAdvance,
                                    on: profile.autoAdvance,
                                    onChanged: (v) => profiles.change(
                                      (p) => p.copyWith(autoAdvance: v),
                                    ),
                                  ),
                                  _Setting(
                                    label: ProgressScreen.calmMode,
                                    on: profile.calmMode,
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
              child: const Text(
                ProgressScreen.title,
                style: BrandVividType.title,
              ),
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
                  const Text('DONE', style: BrandVividType.kicker),
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
      colors: const [BrandVivid.night, BrandVivid.skyMid],
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
            const Text(ProgressScreen.skillsEmpty, style: BrandVividType.body)
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
  const _MissionCard({required this.line});

  final MissionProgress line;

  @override
  Widget build(BuildContext context) {
    final m = line.mission;
    final grade = m.grade;
    final latest = line.latest;
    final lesson = line.lessonToWorkOn;
    final best = line.best;
    return _Panel(
      colors: latest == null
          ? const [BrandVivid.locked, BrandVivid.night]
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
            const Text(ProgressScreen.notPlayed, style: BrandVividType.body),
          ] else ...[
            const SizedBox(height: BrandSpace.sm),
            Wrap(
              spacing: BrandSpace.xs,
              runSpacing: BrandSpace.xs,
              children: [
                _Chip('LATEST', '${latest.total}'),
                _Chip(
                  line.attemptCount == 1 ? 'ATTEMPT' : 'ATTEMPTS',
                  '${line.attemptCount}',
                ),
                for (final d in Dimension.values)
                  _Chip(
                    dimensionLabel(d).toUpperCase(),
                    '${latest.dimensions[d]}',
                  ),
              ],
            ),
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
  const _Panel({
    required this.child,
    this.colors = const [BrandVivid.locked, BrandVivid.night],
    this.glow,
  });

  final Widget child;
  final List<Color> colors;
  final Color? glow;

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

/// One play setting: its line and a switch drawn in the accent.
class _Setting extends StatelessWidget {
  const _Setting({
    required this.label,
    required this.on,
    required this.onChanged,
  });

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  static const double _trackW = 52;
  static const double _trackH = 30;
  static const double _knob = 24;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      toggled: on,
      label: label,
      excludeSemantics: true,
      onTap: () => onChanged(!on),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!on),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
          child: Row(
            children: [
              Expanded(child: Text(label, style: BrandVividType.row)),
              const SizedBox(width: BrandSpace.sm),
              ExcludeSemantics(
                child: Text(
                  (on ? ProgressScreen.on : ProgressScreen.off).toUpperCase(),
                  style: BrandVividType.kicker,
                ),
              ),
              const SizedBox(width: BrandSpace.sm),
              AnimatedContainer(
                duration: still ? Duration.zero : BrandMotion.quick,
                width: _trackW,
                height: _trackH,
                padding: const EdgeInsets.all((_trackH - _knob) / 2),
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: on ? BrandVivid.accent : BrandVivid.locked,
                  borderRadius: BorderRadius.circular(BrandRadius.pill),
                  border: Border.all(color: BrandVivid.hairline(0.3)),
                ),
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandVivid.onDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
