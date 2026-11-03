import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/notifications/reminder_settings_row.dart';
import '../../ui/daylight/daylight_kit.dart';
import 'audio/audio_settings_section.dart';

/// Settings (brief 20; Daylight in brief 46), from the tower's "You" tab: sound and reminders on
/// white cards over the paper, under a top bar with the way back. The theme picker is gone (one
/// considered look). The system back button also returns to the tower (the route is the
/// tower's child).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String title = 'Settings';
  static const String back = 'Back to the tower';
  static const String kicker = 'You';

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context) => DaylightGround(
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        child: DaylightPanel(child: AudioSettingsSection()),
                      ),
                      SizedBox(height: DaylightSpace.s24),
                      Entrance(
                        index: 1,
                        child: DaylightPanel(child: ReminderSettingsRow()),
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
