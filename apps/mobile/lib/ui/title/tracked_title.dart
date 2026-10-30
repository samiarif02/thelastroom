import 'dart:math' as math;

import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import '../film/cue.dart';

/// A title that tracks in (letter-spacing from [trackFrom] down to the style's own) and can
/// never break inside a word at any moment of it (DESIGN.md "Known issues": "THROU / GH").
///
/// The lines are decided once, at the *final* tracking, breaking only between words (and at
/// every `\n`). Each line is then drawn on one unbreakable row while the tracking animates;
/// while it's wider than the frame it overflows symmetrically instead of wrapping. If one word
/// can't fit at the final tracking (2x text on a narrow phone), the whole title shrinks to fit.
class TrackedTitle extends StatelessWidget {
  const TrackedTitle({
    super.key,
    required this.text,
    required this.style,
    required this.t,
    this.trackFrom = defaultTrackFrom,
  });

  /// The Boardroom's tracking-in starts at +22 (DESIGN.md).
  static const double defaultTrackFrom = 22;

  final String text;

  /// The settled style; its letterSpacing is where the tracking ends.
  final TextStyle style;

  /// Progress 0–1: 0 at [trackFrom], 1 settled.
  final double t;
  final double trackFrom;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final layout = layoutTitle(
          text,
          style,
          maxWidth: box.maxWidth,
          textScaler: scaler,
          textDirection: direction,
        );
        final settled = layout.style.letterSpacing ?? 0;
        final spacing = mix(trackFrom, settled, t);
        final drawn = layout.style.copyWith(letterSpacing: spacing);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in layout.lines)
              SizedBox(
                width: box.maxWidth,
                child: OverflowBox(
                  fit: OverflowBoxFit.deferToChild,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  // Flutter adds the spacing after the last letter too; shift by half of it
                  // so the line sits optically centred.
                  child: Transform.translate(
                    offset: Offset(spacing / 2, 0),
                    child: Text(
                      line,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: drawn,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The settled lines of a [TrackedTitle] and the style they fit at.
typedef TitleLayout = ({List<String> lines, TextStyle style});

/// Breaks [text] into lines between words only, at the style's final tracking, to fit
/// [maxWidth]. Shrinks the font if a single word is wider than [maxWidth].
TitleLayout layoutTitle(
  String text,
  TextStyle style, {
  required double maxWidth,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
}) {
  double width(String s, TextStyle st) {
    final painter = TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  final paragraphs = text
      .split('\n')
      .map((p) => p.split(' ').where((w) => w.isNotEmpty).toList());
  final words = paragraphs.expand((p) => p).toList();
  var fitted = style;
  if (maxWidth.isFinite && words.isNotEmpty) {
    final widest = words.map((w) => width(w, style)).reduce(math.max);
    if (widest > maxWidth) {
      // Font size and tracking scale together, so the word's width scales exactly.
      final fit = maxWidth / widest;
      fitted = style.copyWith(
        fontSize: (style.fontSize ?? _fallbackSize) * fit,
        letterSpacing: (style.letterSpacing ?? 0) * fit,
      );
    }
  }

  final lines = <String>[];
  for (final paragraph in paragraphs) {
    var line = '';
    for (final word in paragraph) {
      final candidate = line.isEmpty ? word : '$line $word';
      if (line.isNotEmpty &&
          maxWidth.isFinite &&
          width(candidate, fitted) > maxWidth) {
        lines.add(line);
        line = word;
      } else {
        line = candidate;
      }
    }
    if (line.isNotEmpty) lines.add(line);
  }
  return (lines: lines, style: fitted);
}

const double _fallbackSize = 14;
