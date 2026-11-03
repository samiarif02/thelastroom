import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

/// The host side of integration_test/perf_test.dart (NFR-3): writes what the device reported
/// to `build/perf/` (relative to apps/mobile): per path, the driver's timeline summary
/// (`<path>_timeline.timeline_summary.json`, with the full timeline beside it for DevTools or
/// chrome://tracing), and `summary.json`, the frame-timing numbers per path.
///
/// Run only through the command in docs/status/56.md (a profile build, its own app id).
Future<void> main() => integrationDriver(
  // The driver API hands the report over untyped; each entry is narrowed before use.
  responseDataCallback: (data) async {
    if (data == null) return;
    final out = Directory('build/perf')..createSync(recursive: true);
    for (final MapEntry(:key, :value) in data.entries) {
      if (value is! Map<String, Object?>) continue;
      if (key.endsWith('_timeline')) {
        await TimelineSummary.summarize(Timeline.fromJson(value))
            .writeTimelineToFile(
              key,
              destinationDirectory: out.path,
              pretty: true,
            );
      } else {
        File(
          '${out.path}/$key.json',
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
      }
    }
    stdout.writeln('NFR-3 frame timing written to ${out.absolute.path}');
  },
);
