import 'dart:convert';
import 'dart:developer' as developer;

import 'redact.dart';

/// Severity, lowest first.
enum LogLevel { debug, info, warn, error }

/// One structured log record. Serialises to a single JSON object.
class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    required this.time,
    this.fields = const {},
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final DateTime time;
  final Map<String, Object?> fields;
  final Object? error;
  final StackTrace? stackTrace;

  Map<String, Object?> toJson() => {
    'time': time.toUtc().toIso8601String(),
    'level': level.name,
    'msg': message,
    if (fields.isNotEmpty) ...fields,
    if (error != null) 'error': redactText(error.toString()),
  };
}

/// Where records go. The default writes to `dart:developer` (DevTools and the console);
/// tests capture records; Sentry breadcrumbs plug in here later.
typedef LogSink = void Function(LogRecord record);

void developerSink(LogRecord record) {
  developer.log(
    jsonEncode(record.toJson(), toEncodable: (o) => o.toString()),
    name: 'thelastroom',
    level: _developerLevel[record.level]!,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}

const Map<LogLevel, int> _developerLevel = {
  LogLevel.debug: 500,
  LogLevel.info: 800,
  LogLevel.warn: 900,
  LogLevel.error: 1000,
};

/// The app's logger. Feature code uses this, never `print` or `debugPrint`
/// (docs/rules/logging.md). Fields are redacted before they reach any sink, and a failing sink
/// never takes the app down with it.
class Log {
  Log({
    this.minLevel = LogLevel.info,
    LogSink? sink,
    DateTime Function()? clock,
  }) : _sink = sink ?? developerSink,
       _clock = clock ?? DateTime.now;

  final LogLevel minLevel;
  final LogSink _sink;
  final DateTime Function() _clock;

  void debug(String message, [Map<String, Object?> fields = const {}]) =>
      _emit(LogLevel.debug, message, fields);

  void info(String message, [Map<String, Object?> fields = const {}]) =>
      _emit(LogLevel.info, message, fields);

  void warn(String message, [Map<String, Object?> fields = const {}]) =>
      _emit(LogLevel.warn, message, fields);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) => _emit(
    LogLevel.error,
    message,
    fields,
    error: error,
    stackTrace: stackTrace,
  );

  void _emit(
    LogLevel level,
    String message,
    Map<String, Object?> fields, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;
    final record = LogRecord(
      level: level,
      message: redactText(message),
      time: _clock(),
      fields: redactFields(fields),
      error: error,
      stackTrace: stackTrace,
    );
    try {
      _sink(record);
    } on Object catch (_) {
      // A broken sink must not crash the caller. There is nowhere safer to report it.
    }
  }
}
