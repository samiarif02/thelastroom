import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import 'room_promise.dart';

/// `promise_shown`'s `kind`.
enum PromiseKind { recall, nextRoom }

/// The dated promise (brief 61; direction.md "Reward and retention"): under the line that cost
/// the most, outside the Candidate assessment, a Daylight card in an interviewer's voice with
/// the real day this room's lines come back ("Priya will bring this line back tomorrow. Room 2
/// opens now."), or the next room when there's nothing to bring back. It is decided once the
/// debrief has settled ([ready]): the attempt is stored by then, so the schedule has its notes.
class PromiseCard extends ConsumerStatefulWidget {
  const PromiseCard({super.key, required this.mission, this.ready = true});

  final Mission mission;
  final bool ready;

  @override
  ConsumerState<PromiseCard> createState() => _PromiseCardState();
}

class _PromiseCardState extends ConsumerState<PromiseCard> {
  bool _reported = false;

  void _report(RoomPromise p) {
    if (_reported) return;
    _reported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvent.promiseShown, {
        'mission_id': EventValue.id(widget.mission),
        'kind': EventValue.name(
          p is RecallPromise ? PromiseKind.recall : PromiseKind.nextRoom,
        ),
        'days_ahead': EventValue.count(switch (p) {
          RecallPromise(:final daysAhead) => daysAhead,
          NextRoomPromise() => 0,
        }),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ready) return const SizedBox.shrink();
    // A schedule that can't be read leaves the card out: the debrief never waits on it.
    final reading = ref.watch(roomPromiseProvider(widget.mission.id)).value;
    if (reading == null) return const SizedBox.shrink();
    _report(reading.promise);
    return Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s16),
      child: Entrance(
        child: PromiseCardView(reading: reading, keeper: widget.mission.lead),
      ),
    );
  }
}

/// The card itself, from a [RoomPromiseReading]: a face in its arch, the kicker with the date,
/// the promise (Heading 6) and what opens next. [keeper] is the interviewer of the room just
/// played, who keeps a recall promise; a next-room promise is in the next interviewer's voice.
class PromiseCardView extends StatelessWidget {
  const PromiseCardView({
    super.key,
    required this.reading,
    required this.keeper,
  });

  final RoomPromiseReading reading;
  final Interviewer keeper;

  static const double _face = 48;
  static const double _faceHeight = 56;

  @override
  Widget build(BuildContext context) {
    final p = reading.promise;
    final next = promisedRoom(p);
    final nextLine = PromiseCopy.nextRoomLine(
      p.nextRoom,
      opensNow: reading.opensNow,
    );
    final (CastPerson person, Color arch, Color tone) = switch (p) {
      RecallPromise() => (
        CastPeople.byId(keeper.id),
        DaylightColors.recallSoft,
        DaylightColors.recall,
      ),
      NextRoomPromise() when next != null => (
        CastPeople.byId(next.lead.id),
        next.grade.floor.soft,
        next.grade.floor.deep,
      ),
      NextRoomPromise() => (
        CastPeople.byId(keeper.id),
        DaylightColors.honeyTint,
        DaylightColors.honeyInk,
      ),
    };
    final (String kicker, String headline, String detail) = switch (p) {
      RecallPromise() => (
        PromiseCopy.recallKicker(p.day),
        PromiseCopy.recallHeadline(
          p,
          keeper: keeper.name,
          today: reading.today,
        ),
        nextLine,
      ),
      NextRoomPromise() when next != null => (
        PromiseCopy.nextKicker(next.number),
        nextLine,
        PromiseCopy.cleanDetail(next.lead.name),
      ),
      NextRoomPromise() => (
        PromiseCopy.doneKicker,
        PromiseCopy.doneHeadline,
        PromiseCopy.doneDetail,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$kicker. $headline $detail',
      excludeSemantics: true,
      child: DaylightPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArchPortrait(
              person: person,
              expression: CastExpression.smile,
              width: _face,
              height: _faceHeight,
              ground: arch,
            ),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        p is RecallPromise
                            ? PhosphorBold.calendarBlank
                            : PhosphorBold.door,
                        size: DaylightSpace.s16,
                        color: tone,
                      ),
                      const SizedBox(width: DaylightSpace.s4),
                      Expanded(
                        child: Text(
                          kicker,
                          style: DaylightType.caption3.copyWith(color: tone),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DaylightSpace.s4),
                  Text(headline, style: DaylightType.heading6),
                  const SizedBox(height: DaylightSpace.s4),
                  Text(
                    detail,
                    style: DaylightType.body6.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
