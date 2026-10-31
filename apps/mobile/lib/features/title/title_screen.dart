import 'package:flutter/widgets.dart';

import 'vivid_title.dart';

/// The Last Room's own title (brief 20): the tower lighting up on the evening sky, then the
/// name. The first launch puts "Begin" under it (`TitleGate`); a returning player sees it for a
/// moment over the tower (`StartTitle`).
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, this.footer, this.onLanded});

  final Widget? footer;
  final VoidCallback? onLanded;

  static const String title = VividTitle.title;
  static const String tagline = VividTitle.tagline;

  @override
  Widget build(BuildContext context) =>
      VividTitle(footer: footer, onLanded: onLanded);
}
