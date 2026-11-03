import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import '../progression/progression.dart';
import 'recall_card_view.dart';
import 'recall_controller.dart';

/// The Recall Room (brief 21; Daylight in brief 46, direction.md §7, mockup `07`): on the
/// recall tint, a short round of the traps and lessons the player missed, on a Leitner
/// schedule. The top bar says which note of how many and shows the note's box; Priya hosts,
/// naming who caught you; the note is taped paper; the choices are pick cards; the week's
/// ring at the foot says what this round does for the week.
class RecallScreen extends ConsumerWidget {
  const RecallScreen({super.key});

  static const String title = 'Recall Room';
  static const String back = 'Back to the tower';
  static const String loading = 'Opening the room…';
  static const String noCardsTitle = 'Nothing to recall yet';
  static const String noCards =
      'Play a room. Every trap you fall for comes back here as a note, so it never '
      'catches you twice.';
  static const String caughtUpTitle = 'No notes due';
  static const String caughtUp =
      'Priya will leave one when something needs another look.';
  static const String unavailableTitle = 'The room is stuck';
  static const String unavailable =
      "Your notes are safe, but the room couldn't open them just now.";
  static const String tryAgain = 'Try again';
  static const String doneTitle = 'Round done';
  static const String streakLabel = 'streak';

  static String doneLine(RecallFinished f) =>
      '${f.known} of ${f.verdicts.length} known. Best streak: ${f.bestStreak}.';

  static String noteOf(int n, int of) => '$title · note $n of $of';

  /// "The next one is back on Friday."
  static String nextDue(CalendarDay day, CalendarDay today) {
    final days = today.daysUntil(day);
    if (days <= 1) return 'The next one is back tomorrow.';
    final d = DateTime(day.year, day.month, day.day);
    return 'The next one is back on ${_weekdays[d.weekday - 1]}.';
  }

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recallRoomProvider);
    final room = ref.read(recallRoomProvider.notifier);
    final name =
        ref.watch(profileProvider).value?.displayName ??
        PlayerProfile.fallbackName;
    final progression = ref.watch(progressionProvider).value;
    final today = dayOf(ref.watch(progressionClockProvider)());
    void toTower() => context.go(Routes.tower());
    final body = switch (state) {
      RecallLoading() => const _Message(title: loading, loading: true),
      RecallEmpty(hasCards: false) => _Message(
        title: noCardsTitle,
        line: noCards,
        onTower: toTower,
      ),
      RecallEmpty(:final nextDue) => _Message(
        title: caughtUpTitle,
        line: nextDue == null
            ? caughtUp
            : '$caughtUp ${RecallScreen.nextDue(nextDue, today)}',
        onTower: toTower,
      ),
      RecallUnavailable() => _Message(
        title: unavailableTitle,
        line: unavailable,
        retry: () => ref.invalidate(recallRoomProvider),
        onTower: toTower,
      ),
      RecallPlaying() => RecallCardView(
        playing: state,
        playerName: name,
        onAnswer: room.answer,
        onNext: room.next,
      ),
      RecallFinished() => _Message(
        title: doneTitle,
        line: doneLine(state),
        onTower: toTower,
        done: true,
      ),
    };
    final playing = state is RecallPlaying ? state : null;
    final week = progression == null || state is! RecallPlaying
        ? null
        : _WeekNote(progression: progression);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DaylightGround(
      color: DaylightColors.recallTint,
      floor: _recallFloor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                DaylightTopBar(
                  leadingLabel: back,
                  onLeading: toTower,
                  kicker: playing == null
                      ? title
                      : noteOf(playing.index + 1, playing.round.length),
                  title: playing == null
                      ? title
                      : _source(playing) ?? RecallScreen.title,
                  trailing: playing == null ? null : _Boxes(box: playing.box),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      DaylightSpace.s16,
                      DaylightSpace.s12,
                      DaylightSpace.s16,
                      DaylightSpace.s24 +
                          bottom +
                          (week == null ? 0 : _WeekNote.reserve),
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
          if (week != null)
            Positioned(
              left: DaylightSpace.s16,
              right: DaylightSpace.s16,
              bottom: bottom + DaylightSpace.s16,
              child: week,
            ),
        ],
      ),
    );
  }

  /// "From Marcus's room" for a trap note; null for a lesson.
  static String? _source(RecallPlaying p) {
    final who = p.question.caughtBy;
    if (who == null) return null;
    return 'From ${interviewerById(who).name}\u2019s room';
  }
}

/// The Recall Room's colours, as a floor, so every kit widget below wears them.
const FloorColours _recallFloor = FloorColours(
  base: DaylightColors.recall,
  deep: DaylightColors.recallDeep,
  tint: DaylightColors.recallTint,
  soft: DaylightColors.recallSoft,
  on: DaylightColors.recallTint,
);

/// The Leitner boxes (mockup `07`): three squares on a raised tile, lit up to the note's box.
class _Boxes extends StatelessWidget {
  const _Boxes({required this.box});

  final LeitnerBox? box;

  static const double _size = 16;

  @override
  Widget build(BuildContext context) {
    final lit = switch (box) {
      LeitnerBox.one || null => 1,
      LeitnerBox.three => 2,
      LeitnerBox.seven => 3,
    };
    return Semantics(
      label: 'Box $lit of 3',
      excludeSemantics: true,
      child: Container(
        height: DaylightSize.iconTile,
        padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s12),
        decoration: BoxDecoration(
          color: DaylightColors.raised,
          borderRadius: BorderRadius.circular(DaylightRadius.tile),
          boxShadow: DaylightElevation.edgeOf(
            DaylightColors.sand2,
            depth: DaylightSize.edgeSmall,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: DaylightSpace.s4),
              SizedBox.square(
                dimension: _size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < lit
                        ? DaylightColors.recall
                        : DaylightColors.recallSoft,
                    borderRadius: BorderRadius.circular(DaylightSpace.s4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The week at the foot (mockup `07`): the ring and what this round does for the week, never
/// a streak.
class _WeekNote extends StatelessWidget {
  const _WeekNote({required this.progression});

  final Progression progression;

  /// The space the scroll leaves under the cards for it.
  static const double reserve = 88;
  static const double _ring = 44;

  static String line(Progression p) {
    final next = p.sessionsThisWeek + 1;
    if (p.goalMet) return 'Your week is done. This round is a bonus.';
    if (p.playedToday) {
      return 'Today already counts: ${p.sessionsThisWeek} of ${p.weeklyGoal} this week.';
    }
    if (next >= p.weeklyGoal) {
      return 'This closes $next of ${p.weeklyGoal} for the week. Two minutes, then you\u2019re done.';
    }
    return 'This counts for the week: $next of ${p.weeklyGoal}.';
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DaylightColors.raised,
      borderRadius: BorderRadius.circular(DaylightRadius.card),
      boxShadow: DaylightElevation.lift,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DaylightSpace.s16,
        vertical: DaylightSpace.s12,
      ),
      child: Row(
        children: [
          WeeklyRing(
            done: progression.sessionsThisWeek,
            goal: progression.weeklyGoal,
            size: _ring,
            floor: DaylightFloors.one,
          ),
          const SizedBox(width: DaylightSpace.s12),
          Expanded(
            child: Text(
              line(progression),
              style: DaylightType.body5.copyWith(color: DaylightColors.ink2),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Loading, empty, stuck and done, in the room's own language: Priya in her arch, never a
/// spinner on a blank page.
class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    this.line,
    this.onTower,
    this.retry,
    this.loading = false,
    this.done = false,
  });

  final String title;
  final String? line;
  final VoidCallback? onTower;
  final VoidCallback? retry;
  final bool loading;
  final bool done;

  @override
  Widget build(BuildContext context) => Entrance(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DaylightSpace.s24),
        ArchPortrait(
          person: CastPeople.priya,
          expression: loading
              ? CastExpression.thinking
              : done
              ? CastExpression.smile
              : CastExpression.neutral,
          ground: DaylightColors.recallSoft,
        ),
        const SizedBox(height: DaylightSpace.s24),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(title, style: DaylightType.heading4),
        ),
        if (line case final l?) ...[
          const SizedBox(height: DaylightSpace.s8),
          Text(
            l,
            style: DaylightType.body3.copyWith(color: DaylightColors.ink2),
          ),
        ],
        if (retry case final r?) ...[
          const SizedBox(height: DaylightSpace.s24),
          TactileButton(
            label: RecallScreen.tryAgain,
            icon: PhosphorBold.arrowCounterClockwise,
            tone: TactileTone.recall,
            onPressed: r,
          ),
        ],
        if (onTower case final t?) ...[
          SizedBox(
            height: retry == null ? DaylightSpace.s24 : DaylightSpace.s8,
          ),
          TactileButton(
            label: RecallScreen.back,
            icon: PhosphorBold.buildings,
            tone: retry == null ? TactileTone.recall : TactileTone.quiet,
            onPressed: t,
          ),
        ],
      ],
    ),
  );
}
