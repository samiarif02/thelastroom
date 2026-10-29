import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics.dart';
import '../core/env/env.dart';
import '../core/logging/log.dart';

/// App-wide services. Overridden in `main.dart` (real values) and in tests (fakes), so nothing
/// below the root constructs its own.
final envProvider = Provider<Env>((ref) => Env.fromDefines());

final logProvider = Provider<Log>((ref) => Log());

final analyticsProvider = Provider<Analytics>(
  (ref) => LogAnalytics(ref.watch(logProvider)),
);
