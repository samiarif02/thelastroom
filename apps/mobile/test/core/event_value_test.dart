import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/analytics/event_value.dart';
import 'package:the_last_room/core/logging/log.dart';

class _Item implements Identified {
  const _Item(this.id);

  @override
  final String id;
}

void main() {
  test('each allowed kind reaches the backend as an id, a name, a number or a bool', () {
    expect(const EventValue.id(_Item('m_opportunity')).wire, 'm_opportunity');
    expect(const EventValue.name(ScoreBucket.from60).wire, 'from60');
    expect(const EventValue.count(3).wire, 3);
    expect(const EventValue.number(0.5).wire, 0.5);
    expect(const EventValue.flag(true).wire, true);
  });

  // The other half of the contract is a compile error, which a test can't run:
  // `EventValue.id('I led the team')` doesn't compile (a String isn't Identified), and
  // there is no constructor that takes a String at all.

  test('LogAnalytics logs the event with its properties as wire values', () {
    final records = <LogRecord>[];
    LogAnalytics(Log(minLevel: LogLevel.debug, sink: records.add))
        .track(AnalyticsEvent.missionCompleted, {
          'mission_id': const EventValue.id(_Item('m_opportunity')),
          'chapter': const EventValue.count(1),
          'score_bucket': const EventValue.name(ScoreBucket.from40),
          'attempt_number': const EventValue.count(1),
        });
    expect(records.single.fields, {
      'event': 'mission_completed',
      'mission_id': 'm_opportunity',
      'chapter': 1,
      'score_bucket': 'from40',
      'attempt_number': 1,
    });
  });
}
