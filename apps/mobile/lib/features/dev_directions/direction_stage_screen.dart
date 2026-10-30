import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'direction_studio.dart';

/// `/dev/directions/<id>`: one direction, frame by frame (the app lays its grain and vignette
/// over every route).
///
/// A slim pill of controls sits top-right (back, the three frames, replay, hide). Hide it for
/// screenshots, or open the route with `?chrome=off`.
class DirectionStageScreen extends StatefulWidget {
  const DirectionStageScreen({
    super.key,
    required this.studio,
    this.frame = DirectionFrame.title,
    this.chrome = true,
  });

  final DirectionStudio studio;
  final DirectionFrame frame;
  final bool chrome;

  @override
  State<DirectionStageScreen> createState() => _DirectionStageScreenState();
}

class _DirectionStageScreenState extends State<DirectionStageScreen> {
  late DirectionFrame _frame = widget.frame;
  late bool _chrome = widget.chrome;

  /// Bumped to replay the current frame from the top.
  int _take = 0;

  void _show(DirectionFrame f) => setState(() {
    _frame = f;
    _take++;
  });

  @override
  Widget build(BuildContext context) {
    final studio = widget.studio;
    final d = studio.direction;
    return ColoredBox(
      color: d.palette.void_,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: BrandMotion.standard,
            child: KeyedSubtree(
              key: ValueKey('${_frame.name}-$_take'),
              child: studio.frame(_frame),
            ),
          ),
          if (_chrome)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: _Controls(
                  direction: d,
                  frame: _frame,
                  onFrame: _show,
                  onReplay: () => _show(_frame),
                  onHide: () => setState(() => _chrome = false),
                ),
              ),
            )
          else
            // Hidden controls come back with a long press anywhere.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: () => setState(() => _chrome = true),
              ),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.direction,
    required this.frame,
    required this.onFrame,
    required this.onReplay,
    required this.onHide,
  });

  final CinematicDirection direction;
  final DirectionFrame frame;
  final ValueChanged<DirectionFrame> onFrame;
  final VoidCallback onReplay;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final p = direction.palette;
    final label = direction.type.label;
    return Padding(
      padding: const EdgeInsets.all(BrandSpace.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.void_.withValues(alpha: 0.82),
          border: Border.all(color: p.line),
          borderRadius: BorderRadius.circular(BrandRadius.md),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Control(
                label: '‹ ${direction.letter}',
                semantics: 'Back to the directions',
                style: label.copyWith(color: p.textPrimary),
                onTap: () => context.pop(),
              ),
              for (final f in DirectionFrame.values)
                _Control(
                  label: f.label.toUpperCase(),
                  semantics: 'Show the ${f.label.toLowerCase()} frame',
                  style: label.copyWith(
                    color: f == frame ? direction.lobby.key : p.textSecondary,
                  ),
                  onTap: () => onFrame(f),
                ),
              _Control(
                label: 'REPLAY',
                semantics: 'Replay this frame',
                style: label.copyWith(color: p.textPrimary),
                onTap: onReplay,
              ),
              _Control(
                label: 'HIDE',
                semantics: 'Hide the controls (long-press to bring them back)',
                style: label.copyWith(color: p.textPrimary),
                onTap: onHide,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({
    required this.label,
    required this.semantics,
    required this.style,
    required this.onTap,
  });

  final String label;
  final String semantics;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    child: ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: BrandSpace.minTarget,
            minHeight: BrandSpace.minTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BrandSpace.sm + 2),
            // heightFactor keeps the pill as tall as a control, not the screen.
            child: Center(heightFactor: 1, child: Text(label, style: style)),
          ),
        ),
      ),
    ),
  );
}
