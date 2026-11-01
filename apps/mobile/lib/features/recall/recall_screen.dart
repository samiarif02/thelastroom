import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/vivid/progress_ring.dart';
import '../../ui/vivid/vivid_backdrop.dart';
import '../../ui/vivid/vivid_button.dart';
import '../../ui/vivid/vivid_panel.dart';
import 'recall_card_view.dart';
import 'recall_controller.dart';

/// The Recall Room (brief 21): a one-minute round of the traps and lessons the player missed,
/// on a Leitner schedule. A pinned header with the way back and the round's ring (cards done,
/// the streak in the middle), then one card at a time.
class RecallScreen extends ConsumerWidget {
  const RecallScreen({super.key});

  static const String title = 'Recall Room';
  static const String back = 'Tower';
  static const String loading = 'Opening the room…';
  static const String noCardsTitle = 'Nothing to recall yet';
  static const String noCards =
      'Play a mission. Every trap you fall for comes back here as a card, so it never '
      'catches you twice.';
  static const String caughtUpTitle = 'All caught up';
  static const String caughtUp =
      'Every card is resting. The next ones come back tomorrow.';
  static const String unavailableTitle = 'The room is stuck';
  static const String unavailable =
      "Your cards are safe, but the room couldn't open them just now.";
  static const String tryAgain = 'Try again';
  static const String doneTitle = 'Round done';
  static const String streakLabel = 'streak';

  static String doneLine(RecallFinished f) =>
      '${f.known} of ${f.verdicts.length} known. Best streak: ${f.bestStreak}.';

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recallRoomProvider);
    final room = ref.read(recallRoomProvider.notifier);
    void toTower() => context.go(Routes.tower());
    final body = switch (state) {
      RecallLoading() => const _Message(title: loading),
      RecallEmpty(hasCards: false) => _Message(
        title: noCardsTitle,
        line: noCards,
        action: VividButton(label: back, onPressed: toTower),
      ),
      RecallEmpty() => _Message(
        title: caughtUpTitle,
        line: caughtUp,
        action: VividButton(label: back, onPressed: toTower),
      ),
      RecallUnavailable() => _Message(
        title: unavailableTitle,
        line: unavailable,
        action: VividButton(
          label: tryAgain,
          onPressed: () => ref.invalidate(recallRoomProvider),
        ),
      ),
      RecallPlaying() => RecallCardView(
        playing: state,
        onAnswer: room.answer,
        onNext: room.next,
      ),
      RecallFinished() => _Message(
        title: doneTitle,
        line: doneLine(state),
        action: VividButton(label: back, onPressed: toTower),
      ),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        const VividBackdrop(grade: ChapterGrade.pressure),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(state: state, onBack: toTower),
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
                      child: body,
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

/// The way back, the title, and the round's ring: cards answered, the streak in the middle.
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.onBack});

  final RecallRoomState state;
  final VoidCallback onBack;

  static const double _ring = 52;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final (progress, streak) = switch (s) {
      RecallPlaying() => (s.progress, s.streak),
      RecallFinished() => (1.0, s.bestStreak),
      _ => (0.0, 0),
    };
    return ColoredBox(
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
              label: '‹  ${RecallScreen.back}',
              primary: false,
              onPressed: onBack,
            ),
            const SizedBox(width: BrandSpace.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(RecallScreen.title, style: BrandVividType.title),
              ),
            ),
            Semantics(
              label: '$streak ${RecallScreen.streakLabel}',
              excludeSemantics: true,
              child: ProgressRing(
                value: progress,
                color: BrandVivid.accent,
                size: _ring,
                child: Text('$streak', style: BrandVividType.row),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading, empty, stuck and done, in the room's own language: never a spinner on a blank page.
class _Message extends StatelessWidget {
  const _Message({required this.title, this.line, this.action});

  final String title;
  final String? line;
  final Widget? action;

  @override
  Widget build(BuildContext context) => VividPanel(
    colors: ChapterGrade.pressure.cardGradient,
    glow: ChapterGrade.pressure.glow,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: BrandVividType.title),
        ),
        if (line case final l?) ...[
          const SizedBox(height: BrandSpace.sm),
          Text(l, style: BrandVividType.body),
        ],
        if (action case final a?) ...[const SizedBox(height: BrandSpace.md), a],
      ],
    ),
  );
}
