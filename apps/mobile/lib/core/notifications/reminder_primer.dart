import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui/film_kit.dart';
import '../analytics/analytics_event.dart';
import 'reminder_settings.dart';
import 'reminders.dart';

/// Offers reminders once, at the designed moment: back on the tower after the first mission's
/// debrief (FR-52, brief 26), never at launch. A vivid explainer card first; the system's own
/// prompt only if the player says yes. Does nothing on the web or once it has been offered.
Future<void> offerReminders(BuildContext context, WidgetRef ref) async {
  if (!remindersSupported) return;
  await ref.read(reminderSettingsProvider.notifier).loaded;
  if (ref.read(reminderSettingsProvider).offered) return;
  // Let the room light up and its notice land before the card comes in.
  await Future<void>.delayed(ReminderPrimer.settle);
  if (!context.mounted) return;
  ref
      .read(analyticsProvider)
      .track(AnalyticsEvent.notificationPermissionPrompted);
  final reminders = ref.read(remindersProvider);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: ReminderPrimer.notNow,
    barrierColor: BrandVivid.night.withValues(alpha: ReminderPrimer.scrim),
    transitionDuration: BrandMotion.standard,
    pageBuilder: (dialogContext, _, _) => ReminderPrimer(
      onYes: () {
        Navigator.of(dialogContext).pop();
        unawaited(reminders.enable());
      },
      onNotNow: () => Navigator.of(dialogContext).pop(),
    ),
  );
  // Answered or dismissed, it isn't offered again; Settings has the switch.
  if (!ref.read(reminderSettingsProvider).enabled) {
    await reminders.markOffered();
  }
}

/// The explainer: what the reminders are, how kind they are, and two clear answers.
class ReminderPrimer extends StatelessWidget {
  const ReminderPrimer({
    super.key,
    required this.onYes,
    required this.onNotNow,
  });

  final VoidCallback onYes;
  final VoidCallback onNotNow;

  static const String kicker = 'A FRIENDLY NUDGE';
  static const String title = 'Want Priya to remind you?';
  static const String line =
      'When traps are waiting in the Recall Room, or your next interview is ready. At most once '
      'a day, never after 9 pm, and quieter if you are busy. Switch it off any time in Settings.';
  static const String yes = 'Yes, remind me';
  static const String notNow = 'Not now';

  static const double scrim = 0.7;

  /// How long the tower's reward moment plays before the explainer appears.
  static const Duration settle = Duration(milliseconds: 1600);
  static const double _maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(BrandSpace.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: VividPanel(
              colors: ChapterGrade.lobby.cardGradient,
              glow: BrandVivid.accent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(kicker, style: BrandVividType.kicker),
                  const SizedBox(height: BrandSpace.sm),
                  Semantics(
                    header: true,
                    child: const Text(title, style: BrandVividType.title),
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  const Text(line, style: BrandVividType.body),
                  const SizedBox(height: BrandSpace.lg),
                  VividButton(label: yes, onPressed: onYes, expand: true),
                  const SizedBox(height: BrandSpace.sm),
                  VividButton(
                    label: notNow,
                    primary: false,
                    onPressed: onNotNow,
                    expand: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
