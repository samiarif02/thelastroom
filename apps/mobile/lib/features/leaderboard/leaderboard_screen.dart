import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/backend/remote_rows.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/haptics.dart';
import '../progression/progression.dart';
import 'board_rows.dart';
import 'leaderboard_controller.dart';
import 'leaderboard_states.dart';
import 'league_banner.dart';
import 'podium.dart';

/// The leaderboard (issue 72), from the tower's tab bar: the player's league on top, then
/// "This week" (this UTC week's XP) or "All time" (total XP): the podium, the ranked list, and
/// the player's own row pinned at the bottom. Offline it shows the last board with "as of …";
/// with no backend, a calm explainer (ADR 0005). The back button returns to the tower.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  static const String title = 'Leaderboard';
  static const String kicker = 'Northstar tower';
  static const String back = 'Back to the tower';
  static const String weekTab = 'This week';
  static const String allTab = 'All time';

  /// "Offline · as of Tue 14:05".
  static String asOf(DateTime at) {
    final local = at.toLocal();
    final hh = '${local.hour}'.padLeft(2, '0');
    final mm = '${local.minute}'.padLeft(2, '0');
    return 'Offline · as of ${_days[local.weekday - 1]} $hh:$mm';
  }

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.week;

  static const double _maxWidth = 560;
  static const double _pinnedShare = 0.4;

  @override
  void initState() {
    super.initState();
    _track();
  }

  void _track() => ref.read(analyticsProvider).track(
    AnalyticsEvent.leaderboardOpened,
    {'tab': EventValue.name(_tab(_scope))},
  );

  void _select(LeaderboardScope scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _track();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider(_scope));
    final progression = ref.watch(progressionProvider).value;
    final hidden = ref.watch(leaderboardVisibleProvider).value == false;
    final ready = state.value;
    final me = ready is BoardReady ? ready.board.me : null;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DaylightGround(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DaylightTopBar(
              leadingIcon: PhosphorBold.arrowLeft,
              leadingLabel: LeaderboardScreen.back,
              onLeading: () => context.go(Routes.tower()),
              kicker: LeaderboardScreen.kicker,
              title: LeaderboardScreen.title,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  DaylightSpace.s16,
                  DaylightSpace.s8,
                  DaylightSpace.s16,
                  DaylightSpace.s24 + (me == null ? bottom : 0),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(
                          child: LeagueBanner(totalXp: progression?.xp ?? 0),
                        ),
                        const SizedBox(height: DaylightSpace.s16),
                        Entrance(
                          index: 1,
                          child: _ScopeTabs(scope: _scope, onSelect: _select),
                        ),
                        const SizedBox(height: DaylightSpace.s16),
                        Entrance(
                          index: 2,
                          child: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : DaylightMotion.colour,
                            child: KeyedSubtree(
                              key: ValueKey((_scope, ready.runtimeType)),
                              child: _body(state),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The player's own row, pinned under the scrolling board.
            if ((ready, me) case (final BoardReady r, final mine?))
              Padding(
                padding: EdgeInsets.fromLTRB(
                  DaylightSpace.s16,
                  DaylightSpace.s8,
                  DaylightSpace.s16,
                  bottom + DaylightSpace.s16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // Never more than 40% of the screen, even at 2x text.
                    constraints: BoxConstraints(
                      maxWidth: _maxWidth,
                      maxHeight:
                          MediaQuery.sizeOf(context).height * _pinnedShare,
                    ),
                    child: _Seen(
                      scope: _scope,
                      score: mine.score(_scope),
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: YouRow(
                            board: r.board,
                            me: mine,
                            hidden: hidden,
                            seenBefore: r.seenBefore,
                          ),
                        ),
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

  Widget _body(AsyncValue<BoardState> state) => switch (state.value) {
    // Reloading (the guest just signed in, a retry): the skeleton, unless a board is showing.
    final v when state.isLoading && v is! BoardReady => const BoardSkeleton(),
    null when state.hasError => _unavailable(),
    null => const BoardSkeleton(),
    BoardNoBackend() => const BoardNotice(
      person: CastPeople.priya,
      title: BoardNotice.noBackendTitle,
      line: BoardNotice.noBackendLine,
    ),
    BoardUnavailable() => _unavailable(),
    BoardReady(:final board, :final live) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!live) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Tag(
              label: LeaderboardScreen.asOf(board.fetchedAt),
              icon: PhosphorBold.wifiSlash,
            ),
          ),
          const SizedBox(height: DaylightSpace.s16),
        ],
        if (board.isEmpty)
          BoardNotice(
            person: CastPeople.sam,
            title: BoardNotice.emptyTitle(board.scope),
            line: BoardNotice.emptyLine,
            action: BoardNotice.play,
            actionIcon: PhosphorBold.door,
            onAction: () => context.go(Routes.tower()),
          )
        else ...[
          Podium(board: board),
          if (board.rest.isNotEmpty) ...[
            const SizedBox(height: DaylightSpace.s16),
            BoardList(board: board, entries: board.rest),
          ],
        ],
      ],
    ),
  };

  Widget _unavailable() => BoardNotice(
    person: CastPeople.priya,
    title: BoardNotice.offlineTitle,
    line: BoardNotice.offlineLine,
    action: BoardNotice.retry,
    actionIcon: PhosphorBold.arrowCounterClockwise,
    quiet: true,
    onAction: () => ref.invalidate(leaderboardProvider(_scope)),
  );

  static _Tab _tab(LeaderboardScope s) =>
      s == LeaderboardScope.week ? _Tab.week : _Tab.allTime;
}

/// The `tab` property of `leaderboard_opened`.
enum _Tab { week, allTime }

/// Remembers the score the player saw once their row is on screen, so the next visit counts up
/// from it.
class _Seen extends ConsumerStatefulWidget {
  const _Seen({required this.scope, required this.score, required this.child});

  final LeaderboardScope scope;
  final int score;
  final Widget child;

  @override
  ConsumerState<_Seen> createState() => _SeenState();
}

class _SeenState extends ConsumerState<_Seen> {
  @override
  void initState() {
    super.initState();
    _mark();
  }

  @override
  void didUpdateWidget(_Seen old) {
    super.didUpdateWidget(old);
    if (old.scope != widget.scope || old.score != widget.score) _mark();
  }

  void _mark() => unawaited(
    ref.read(leaderboardActionsProvider).seen(widget.scope, widget.score),
  );

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "This week" | "All time": two segments on a sand track, the current one white. Each is a
/// 48 target and a selected tab to screen readers.
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.scope, required this.onSelect});

  final LeaderboardScope scope;
  final ValueChanged<LeaderboardScope> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DaylightSpace.s4),
    decoration: BoxDecoration(
      color: DaylightColors.sand,
      borderRadius: BorderRadius.circular(DaylightRadius.card),
    ),
    child: Row(
      children: [
        for (final s in LeaderboardScope.values)
          Expanded(child: _segment(context, s)),
      ],
    ),
  );

  Widget _segment(BuildContext context, LeaderboardScope s) {
    final on = s == scope;
    final label = s == LeaderboardScope.week
        ? LeaderboardScreen.weekTab
        : LeaderboardScreen.allTab;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      onTap: () => onSelect(s),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!on) choiceTick();
          onSelect(s);
        },
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : DaylightMotion.colour,
          curve: DaylightMotion.ease,
          constraints: const BoxConstraints(minHeight: DaylightSize.hit),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s8),
          decoration: BoxDecoration(
            color: on
                ? DaylightColors.raised
                : DaylightColors.raised.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(DaylightRadius.inner),
            boxShadow: on ? DaylightElevation.edge : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: DaylightType.title3.copyWith(
              color: on ? DaylightColors.ink : DaylightColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
