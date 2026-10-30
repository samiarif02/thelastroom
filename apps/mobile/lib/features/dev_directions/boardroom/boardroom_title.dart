import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../mission_one.dart';

/// C · title card: the kit's [ChapterTitleCard] for Chapter One.
class BoardroomTitle extends StatelessWidget {
  const BoardroomTitle({super.key});

  @override
  Widget build(BuildContext context) => const ChapterTitleCard(
    eyebrow: MissionOne.chapterNumber,
    title: MissionOne.chapterTitle,
    subtitle: 'in which we meet ${MissionOne.interviewer}',
  );
}
