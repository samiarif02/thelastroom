import '../logging/log.dart';
import 'analytics_event.dart';

/// A property value: an id, an enum name, a number or a boolean. Never free text a person typed.
typedef EventProperties = Map<String, Object>;

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
    _log.debug('event', {'event': event.wireName, ...properties});
  }
}
