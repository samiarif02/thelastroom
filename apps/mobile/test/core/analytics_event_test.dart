import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';

void main() {
  final snakeCase = RegExp(r'^[a-z]+(_[a-z]+)+$');

  test('every wire name is unique snake_case object_action', () {
    final names = AnalyticsEvent.values.map((e) => e.wireName).toList();
    expect(names.toSet(), hasLength(names.length));
    for (final name in names) {
      expect(snakeCase.hasMatch(name), isTrue, reason: name);
    }
  });

  test('the Dart name is the camelCase of the wire name', () {
    for (final event in AnalyticsEvent.values) {
      final camel = event.wireName.replaceAllMapped(
        RegExp('_([a-z])'),
        (m) => m.group(1)!.toUpperCase(),
      );
      expect(event.name, camel);
    }
  });
}
