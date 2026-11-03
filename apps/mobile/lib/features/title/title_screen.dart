import 'package:flutter/widgets.dart';

import 'daylight_title.dart';

/// The Last Room's own title (brief 20; Daylight in brief 48): the tower lighting up in the
/// day sky, then the name and the cast. The first launch puts "Step inside" under it
/// (`TitleGate`); a returning player sees it for a moment over the tower (`StartTitle`).
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, this.footer, this.onLanded});

  final Widget? footer;
  final VoidCallback? onLanded;

  static const String title = DaylightTitle.title;
  static const String tagline = DaylightTitle.tagline;

  @override
  Widget build(BuildContext context) =>
      DaylightTitle(footer: footer, onLanded: onLanded);
}
