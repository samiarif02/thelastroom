import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/audio/game_sounds.dart';
import '../../core/progress/progress_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/paper/dossier.dart';
import '../debrief/ai_score_store.dart';
import '../debrief/debrief_facts.dart';
import '../debrief/debrief_view.dart' show DebriefView;
import '../mission/mission_lookup.dart';
import '../voice/voice_debrief.dart' show voiceRedPen;
import 'file_trouble.dart';
import 'progress_facts.dart';
import 'progress_screen.dart' show ProgressScreen, aiFor;

/// A played room's attempts, read back from the device for its last result.
class PastResult {
  const PastResult({required this.mission, required this.attempts, this.ai});

  final Mission mission;

  /// Oldest first; empty when the room hasn't been played.
  final List<AttemptRecord> attempts;

  /// The AI recruiter's verdict on the latest attempt, when it scored that one.
  final SavedAiScore? ai;

  AttemptRecord? get latest => attempts.isEmpty ? null : attempts.last;

  /// Each dimension's best across every attempt (the engine's numbers, like for like).
  Map<Dimension, int> get best => {
    for (final d in Dimension.values)
      d: attempts
          .map((a) => a.score.dimensions[d] ?? 0)
          .fold(0, (a, b) => a > b ? a : b),
  };

  /// What the latest attempt shows: the AI's numbers when it scored it, else the engine's.
  Map<Dimension, int> get shown => {
    for (final d in Dimension.values)
      d: ai?.score.dimensions[d]?.score ?? latest?.score.dimensions[d] ?? 0,
  };

  int get shownTotal => ai?.score.overall.score ?? latest?.score.total ?? 0;
}

/// Room [number]'s attempts from the progress store, with the AI's verdict if it scored the
/// latest one. Null for a number that isn't a room.
final pastResultProvider = FutureProvider.autoDispose.family<PastResult?, int>((
  ref,
  number,
) async {
  final mission = missionByNumber(number);
  if (mission == null) return null;
  final attempts = await ref
      .read(progressRepositoryProvider)
      .attempts(missionId: mission.id);
  final scores = await ref.watch(latestAiScoresProvider.future);
  return PastResult(
    mission: mission,
    attempts: attempts,
    ai: aiFor(MissionProgress(mission: mission, attempts: attempts), scores),
  );
});

/// A played room's last result (brief 48), opened from its card in Your file. Nothing is scored
/// again: the stored attempt is shown as it was. The Candidate assessment comes back exactly
/// as the debrief drew it (the same sheet, stamps, red pen and seal, the owner's rule), on the
/// floor's colour; under it in Daylight: each dimension's latest score against its best, the
/// lesson still to work on, what you said, and the way to play the room again. A room not
/// played yet, or a store that won't read, says so.
class PastResultScreen extends ConsumerWidget {
  const PastResultScreen({super.key, required this.number});

  final int number;

  static const String back = 'Back to your file';
  static String kicker(Mission m) => 'Floor ${m.chapter} · room ${m.number}';
  static String lastPlayed(DateTime? at, int attempt, int of) {
    final when = at == null ? '' : ', ${_date(at.toLocal())}';
    return 'Your last result$when. Try $attempt of $of.';
  }

  static const String scoresTitle = 'Latest and best';
  static const String scoresAside = 'Out of 100';
  static String latestBest(int latest, int best) =>
      latest >= best ? 'Your best yet' : 'Best $best';
  static const String workOn = 'Still to work on';
  static const String saidTitle = 'What you said';
  static const String saidVoice = 'What you covered out loud';
  static const String followUp = 'Your reply to the follow-up';
  static const String made = 'Covered';
  static const String missed = 'Missed';
  static const String voiceNote =
      'Only which points you made is kept. Your voice never is.';
  static String again(int room) => 'Play room $room again';
  static const String notPlayedTitle = 'No result here yet';
  static String notPlayedLine(Mission m) =>
      'Room ${m.number}, “${m.title}”, hasn\'t been played. Its result shows here once '
      'it has.';
  static const String unknownLine = 'There is no room with that number.';

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _date(DateTime t) => '${t.day} ${_months[t.month - 1]}';

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(pastResultProvider(number));
    final result = reading.value;
    final mission = result?.mission ?? missionByNumber(number);
    final f = mission?.grade.floor ?? DaylightFloors.one;
    final Widget body;
    if (result == null && reading.hasError) {
      body = FileTrouble(
        onRetry: () => ref.invalidate(pastResultProvider(number)),
      );
    } else if (reading.isLoading && result == null) {
      body = const SizedBox.shrink();
    } else if (result == null || result.latest == null) {
      body = _NotPlayed(mission: mission);
    } else {
      body = _Result(result: result);
    }
    return DaylightGround(
      color: f.tint,
      floor: f,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DaylightTopBar(
              leadingIcon: PhosphorBold.arrowLeft,
              leadingLabel: back,
              onLeading: () => context.go(Routes.progress),
              kicker: mission == null ? null : kicker(mission),
              title: mission?.title ?? notPlayedTitle,
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
                    child: body,
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

class _Result extends ConsumerWidget {
  const _Result({required this.result});

  final PastResult result;

  static const double _arch = 64;
  static const double _archHeight = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = result.mission;
    final f = ChapterTint.floorOf(context);
    final latest = result.latest!;
    final voice = latest.voice;
    final facts = DebriefFacts.of(m, latest.score);
    final ({int? marked, String? note}) pen;
    final Lesson? lesson;
    if (voice != null && m.voice != null) {
      pen = voiceRedPen(
        mission: m,
        byCost: latest.score.optionIdsByCost,
        made: voice.madePointIds.toSet(),
      );
      lesson = lessonById(m.voice!.lessonId);
    } else {
      pen = (marked: facts.markedDimensionIndex, note: facts.lesson?.title);
      lesson = facts.lesson;
    }
    final total = result.shownTotal;
    final strong = total >= DebriefFacts.strongFrom;
    final sounds = ref.read(gameSoundsProvider);
    final shown = result.shown;
    final best = result.best;
    final weakest = Dimension.values.reduce(
      (a, b) => shown[b]! < shown[a]! ? b : a,
    );
    var i = 0;
    Widget enter(Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: DaylightSpace.s24),
      child: Entrance(index: i++, child: child),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ArchPortrait(
                person: CastPeople.byId(m.lead.id),
                expression: strong ? CastExpression.smile : CastExpression.hmm,
                width: _arch,
                height: _archHeight,
                ground: f.soft,
                idle: false,
              ),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PastResultScreen.lastPlayed(
                        latest.completedAt,
                        latest.attemptNumber,
                        result.attempts.length,
                      ),
                      style: DaylightType.body5,
                    ),
                    const SizedBox(height: DaylightSpace.s8),
                    Tag(
                      label: result.ai == null
                          ? ProgressScreen.offline
                          : ProgressScreen.aiScored,
                      icon: result.ai == null
                          ? PhosphorRegular.wifiSlash
                          : PhosphorFill.sparkle,
                      tone: result.ai == null
                          ? TagTone.raised
                          : TagTone.floor(f),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // The Candidate assessment, exactly as the debrief draws it, on the floor's colour.
        enter(
          DaylightPanel(
            color: f.base,
            edge: f.deep,
            padding: const EdgeInsets.symmetric(
              horizontal: DaylightSpace.s8,
              vertical: DaylightSpace.s16,
            ),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: DebriefView.maxSheetTextScale,
              child: Dossier(
                title: DebriefView.title,
                subtitle: '${m.title} · with ${m.lead.name}',
                scores: [
                  for (final d in Dimension.values)
                    DossierScore(label: dimensionLabel(d), value: shown[d]!),
                ],
                total: total,
                note: pen.note,
                markedIndex: pen.marked,
                onStamp: (_) => sounds.scoreStamped(),
              ),
            ),
          ),
        ),
        if (result.ai case final ai?)
          enter(
            DaylightPanel(
              child: Text(ai.score.overall.basis, style: DaylightType.body6),
            ),
          ),
        enter(
          _Block(
            title: PastResultScreen.scoresTitle,
            aside: PastResultScreen.scoresAside,
            child: DaylightPanel(
              child: Column(
                children: [
                  for (final (n, d) in Dimension.values.indexed) ...[
                    if (n > 0) const SizedBox(height: DaylightSpace.s16),
                    DimensionRow(
                      name: dimensionLabel(d),
                      score: shown[d]!,
                      basis: PastResultScreen.latestBest(
                        latest.score.dimensions[d] ?? 0,
                        best[d]!,
                      ),
                      weakest: d == weakest && shown[d]! < best[d]!,
                      delay: DaylightMotion.stagger * n,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (lesson != null)
          enter(
            _Block(
              title: PastResultScreen.workOn,
              child: DaylightPanel(
                color: DaylightColors.trapTint,
                edge: null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: DaylightType.heading6.copyWith(
                        color: DaylightColors.trap,
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Text(lesson.takeaway, style: DaylightType.body6),
                  ],
                ),
              ),
            ),
          ),
        enter(
          voice != null && m.voice != null
              ? _Block(
                  title: PastResultScreen.saidVoice,
                  child: _VoicePoints(
                    points: [
                      ...m.voice!.listenFor,
                      ...m.voice!.followUpListenFor,
                    ],
                    made: voice.madePointIds.toSet(),
                  ),
                )
              : _Block(
                  title: PastResultScreen.saidTitle,
                  child: _Lines(mission: m, attempt: latest),
                ),
        ),
        Entrance(
          index: i,
          child: TactileButton(
            label: PastResultScreen.again(m.number),
            icon: PhosphorBold.arrowCounterClockwise,
            onPressed: () => context.go(Routes.mission(m.number)),
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.aside});

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

/// The lines the player chose, beat by beat, and their reply to the follow-up: roman, in
/// quotation marks (no italics).
class _Lines extends StatelessWidget {
  const _Lines({required this.mission, required this.attempt});

  final Mission mission;
  final AttemptRecord attempt;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final lines = <(String, String)>[
      for (var i = 0; i < mission.beats.length; i++)
        if (i < attempt.beatOptionIds.length)
          if (mission.optionById(attempt.beatOptionIds[i]) case final o?)
            (_beat(mission.beats[i].kind), o.text),
      if (mission.optionById(attempt.replyOptionId) case final reply?)
        (PastResultScreen.followUp, reply.text),
    ];
    return DaylightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (n, (label, text)) in lines.indexed) ...[
            if (n > 0) const SizedBox(height: DaylightSpace.s16),
            Text(label, style: DaylightType.caption3.copyWith(color: f.deep)),
            const SizedBox(height: DaylightSpace.s4),
            Text('“$text”', style: DaylightType.body3),
          ],
        ],
      ),
    );
  }

  static String _beat(BeatKind kind) {
    final name = kind.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

/// A spoken answer's points: made (a check in the floor's colour) or missed (clay).
class _VoicePoints extends StatelessWidget {
  const _VoicePoints({required this.points, required this.made});

  final List<ListenFor> points;
  final Set<String> made;

  static const double _icon = 20;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DaylightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (n, p) in points.indexed) ...[
            if (n > 0) const SizedBox(height: DaylightSpace.s12),
            Semantics(
              label:
                  '${made.contains(p.id) ? PastResultScreen.made : PastResultScreen.missed}: '
                  '${p.text}',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    made.contains(p.id)
                        ? PhosphorFill.checkCircle
                        : PhosphorBold.x,
                    size: _icon,
                    color: made.contains(p.id) ? f.base : DaylightColors.trap,
                  ),
                  const SizedBox(width: DaylightSpace.s12),
                  Expanded(child: Text(p.text, style: DaylightType.body6)),
                ],
              ),
            ),
          ],
          const SizedBox(height: DaylightSpace.s16),
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
                  PastResultScreen.voiceNote,
                  style: DaylightType.caption4.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// No result to show: the room hasn't been played (or isn't a room). An arch with a lock, what
/// opens a result here, and the way back.
class _NotPlayed extends StatelessWidget {
  const _NotPlayed({required this.mission});

  final Mission? mission;

  static const double _arch = 72;
  static const double _archHeight = 88;
  static const double _lock = 28;

  @override
  Widget build(BuildContext context) {
    final m = mission;
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
              PastResultScreen.notPlayedTitle,
              style: DaylightType.heading5,
            ),
          ),
          const SizedBox(height: DaylightSpace.s8),
          Text(
            m == null
                ? PastResultScreen.unknownLine
                : PastResultScreen.notPlayedLine(m),
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
          const SizedBox(height: DaylightSpace.s24),
          TactileButton(
            label: PastResultScreen.back,
            icon: PhosphorBold.arrowLeft,
            onPressed: () => context.go(Routes.progress),
          ),
        ],
      ),
    );
  }
}
