import '../logging/log.dart';
import 'analytics_event.dart';
import 'event_value.dart';

/// An event's properties, keyed by snake_case name. Values are [EventValue]s, so free text
/// can't get in (docs/rules/analytics.md).
typedef EventProperties = Map<String, EventValue>;

/// The only way feature code records an event. The PostHog implementation lands with the
/// analytics prompt; until then events go to the log so they can be checked while developing.
abstract interface class Analytics {
  void track(AnalyticsEvent event, [EventProperties properties = const {}]);
}

class LogAnalytics implements Analytics {
  const LogAnalytics(this._log);

  final Log _log;

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) {
    _log.debug('event', {
      'event': event.wireName,
      for (final MapEntry(:key, :value) in properties.entries) key: value.wire,
    });
  }
}
