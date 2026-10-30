import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The app's home until the tower exists (brief 13): The Last Room's own title card, so a fresh
/// `flutter run` already looks like the film. The banker's lamp below the title is the room
/// waiting for you. It fires no events until the intro exists (brief 10).
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  static const String eyebrow = 'NORTHSTAR LABS';
  static const String title = 'THE LAST ROOM';
  static const String tagline = 'One room left between you and the offer.';

  static const double _lampWidth = 112;

  @override
  Widget build(BuildContext context) {
    return const ChapterTitleCard(
      eyebrow: eyebrow,
      title: title,
      subtitle: tagline,
      footer: SizedBox(width: _lampWidth, child: BankersLamp()),
    );
  }
}
