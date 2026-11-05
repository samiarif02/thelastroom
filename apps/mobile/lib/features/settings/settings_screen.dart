import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/notifications/reminder_settings_row.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../tips/tips.dart';
import 'account/save_progress_card.dart';
import 'audio/audio_settings_section.dart';
import 'leaderboard_visibility_section.dart';

/// Settings (brief 20; Daylight in brief 46), from the tower's "You" tab: "Save your progress"
/// (FR-3), sound, reminders and "Show me on the leaderboard" on
/// white cards over the paper, under a top bar with the way back. The theme picker is gone (one
/// considered look). The system back button also returns to the tower (the route is the
/// tower's child).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String title = 'Settings';
  static const String back = 'Back to the tower';
  static const String kicker = 'You';
  static const String tipsHeading = 'First-time tips';
  static const String tipsLine =
      'See the short tips from the cast again: where to tap, and what to look for.';
  static const String tips = 'Show tips again';
  static const String howHeading = 'How it works';
  static const String howLine =
      'The short tour again: what a room asks, how you’re scored, and how the lines that '
      'caught you come back.';
  static const String how = 'Show how it works';

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
                        child: DaylightPanel(child: SaveProgressCard()),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      const Entrance(
                        index: 1,
                        child: DaylightPanel(child: AudioSettingsSection()),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      const Entrance(
                        index: 2,
                        child: DaylightPanel(child: ReminderSettingsRow()),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      const Entrance(
                        index: 3,
                        child: DaylightPanel(
                          child: LeaderboardVisibilitySection(),
                        ),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      Entrance(
                        index: 4,
                        child: DaylightPanel(
                          child: _Replay(
                            heading: howHeading,
                            line: howLine,
                            button: TactileButton(
                              label: how,
                              icon: PhosphorBold.bookOpen,
                              tone: TactileTone.quiet,
                              compact: true,
                              onPressed: () => context.go(Routes.howItWorks),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      Entrance(
                        index: 5,
                        child: DaylightPanel(
                          child: _Replay(
                            heading: tipsHeading,
                            line: tipsLine,
                            button: TactileButton(
                              label: tips,
                              icon: PhosphorBold.lightbulbFilament,
                              tone: TactileTone.quiet,
                              compact: true,
                              onPressed: () async {
                                await ref
                                    .read(tipsProvider.notifier)
                                    .replayAll();
                                if (context.mounted) {
                                  context.go(Routes.tower());
                                }
                              },
                            ),
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

/// A Settings card that brings something back: a heading, a line, and its quiet button.
class _Replay extends StatelessWidget {
  const _Replay({
    required this.heading,
    required this.line,
    required this.button,
  });

  final String heading;
  final String line;
  final Widget button;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(heading, style: DaylightType.heading6),
      ),
      const SizedBox(height: DaylightSpace.s4),
      Text(
        line,
        style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
      ),
      const SizedBox(height: DaylightSpace.s16),
      button,
    ],
  );
}
