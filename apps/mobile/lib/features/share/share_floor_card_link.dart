import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import 'card_renderer.dart';
import 'card_sharer.dart';
import 'floor_card.dart';
import 'floor_card_facts.dart';

/// "Share your floor card" (direction.md §6): a text link under a cleared floor's button. A tap
/// draws the [FloorCard] off screen (1080 × 1350) and opens the system's share sheet with it and
/// one line ("I cleared floor 1 of The Last Room: …"). Every tap fires `floor_card_shared` with
/// how it went. If the sheet can't open, a calm bubble says so; nothing else changes.
class ShareFloorCardLink extends ConsumerStatefulWidget {
  const ShareFloorCardLink({
    super.key,
    required this.floor,
    this.ink = DaylightColors.raised,
  });

  /// The cleared floor, 1–3.
  final int floor;

  /// The link's colour: white on a floor's colour, ink on paper.
  final Color ink;

  static const String label = 'Share your floor card';
  static const String making = 'Making your card…';
  static const String trouble = "Couldn't open sharing. Try again.";

  /// How long the bubble stays.
  static const Duration troubleFor = Duration(seconds: 4);

  @override
  ConsumerState<ShareFloorCardLink> createState() => _ShareFloorCardLinkState();
}

class _ShareFloorCardLinkState extends ConsumerState<ShareFloorCardLink> {
  final OverlayPortalController _bubble = OverlayPortalController();
  Timer? _hide;
  bool _busy = false;

  static const double _icon = 18;
  static const double _busyOpacity = 0.6;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    _hide?.cancel();
    if (_bubble.isShowing) _bubble.hide();
    final floor = widget.floor;
    final view = View.of(context);
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final analytics = ref.read(analyticsProvider);
    final log = ref.read(logProvider);
    final renderer = ref.read(cardRendererProvider);
    final sharer = ref.read(cardSharerProvider);
    var outcome = ShareOutcome.unavailable;
    var failed = false;
    try {
      final facts = await ref.read(floorCardFactsProvider(floor).future);
      final png = await renderer.render(
        FloorCard(facts: facts),
        size: FloorCard.size,
        pixelRatio: FloorCard.pixelRatio,
        view: view,
      );
      outcome = await sharer.share(
        png: png,
        fileName: FloorCard.fileName(floor),
        text: FloorCard.shareText(facts),
        origin: origin,
      );
    } on Exception catch (e) {
      // The sheet couldn't open (no share target, a plugin error, the picture not drawn):
      // say so calmly; the player's progress is untouched either way.
      failed = true;
      log.warn('floor card not shared', {
        'floor': floor,
        'error': e.runtimeType.toString(),
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    analytics.track(AnalyticsEvent.floorCardShared, {
      'floor': EventValue.count(floor),
      'outcome': EventValue.name(outcome),
    });
    if (!mounted) return;
    if (failed) {
      _bubble.show();
      _hide = Timer(ShareFloorCardLink.troubleFor, () {
        if (mounted && _bubble.isShowing) _bubble.hide();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the facts are ready (and kept) by the time the link is tapped.
    ref.watch(floorCardFactsProvider(widget.floor));
    final ink = widget.ink;
    final label = _busy ? ShareFloorCardLink.making : ShareFloorCardLink.label;
    return OverlayPortal(
      controller: _bubble,
      overlayChildBuilder: (_) => const _TroubleBubble(),
      child: Semantics(
        button: true,
        enabled: !_busy,
        label: label,
        excludeSemantics: true,
        onTap: _busy ? null : () => unawaited(_share()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _busy ? null : () => unawaited(_share()),
          child: Opacity(
            opacity: _busy ? _busyOpacity : 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: DaylightSize.hit),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorBold.shareNetwork, size: _icon, color: ink),
                  const SizedBox(width: DaylightSpace.s8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: DaylightType.body4.copyWith(
                        color: ink,
                        decoration: TextDecoration.underline,
                        decorationColor: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The calm bubble when sharing can't open (the tower's notice: an ink bubble, lifted, a honey
/// glyph), clear of the bottom of the screen. It rises in; under reduced motion it is there.
class _TroubleBubble extends StatelessWidget {
  const _TroubleBubble();

  static const double _lift = DaylightSpace.s96;
  static const double _rise = DaylightSpace.s16;
  static const double _glyph = 18;

  @override
  Widget build(BuildContext context) => Positioned(
    left: DaylightSpace.s16,
    right: DaylightSpace.s16,
    bottom: MediaQuery.paddingOf(context).bottom + _lift,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : DaylightMotion.colour,
        curve: DaylightMotion.ease,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, _rise * (1 - t)),
          child: child,
        ),
        child: Semantics(
          liveRegion: true,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DaylightColors.ink,
                borderRadius: BorderRadius.circular(DaylightRadius.card),
                boxShadow: DaylightElevation.lift,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DaylightSpace.s16,
                  vertical: DaylightSpace.s12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        PhosphorBold.shareNetwork,
                        size: _glyph,
                        color: DaylightColors.honey,
                      ),
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    Flexible(
                      child: Text(
                        ShareFloorCardLink.trouble,
                        textAlign: TextAlign.center,
                        style: DaylightType.body5.copyWith(
                          color: DaylightColors.raised,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
