import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'typewriter_text.dart';

/// Called as each character appears: the seam for brief 09's typing sound. [index] is the
/// character's position in the line (UTF-16 code units).
typedef OnCharacter = void Function(String char, int index);

/// Lets a screen complete the line from outside (a tap anywhere on the scene).
class TypewriterController extends ChangeNotifier {
  bool _complete = false;

  /// Whether the whole line is showing.
  bool get isComplete => _complete;

  /// Shows the rest of the line at once. Skipped characters don't fire `onCharacter`.
  void complete() {
    if (_complete) return;
    _complete = true;
    notifyListeners();
  }

  void _reset() => _complete = false;

  void _finished() => _complete = true;
}

/// Film subtitles: the speaker's name in serif small caps (in the grade's key light), the line
/// typed out beneath it at [BrandMotion.perCharacter]. A tap on it, or
/// [TypewriterController.complete], shows the rest at once.
///
/// Under reduced motion the line appears whole with a short fade; [onComplete] still fires,
/// [onCharacter] doesn't.
class TypewriterSubtitle extends StatefulWidget {
  const TypewriterSubtitle({
    super.key,
    required this.speaker,
    required this.line,
    this.grade = ChapterGrade.lobby,
    this.controller,
    this.onCharacter,
    this.onComplete,
    this.play = true,
    this.textAlign = TextAlign.center,
  });

  final String speaker;
  final String line;
  final ChapterGrade grade;
  final TypewriterController? controller;
  final OnCharacter? onCharacter;
  final VoidCallback? onComplete;

  /// False shows the line already typed (the catalog's settled state, a replayed line).
  final bool play;
  final TextAlign textAlign;

  @override
  State<TypewriterSubtitle> createState() => _TypewriterSubtitleState();
}

class _TypewriterSubtitleState extends State<TypewriterSubtitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typing = AnimationController(vsync: this)
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);
  int _shown = 0;
  bool _started = false;

  // True while the line types; a line that starts complete reports itself after the frame.
  bool _typingLive = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start();
  }

  @override
  void didUpdateWidget(TypewriterSubtitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    if (oldWidget.line != widget.line) _start();
  }

  void _start() {
    widget.controller?._reset();
    _shown = 0;
    final still = MediaQuery.disableAnimationsOf(context);
    _typingLive = !(still || !widget.play || widget.line.isEmpty);
    if (!_typingLive) {
      // Count first, so the jump to the end fires no characters.
      _shown = widget.line.length;
      _typing.value = 1;
      widget.controller?._finished();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete?.call();
      });
      return;
    }
    _typing
      ..duration = BrandMotion.perCharacter * widget.line.length
      ..forward(from: 0);
  }

  void _onTick() {
    final target = (_typing.value * widget.line.length).floor();
    if (target <= _shown) return;
    final onCharacter = widget.onCharacter;
    if (onCharacter != null) {
      for (var i = _shown; i < target; i++) {
        onCharacter(widget.line[i], i);
      }
    }
    setState(() => _shown = target);
  }

  void _onStatus(AnimationStatus status) {
    if (!_typingLive || status != AnimationStatus.completed) return;
    widget.controller?._finished();
    widget.onComplete?.call();
  }

  void _onController() {
    final controller = widget.controller;
    if (controller != null && controller.isComplete) _skip();
  }

  void _skip() {
    if (_typing.isCompleted) return;
    // Jump the count first, so the tick that follows fires no characters.
    _shown = widget.line.length;
    _typing.value = 1;
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final align = switch (widget.textAlign) {
      TextAlign.left || TextAlign.start => CrossAxisAlignment.start,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };
    final subtitle = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Text(
            widget.speaker,
            textAlign: widget.textAlign,
            style: BrandType.speaker.copyWith(color: widget.grade.key),
          ),
          const SizedBox(height: BrandSpace.xs),
          TypewriterText(
            text: widget.line,
            characters: _shown,
            style: BrandType.subtitle,
            textAlign: widget.textAlign,
          ),
        ],
      ),
    );
    if (!still) return subtitle;
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.line),
      tween: Tween(begin: 0, end: 1),
      duration: BrandMotion.reducedMotionFade,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: subtitle,
    );
  }
}
