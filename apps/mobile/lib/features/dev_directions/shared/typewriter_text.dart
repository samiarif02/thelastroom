import 'package:flutter/widgets.dart';

/// A subtitle line revealed character by character. The unrevealed rest is laid out but
/// transparent, so the line never reflows while it types.
class TypewriterText extends StatelessWidget {
  const TypewriterText({
    super.key,
    required this.text,
    required this.characters,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;

  /// How many characters are visible.
  final int characters;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final shown = characters.clamp(0, text.length);
    final hidden = style.copyWith(
      color: style.color?.withValues(alpha: 0),
      shadows: const [],
    );
    return Semantics(
      label: text,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: text.substring(0, shown), style: style),
              TextSpan(text: text.substring(shown), style: hidden),
            ],
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
}
