import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/notifications/reminder_settings_row.dart';
import '../../ui/film_kit.dart';
import 'audio/audio_settings_section.dart';
import 'theme/theme_picker.dart';

/// Settings (brief 20, vivid in brief 23), from the tower's gear: the audio section on a vivid
/// panel over the evening sky, under a pinned header with the way back. The system back button also returns
/// to the tower (the route is the tower's child).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String title = 'Settings';
  static const String back = 'Tower';

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const VividBackdrop(lights: false),
      SafeArea(
        bottom: false,
        child: Column(
          children: [
            VividHeader(
              title: title,
              backLabel: back,
              onBack: () => context.go(Routes.tower()),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BrandSpace.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StaggeredEntrance(
                          index: 0,
                          child: VividPanel(child: ThemePicker()),
                        ),
                        SizedBox(height: BrandSpace.md),
                        StaggeredEntrance(
                          index: 1,
                          child: VividPanel(child: AudioSettingsSection()),
                        ),
                        SizedBox(height: BrandSpace.md),
                        StaggeredEntrance(
                          index: 2,
                          child: VividPanel(child: ReminderSettingsRow()),
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
    ],
  );
}
