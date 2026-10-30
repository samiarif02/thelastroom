import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/game_sounds.dart';

/// A film-credit button: a spaced, small-caps label in brass between hairlines, at least
/// [BrandSpace.minTarget] tall. [quiet] drops the frame (Skip). No ripple, no Material. Every
/// press plays [GameSounds.uiTap].
///
/// Lives with the mission player for now; it belongs in the kit (`ui/`), which is 06b's this
/// wave (asked for in docs/status/10.md).
class CueButton extends ConsumerStatefulWidget {
  const CueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.grade = ChapterGrade.lobby,
    this.quiet = false,
  });

  final String label;

  /// Null disables it.
  final VoidCallback? onPressed;
  final ChapterGrade grade;
  final bool quiet;

  @override
  ConsumerState<CueButton> createState() => _CueButtonState();
}

class _CueButtonState extends ConsumerState<CueButton> {
  bool _lit = false;

  VoidCallback? get _press {
    final onPressed = widget.onPressed;
    if (onPressed == null) return null;
    return () {
      ref.read(gameSoundsProvider).uiTap();
      onPressed();
    };
  }

  static const double _padX = BrandSpace.md;
  static const double _hairline = 0.8;
  static const double _disabledAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final press = _press;
    final enabled = press != null;
    final brass = widget.grade.key;
    final alpha = !enabled ? _disabledAlpha : (_lit ? 1.0 : 0.85);
    final text = Text(
      widget.label.toUpperCase(),
      textAlign: TextAlign.center,
      style: BrandType.eyebrow.copyWith(
        color: (widget.quiet ? BrandColors.textSecondary : brass).withValues(
          alpha: alpha,
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: press,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _lit = v),
        onShowFocusHighlight: (v) => setState(() => _lit = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              press?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: press,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BrandSpace.minTarget,
              minWidth: BrandSpace.minTarget,
            ),
            child: AnimatedContainer(
              duration: BrandMotion.quick,
              padding: const EdgeInsets.symmetric(horizontal: _padX),
              decoration: widget.quiet
                  ? null
                  : BoxDecoration(
                      color: brass.withValues(alpha: _lit ? 0.12 : 0.04),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: brass.withValues(alpha: alpha),
                          width: _hairline,
                        ),
                      ),
                    ),
              // Sized by its label unless its parent stretches it; centred either way.
              child: Center(widthFactor: 1, heightFactor: 1, child: text),
            ),
          ),
        ),
      ),
    );
  }
}
