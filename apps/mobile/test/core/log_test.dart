import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/logging/redact.dart';

void main() {
  late List<LogRecord> records;
  final fixedTime = DateTime.utc(2026, 10, 29, 12);

  Log logAt(LogLevel minLevel) =>
      Log(minLevel: minLevel, sink: records.add, clock: () => fixedTime);

  setUp(() => records = []);

  test('drops records below the minimum level', () {
    final log = logAt(LogLevel.warn)
      ..debug('d')
      ..info('i')
      ..warn('w')
      ..error('e');
    expect(log.minLevel, LogLevel.warn);
    expect(records.map((r) => r.level), [LogLevel.warn, LogLevel.error]);
  });

  test('a record serialises to one valid JSON object with its fields', () {
    logAt(LogLevel.debug)
        .info('mission loaded', {'mission_id': 'm1', 'beats': 3});
    final json =
        jsonDecode(jsonEncode(records.single.toJson())) as Map<String, Object?>;
    expect(json['level'], 'info');
    expect(json['msg'], 'mission loaded');
    expect(json['mission_id'], 'm1');
    expect(json['beats'], 3);
    expect(json['time'], '2026-10-29T12:00:00.000Z');
  });

  test('redacts sensitive field names and credential-shaped values', () {
    logAt(LogLevel.debug).info('sync', {
      'api_key': 'not-even-secret-looking',
      'answer': 'I led the project',
      'note': 'header was Bearer ${'x' * 26}',
      'nested': {'token': 'x', 'ok': 'fine'},
      'contact': 'someone@example.com',
    });
    final f = records.single.fields;
    expect(f['api_key'], redacted);
    expect(f['answer'], redacted);
    expect(f['note'], isNot(contains('x' * 16)));
    expect((f['nested']! as Map<String, Object?>)['token'], redacted);
    expect((f['nested']! as Map<String, Object?>)['ok'], 'fine');
    expect(f['contact'], redacted);
  });

  test('a failing sink never throws into the caller', () {
    final log = Log(sink: (_) => throw StateError('sink down'));
    expect(() => log.error('boom'), returnsNormally);
  });
}
