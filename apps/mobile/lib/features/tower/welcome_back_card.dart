import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/film_kit.dart';
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
      duration: reduced ? BrandMotion.reducedMotionFade : BrandMotion.standard,
      switchInCurve: BrandMotion.enter,
      switchOutCurve: BrandMotion.exit,
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
              padding: const EdgeInsets.only(bottom: BrandSpace.md),
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

  @override
  Widget build(BuildContext context) => VividPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: BrandSpace.sm),
                child: Text(welcome.kicker, style: BrandVividType.kicker),
              ),
            ),
            Pressable(
              label: WelcomeBackCard.dismiss,
              onTap: onDismiss,
              child: SizedBox.square(
                dimension: BrandSpace.minTarget,
                child: Center(
                  child: CustomPaint(
                    size: const Size.square(_cross),
                    painter: _Cross(BrandVivid.onDeepSoft),
                  ),
                ),
              ),
            ),
          ],
        ),
        Semantics(
          header: true,
          child: Text(welcome.greeting, style: BrandVividType.row),
        ),
        const SizedBox(height: BrandSpace.sm),
        for (final line in welcome.waiting)
          Padding(
            padding: const EdgeInsets.only(bottom: BrandSpace.xs),
            child: Text(line, style: BrandVividType.body),
          ),
        const SizedBox(height: BrandSpace.sm),
        VividButton(
          label: welcome.action,
          // The tower's one amber button stays the hero's "Play".
          primary: false,
          expand: true,
          onPressed: onFollow,
        ),
      ],
    ),
  );

  static const double _cross = 14;
}

/// The dismiss mark: two thin strokes.
class _Cross extends CustomPainter {
  const _Cross(this.color);

  final Color color;

  static const double _stroke = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_Cross old) => old.color != color;
}
