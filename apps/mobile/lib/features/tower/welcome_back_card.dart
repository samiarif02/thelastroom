import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../progression/progression.dart';
import '../recall/recall_controller.dart';
import 'tower_rooms.dart';
import 'welcome_back.dart';

/// "Welcome back" on the tower (brief 42): after a day or more away, a short card in the next
/// interviewer's voice says what's waiting (cards due, the next room, the week so far) with one
/// button to it. Dismissible, once per return, never shaming. Takes no space when it's not up.
///
/// [quiet]: the tower opened from a finished mission, so the player never left.
class WelcomeBackCard extends ConsumerStatefulWidget {
  const WelcomeBackCard({super.key, this.quiet = false});

  final bool quiet;

  static const String dismiss = 'Dismiss';

  @override
  ConsumerState<WelcomeBackCard> createState() => _WelcomeBackCardState();
}

class _WelcomeBackCardState extends ConsumerState<WelcomeBackCard> {
  late final WelcomeBackController _controller = ref.read(
    welcomeBackProvider.notifier,
  );
  late final AppLifecycleListener _lifecycle;
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // A phone left on the tower overnight comes back to a new day.
      onResume: () => unawaited(_controller.arrive()),
      onHide: () => unawaited(_controller.leave()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Under a mission the tower is built but not seen: it's a visit once it's the route on top.
    if (_arrived || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _arrived = true;
    unawaited(_controller.arrive(quiet: widget.quiet));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _follow(WelcomeBack welcome) {
    _controller.close(welcome.target, followed: true);
    context.go(switch (welcome.target) {
      WelcomeBackTarget.recall => Routes.recall,
      WelcomeBackTarget.mission => Routes.mission(welcome.missionNumber!),
      WelcomeBackTarget.progress => Routes.progress,
    });
  }

  @override
  Widget build(BuildContext context) {
    final away = ref.watch(welcomeBackProvider);
    final rooms = ref.watch(towerRoomsProvider).value;
    final due = ref.watch(recallDueCountProvider).value;
    final progress = ref.watch(progressionProvider).value;
    // Up only once everything it names is known, so it never changes its mind on screen.
    final welcome =
        away == null || rooms == null || due == null || progress == null
        ? null
        : welcomeBackFor(
            recallDue: due,
            next: heroRoom(rooms),
            progress: progress,
          );
    if (welcome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.shown(welcome.target);
      });
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduced ? DaylightMotion.colour : DaylightMotion.move,
      switchInCurve: DaylightMotion.ease,
      switchOutCurve: DaylightMotion.ease,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      // Reduced motion: a plain cross-fade, the space closing at once.
      transitionBuilder: (child, t) => reduced
          ? FadeTransition(opacity: t, child: child)
          : FadeTransition(
              opacity: t,
              child: SizeTransition(
                sizeFactor: t,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
      child: welcome == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              key: const ValueKey('welcome'),
              padding: const EdgeInsets.only(bottom: DaylightSpace.s16),
              child: _Card(
                welcome: welcome,
                onFollow: () => _follow(welcome),
                onDismiss: () =>
                    _controller.close(welcome.target, followed: false),
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.welcome,
    required this.onFollow,
    required this.onDismiss,
  });

  final WelcomeBack welcome;
  final VoidCallback onFollow;
  final VoidCallback onDismiss;

  static const double _face = 56;
  static const double _faceHeight = 64;
  static const double _icon = 18;

  static IconData _iconOf(WaitingKind kind) => switch (kind) {
    WaitingKind.recall => PhosphorFill.cards,
    WaitingKind.room => PhosphorFill.door,
    WaitingKind.week => PhosphorFill.circleHalf,
  };

  @override
  Widget build(BuildContext context) => DaylightPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArchPortrait(
              person: CastPeople.byId(welcome.interviewerId),
              expression: CastExpression.smile,
              width: _face,
              height: _faceHeight,
              ground: DaylightColors.recallSoft,
              semanticLabel: welcome.speaker,
            ),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    welcome.kicker,
                    style: DaylightType.caption3.copyWith(
                      color: DaylightColors.recall,
                    ),
                  ),
                  const SizedBox(height: DaylightSpace.s2),
                  Semantics(
                    header: true,
                    child: Text(welcome.greeting, style: DaylightType.heading6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DaylightSpace.s8),
            IconTile.quiet(
              icon: PhosphorBold.x,
              semanticLabel: WelcomeBackCard.dismiss,
              onPressed: onDismiss,
            ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s12),
        for (final (i, line) in welcome.waiting.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: DaylightSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    _iconOf(
                      i < welcome.kinds.length
                          ? welcome.kinds[i]
                          : WaitingKind.week,
                    ),
                    size: _icon,
                    color: DaylightColors.recall,
                  ),
                ),
                const SizedBox(width: DaylightSpace.s8),
                Expanded(child: Text(line, style: DaylightType.body5)),
              ],
            ),
          ),
        const SizedBox(height: DaylightSpace.s8),
        TactileButton(
          label: welcome.action,
          icon: switch (welcome.target) {
            WelcomeBackTarget.recall => PhosphorBold.cards,
            WelcomeBackTarget.mission => PhosphorFill.play,
            WelcomeBackTarget.progress => PhosphorBold.userCircle,
          },
          // Recall's colour: the tower's one honey button stays the up-next card's.
          tone: TactileTone.recall,
          compact: true,
          onPressed: onFollow,
        ),
      ],
    ),
  );
}
