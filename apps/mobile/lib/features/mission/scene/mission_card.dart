import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';
import '../mission_lookup.dart';

/// The room's title card (Daylight, brief 46): the floor's own colour edge to edge, the room's
/// interviewer in an arch, the kicker "Floor 1 · room 4", the title in Heading 3 (the floor's
/// name on its first room), and who's asking. Left-aligned, sentence case and set to wrap
/// between words: at 360–411 dp it breaks where the words do (the playthrough's note: the old
/// tracked capitals wrapped badly at 411). It moves on by itself after [hold], or on a tap.
class MissionCard extends StatefulWidget {
  const MissionCard({super.key, required this.mission, this.onFinished});

  final Mission mission;
  final VoidCallback? onFinished;

  /// How long the card holds before the room opens.
  static const Duration hold = Duration(milliseconds: 2800);

  static const String tapHint = 'Tap to go in';

  /// "Floor 2 · room 11". The number and its word never part (a no-break space).
  static String kicker(Mission m) => 'Floor ${m.chapter} · room ${m.number}';

  static String chapterEyebrow(int chapter) => 'Floor $chapter';

  static String withWho(Interviewer lead) =>
      'with ${lead.name}, the ${lead.role.toLowerCase()}';

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  Timer? _timer;

  static const double _arch = 120;
  static const double _archHeight = 148;

  @override
  void initState() {
    super.initState();
    _timer = Timer(MissionCard.hold, () => widget.onFinished?.call());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final f = m.grade.floor;
    final lead = m.lead;
    final chapter = chapters.firstWhere((c) => c.number == m.chapter);
    final opens = m.opensChapter;
    final title = opens ? chapter.title : m.title;
    final sub = opens
        ? 'Room ${m.number}: ${m.title}, ${MissionCard.withWho(lead)}'
        : MissionCard.withWho(lead);
    final items = <Widget>[
      ArchPortrait(
        person: CastPeople.byId(lead.id),
        expression: CastExpression.smile,
        width: _arch,
        height: _archHeight,
        ground: f.soft,
        border: DaylightSpace.s4,
        sill: f.deep,
        semanticLabel: '${lead.name}, ${lead.role}',
      ),
      const SizedBox(height: DaylightSpace.s24),
      Text(
        MissionCard.kicker(m),
        style: DaylightType.caption3.copyWith(color: f.on),
      ),
      const SizedBox(height: DaylightSpace.s8),
      Semantics(
        header: true,
        child: Text(
          title,
          style: DaylightType.heading3.copyWith(color: DaylightColors.raised),
        ),
      ),
      const SizedBox(height: DaylightSpace.s8),
      Text(sub, style: DaylightType.body2.copyWith(color: f.on)),
      const SizedBox(height: DaylightSpace.s32),
      Row(
        children: [
          Icon(PhosphorBold.door, size: DaylightSpace.s16, color: f.on),
          const SizedBox(width: DaylightSpace.s8),
          Text(
            MissionCard.tapHint,
            style: DaylightType.caption4.copyWith(color: f.on),
          ),
        ],
      ),
    ];
    return DaylightGround(
      color: f.base,
      floor: f,
      dark: true,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.all(DaylightSpace.s24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: box.maxHeight - DaylightSpace.s48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, w) in items.indexed)
                    Entrance(index: i ~/ 2, child: w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
