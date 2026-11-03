import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../ui/daylight/daylight_kit.dart';

/// Whether the tower tour has been seen, on the device (offline, like the last visit).
abstract interface class TowerTourStore {
  Future<bool> seen();
  Future<void> markSeen();
  Future<void> reset();
}

class SharedPreferencesTowerTourStore implements TowerTourStore {
  const SharedPreferencesTowerTourStore();

  static const String key = 'tower.tourSeen';

  @override
  Future<bool> seen() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;

  @override
  Future<void> markSeen() async =>
      (await SharedPreferences.getInstance()).setBool(key, true);

  @override
  Future<void> reset() async =>
      (await SharedPreferences.getInstance()).remove(key);
}

final towerTourStoreProvider = Provider<TowerTourStore>(
  (ref) => const SharedPreferencesTowerTourStore(),
);

/// How the tour ended (`tower_tour_done`'s `action`).
enum TourAction { started, dismissed }

/// Whether the tower should show its tour now: true until it's been seen. A store that can't
/// be read counts as seen (never a tour that can't be put away).
final towerTourProvider = NotifierProvider<TowerTourController, bool>(
  TowerTourController.new,
);

class TowerTourController extends Notifier<bool> {
  bool _replay = false;
  bool _reported = false;

  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    try {
      final seen = await ref.read(towerTourStoreProvider).seen();
      if (ref.mounted && !seen) state = true;
    } on Object catch (e) {
      if (ref.mounted) {
        ref.read(logProvider).warn('tower tour flag unreadable', {
          'error': e.runtimeType.toString(),
        });
      }
    }
  }

  /// The tour is on screen.
  void shown() {
    if (_reported) return;
    _reported = true;
    ref.read(analyticsProvider).track(AnalyticsEvent.towerTourShown, {
      'replay': EventValue.flag(_replay),
    });
  }

  /// The tour is put away, by tapping the door or dismissing it; it won't come back by itself.
  Future<void> done(TourAction action) async {
    if (!state) return;
    state = false;
    ref.read(analyticsProvider).track(AnalyticsEvent.towerTourDone, {
      'action': EventValue.name(action),
    });
    try {
      await ref.read(towerTourStoreProvider).markSeen();
    } on Object catch (e) {
      if (ref.mounted) {
        ref.read(logProvider).warn('tower tour flag not saved', {
          'error': e.runtimeType.toString(),
        });
      }
    }
  }

  /// "Show the tower tour again" in Settings.
  Future<void> replay() async {
    _replay = true;
    _reported = false;
    try {
      await ref.read(towerTourStoreProvider).reset();
    } on Object catch (e) {
      ref.read(logProvider).warn('tower tour flag not reset', {
        'error': e.runtimeType.toString(),
      });
    }
    if (ref.mounted) state = true;
  }
}

/// The tower tour (the owner: "the first time, if we show a showcase, they'd know to click
/// here"): the screen dims except for a lit cut-out round the door to play, and Priya says
/// what to do in a bubble beside it. A tap on the door starts the room; "Got it" or a tap
/// anywhere else puts the tour away. Under reduced motion it simply appears.
class TowerTour extends StatelessWidget {
  const TowerTour({
    super.key,
    required this.target,
    required this.onDoor,
    required this.onDismiss,
  });

  /// The door, in this overlay's coordinates.
  final Rect target;
  final VoidCallback onDoor;
  final VoidCallback onDismiss;

  static const String line =
      'This is your first room. Tap the door to start your interview.';
  static const String gotIt = 'Got it';
  static const String label = 'Tower tour';
  static const String doorLabel = 'Start your first room';

  static const double _pad = 10;
  static const double _scrim = 0.62;
  static const double _face = 48;
  static const double _faceHeight = 56;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final hole = target.inflate(_pad);
    // The bubble goes where there's more room: above the door, or below it.
    final above = hole.top > size.height - hole.bottom;
    final bubble = Padding(
      padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DaylightColors.raised,
          borderRadius: BorderRadius.circular(DaylightRadius.panel),
          boxShadow: DaylightElevation.lift,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DaylightSpace.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ArchPortrait(
                    person: CastPeople.priya,
                    expression: CastExpression.smile,
                    width: _face,
                    height: _faceHeight,
                    ground: DaylightColors.recallSoft,
                    idle: false,
                  ),
                  const SizedBox(width: DaylightSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priya',
                          style: DaylightType.caption3.copyWith(
                            color: DaylightColors.recall,
                          ),
                        ),
                        const SizedBox(height: DaylightSpace.s2),
                        Text(line, style: DaylightType.body2),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DaylightSpace.s12),
              Align(
                alignment: Alignment.centerRight,
                child: TactileButton(
                  label: gotIt,
                  tone: TactileTone.quiet,
                  compact: true,
                  expand: false,
                  onPressed: onDismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final tour = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Anywhere but the door puts the tour away.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: CustomPaint(
              painter: _Spotlight(hole: hole, dim: _scrim),
            ),
          ),
          // The door itself, through the cut-out: tapping it starts the room.
          Positioned.fromRect(
            rect: hole,
            child: Semantics(
              button: true,
              label: doorLabel,
              onTap: onDoor,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDoor,
              ),
            ),
          ),
          // The bubble in the space above or below the door, scrolling if it's taller
          // (large text), so "Got it" is always reachable.
          Positioned(
            left: 0,
            right: 0,
            top: above
                ? insets.top + DaylightSpace.s8
                : hole.bottom + DaylightSpace.s12,
            bottom: above
                ? size.height - hole.top + DaylightSpace.s12
                : insets.bottom + DaylightSpace.s8,
            child: Align(
              alignment: above ? Alignment.bottomCenter : Alignment.topCenter,
              child: SingleChildScrollView(child: bubble),
            ),
          ),
        ],
      ),
    );
    if (still) return tour;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: DaylightMotion.move,
      curve: DaylightMotion.ease,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: tour,
    );
  }
}

/// The dim, with an arch-topped hole round the door and a honey ring on its edge.
class _Spotlight extends CustomPainter {
  const _Spotlight({required this.hole, required this.dim});

  final Rect hole;
  final double dim;

  static const double _ring = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final arch = RRect.fromRectAndCorners(
      hole,
      topLeft: Radius.circular(hole.width / 2),
      topRight: Radius.circular(hole.width / 2),
      bottomLeft: const Radius.circular(DaylightRadius.inner),
      bottomRight: const Radius.circular(DaylightRadius.inner),
    );
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(arch),
    );
    canvas
      ..drawPath(
        shade,
        Paint()..color = DaylightColors.ink.withValues(alpha: dim),
      )
      ..drawRRect(
        arch,
        Paint()
          ..color = DaylightColors.honey
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ring,
      );
  }

  @override
  bool shouldRepaint(_Spotlight old) => old.hole != hole || old.dim != dim;
}
