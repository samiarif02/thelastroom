import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/notifications/reminder_settings_row.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../tower/tower_tour.dart';
import 'audio/audio_settings_section.dart';

/// Settings (brief 20; Daylight in brief 46), from the tower's "You" tab: sound and reminders on
/// white cards over the paper, under a top bar with the way back. The theme picker is gone (one
/// considered look). The system back button also returns to the tower (the route is the
/// tower's child).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String title = 'Settings';
  static const String back = 'Back to the tower';
  static const String kicker = 'You';
  static const String tourHeading = 'The tower';
  static const String tourLine =
      'See where to tap again: the spotlight on your next room, with Priya.';
  static const String tour = 'Show the tower tour again';

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DaylightGround(
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          DaylightTopBar(
            leadingIcon: PhosphorBold.arrowLeft,
            leadingLabel: back,
            onLeading: () => context.go(Routes.tower()),
            kicker: kicker,
            title: title,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                DaylightSpace.s16,
                DaylightSpace.s16,
                DaylightSpace.s16,
                DaylightSpace.s24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Entrance(
                        child: DaylightPanel(child: AudioSettingsSection()),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      const Entrance(
                        index: 1,
                        child: DaylightPanel(child: ReminderSettingsRow()),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      Entrance(
                        index: 2,
                        child: DaylightPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  tourHeading,
                                  style: DaylightType.heading6,
                                ),
                              ),
                              const SizedBox(height: DaylightSpace.s4),
                              Text(
                                tourLine,
                                style: DaylightType.body6.copyWith(
                                  color: DaylightColors.ink2,
                                ),
                              ),
                              const SizedBox(height: DaylightSpace.s16),
                              TactileButton(
                                label: tour,
                                icon: PhosphorBold.door,
                                tone: TactileTone.quiet,
                                compact: true,
                                onPressed: () async {
                                  await ref
                                      .read(towerTourProvider.notifier)
                                      .replay();
                                  if (context.mounted) {
                                    context.go(Routes.tower());
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
