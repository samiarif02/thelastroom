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
import '../debrief/red_pen_slip.dart';
import '../mission/widgets/cue_button.dart';
import 'progress_facts.dart';

/// Where the progress file was opened from (`progress_report_viewed`'s `source`).
enum ProgressSource { tower }

/// Progress (FR-16, FR-41), as a candidate file on the desk like the dossier (the owner's
/// favourite look): the Chapter 1 summary on the letterhead, then each mission's slip with its
/// best and latest score, the four dimensions, the attempts and the lesson still to work on.
/// The player's two play settings sit at the end of the file.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  static const String title = 'Candidate file';
  static const String back = 'Back to the tower';
  static const String notPlayed = 'Not played yet';
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

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    final report = ref.watch(progressReportProvider).value;
    final profile = ref.watch(profileProvider).value ?? const PlayerProfile();
    final profiles = ref.read(profileProvider.notifier);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.6),
              radius: 1.3,
              colors: [grade.tint, BrandColors.surface, BrandColors.void_],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BrandSpace.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CueButton(
                        label: ProgressScreen.back,
                        quiet: true,
                        onPressed: () => context.go(Routes.tower()),
                      ),
                    ),
                    const SizedBox(height: BrandSpace.sm),
                    if (report != null) ...[
                      _Summary(report: report, name: profile.displayName),
                      for (final line in report.missions) ...[
                        const SizedBox(height: BrandSpace.md),
                        _MissionSlip(line: line),
                      ],
                    ],
                    const SizedBox(height: BrandSpace.lg),
                    const BrassOrnament(text: ProgressScreen.settings),
                    const SizedBox(height: BrandSpace.sm),
                    _Setting(
                      label: ProgressScreen.autoAdvance,
                      on: profile.autoAdvance,
                      onChanged: (v) =>
                          profiles.change((p) => p.copyWith(autoAdvance: v)),
                    ),
                    _Setting(
                      label: ProgressScreen.calmMode,
                      on: profile.calmMode,
                      onChanged: (v) =>
                          profiles.change((p) => p.copyWith(calmMode: v)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const double _maxWidth = 520;
}

/// The letterhead: who, and Chapter 1 at a glance.
class _Summary extends StatelessWidget {
  const _Summary({required this.report, required this.name});

  final ProgressReport report;
  final String name;

  static const double _titleSize = 30;

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    final delta = report.sinceBaseline?.totalDelta;
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NORTHSTAR LABS', textAlign: TextAlign.center, style: soft),
          const SizedBox(height: BrandSpace.sm),
          Semantics(
            header: true,
            child: Text(
              ProgressScreen.title,
              textAlign: TextAlign.center,
              style: BrandType.display.copyWith(
                color: BrandColors.ink,
                fontSize: _titleSize,
              ),
            ),
          ),
          Text(
            '$name · Chapter 1',
            textAlign: TextAlign.center,
            style: BrandType.body.copyWith(color: BrandColors.inkSoft),
          ),
          const SizedBox(height: BrandSpace.md),
          const DoubleRule(color: BrandColors.inkSoft),
          const SizedBox(height: BrandSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: BrandSpace.md,
            runSpacing: BrandSpace.sm,
            children: [
              _Figure(
                label: 'MISSIONS DONE',
                value: '${report.done} of ${report.total}',
              ),
              _Figure(label: 'AVERAGE', value: '${report.average ?? '–'}'),
              _Figure(
                label: 'SINCE MISSION 1',
                value: delta == null ? '–' : _signed(delta),
              ),
            ],
          ),
          const SizedBox(height: BrandSpace.sm),
          const DoubleRule(color: BrandColors.inkSoft),
        ],
      ),
    );
  }
}

String _signed(int n) => n > 0 ? '+$n' : '$n';

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: BrandType.score),
        Text(
          label,
          style: BrandType.label.copyWith(color: BrandColors.inkSoft),
        ),
      ],
    ),
  );
}

/// One mission's slip.
class _MissionSlip extends StatelessWidget {
  const _MissionSlip({required this.line});

  final MissionProgress line;

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    final latest = line.latest;
    final lesson = line.lessonToWorkOn;
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MISSION ${line.mission.number}', style: soft),
          Semantics(
            header: true,
            child: Text(
              line.mission.title,
              style: BrandType.choice.copyWith(color: BrandColors.ink),
            ),
          ),
          const SizedBox(height: BrandSpace.sm),
          if (latest == null)
            Text(
              ProgressScreen.notPlayed,
              style: BrandType.body.copyWith(color: BrandColors.inkSoft),
            )
          else ...[
            Wrap(
              spacing: BrandSpace.md,
              runSpacing: BrandSpace.xs,
              children: [
                _Pair('BEST', '${line.best}'),
                _Pair('LATEST', '${latest.total}'),
                _Pair(
                  line.attemptCount == 1 ? 'ATTEMPT' : 'ATTEMPTS',
                  '${line.attemptCount}',
                ),
              ],
            ),
            const SizedBox(height: BrandSpace.xs),
            Wrap(
              spacing: BrandSpace.md,
              runSpacing: BrandSpace.xs,
              children: [
                for (final d in Dimension.values)
                  _Pair(
                    dimensionLabel(d).toUpperCase(),
                    '${latest.dimensions[d]}',
                  ),
              ],
            ),
            if (lesson != null) ...[
              const SizedBox(height: BrandSpace.sm),
              Text('STILL TO WORK ON', style: soft),
              Text(
                lesson.title,
                style: BrandType.body.copyWith(color: BrandColors.redPen),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// "BEST 72": a ledger label and its stamped number.
class _Pair extends StatelessWidget {
  const _Pair(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    excludeSemantics: true,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: BrandType.label.copyWith(color: BrandColors.inkSoft),
          ),
          TextSpan(
            text: value,
            style: BrandType.choice.copyWith(color: BrandColors.ink),
          ),
        ],
      ),
    ),
  );
}

/// One play setting: its line and an On/Off plate.
class _Setting extends StatelessWidget {
  const _Setting({
    required this.label,
    required this.on,
    required this.onChanged,
  });

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
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
            Expanded(child: Text(label, style: BrandType.body)),
            const SizedBox(width: BrandSpace.sm),
            Text(
              (on ? ProgressScreen.on : ProgressScreen.off).toUpperCase(),
              style: BrandType.eyebrow.copyWith(
                color: on ? ChapterGrade.lobby.key : BrandColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
