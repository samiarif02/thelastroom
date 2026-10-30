import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../mission_lookup.dart';

/// The mission's title card. The chapter's first mission opens on the chapter's own card
/// ("CHAPTER ONE · GET THROUGH THE DOOR"); the others name the mission and who's waiting.
/// A tap skips it (the player wraps it).
class MissionCard extends StatelessWidget {
  const MissionCard({super.key, required this.mission, this.onFinished});

  final Mission mission;
  final VoidCallback? onFinished;

  static const List<String> _numbers = ['ONE', 'TWO', 'THREE'];

  static String chapterEyebrow(int chapter) =>
      'CHAPTER ${_numbers[chapter - 1]}';

  @override
  Widget build(BuildContext context) {
    final chapter = chapters.firstWhere((c) => c.number == mission.chapter);
    final lead = mission.lead;
    final opens = mission.opensChapter;
    return ChapterTitleCard(
      grade: mission.grade,
      eyebrow: opens
          ? chapterEyebrow(mission.chapter)
          : '${chapterEyebrow(mission.chapter)}  ·  MISSION ${mission.number}',
      title: (opens ? chapter.title : mission.title).toUpperCase(),
      subtitle: opens
          ? 'Mission ${mission.number}: ${mission.title}'
          : 'with ${lead.name}, the ${lead.role.toLowerCase()}',
      onFinished: onFinished,
    );
  }
}
