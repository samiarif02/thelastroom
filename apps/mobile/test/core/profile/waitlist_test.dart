import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';

import '../../features/mission/mission_harness.dart' show RecordingAnalytics;

void main() {
  test(
    'joining the waitlist stores a timestamp and fires waitlist_joined once',
    () async {
      final analytics = RecordingAnalytics();
      final store = InMemoryProfileRepository();
      final container = ProviderContainer(
        overrides: [
          analyticsProvider.overrideWithValue(analytics),
          profileRepositoryProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      final profile = container.read(profileProvider.notifier);
      await profile.joinWaitlist();
      await profile.joinWaitlist();
      expect((await store.load()).waitlistJoinedAt, isNotNull);
      expect(analytics.count(AnalyticsEvent.waitlistJoined), 1);
      expect(analytics.only(AnalyticsEvent.waitlistJoined).wire, isEmpty);
    },
  );
}
