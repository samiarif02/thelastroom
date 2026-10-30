import 'package:flutter/widgets.dart';

/// Lays [children] out at [alignment] in the space it's given, and scrolls only when they don't
/// fit (2x text). Subtitles and answer cards sit low in frame, like film subtitles; a dossier
/// sits centred on the desk.
class AnchoredScroll extends StatelessWidget {
  const AnchoredScroll({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.end,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final MainAxisAlignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      reverse: alignment == MainAxisAlignment.end,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: box.maxHeight - padding.vertical,
        ),
        child: Column(
          mainAxisAlignment: alignment,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}
