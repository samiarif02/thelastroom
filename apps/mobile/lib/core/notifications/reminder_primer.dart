import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../analytics/analytics_event.dart';
import 'reminder_settings.dart';
import 'reminders.dart';

/// Offers reminders once, at the designed moment: back on the tower after the first mission's
/// debrief (FR-52, brief 26), never at launch. A vivid explainer card first; the system's own
/// prompt only if the player says yes. Does nothing on the web or once it has been offered.
Future<void> offerReminders(BuildContext context, WidgetRef ref) async {
  if (!ref.read(remindersSupportedProvider)) return;
  await ref.read(reminderSettingsProvider.notifier).loaded;
  if (ref.read(reminderSettingsProvider).offered) return;
  // Let the room light up and its notice land before the card comes in.
  await Future<void>.delayed(ReminderPrimer.settle);
  if (!context.mounted) return;
  final reminders = ref.read(remindersProvider);
  if (await showReminderPrimer(context, ref)) unawaited(reminders.enable());
  // Answered or dismissed, it isn't offered again; Settings has the switch.
  if (!ref.read(reminderSettingsProvider).enabled) {
    await reminders.markOffered();
  }
}

/// Shows the explainer and resolves true when the player says yes; asking the system is the
/// caller's next step. Used after Mission 1 and by "Send a test reminder" without permission.
Future<bool> showReminderPrimer(BuildContext context, WidgetRef ref) async {
  ref
      .read(analyticsProvider)
      .track(AnalyticsEvent.notificationPermissionPrompted);
  final yes = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: ReminderPrimer.notNow,
    barrierColor: DaylightColors.ink.withValues(alpha: ReminderPrimer.scrim),
    transitionDuration: DaylightMotion.colour,
    pageBuilder: (dialogContext, _, _) => ReminderPrimer(
      onYes: () => Navigator.of(dialogContext).pop(true),
      onNotNow: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return yes ?? false;
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

  static const String kicker = 'A friendly nudge';
  static const String title = 'Want Priya to remind you?';
  static const String line =
      'When traps are waiting in the Recall Room, or your next interview is ready. At most once '
      'a day, never after 9 pm, and quieter if you are busy. Switch it off any time in Settings.';
  static const String yes = 'Yes, remind me';
  static const String notNow = 'Not now';

  static const double scrim = 0.4;

  /// How long the tower's reward moment plays before the explainer appears.
  static const Duration settle = Duration(milliseconds: 1600);
  static const double _maxWidth = 420;

  static const double _face = 56;
  static const double _faceHeight = 64;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _CentredScroll(
        child: Padding(
          padding: const EdgeInsets.all(DaylightSpace.s16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: DaylightPanel(
              edge: null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ArchPortrait(
                      person: CastPeople.priya,
                      expression: CastExpression.smile,
                      width: _face,
                      height: _faceHeight,
                      ground: DaylightColors.recallSoft,
                    ),
                  ),
                  const SizedBox(height: DaylightSpace.s12),
                  Text(
                    kicker,
                    style: DaylightType.caption3.copyWith(
                      color: DaylightColors.recall,
                    ),
                  ),
                  const SizedBox(height: DaylightSpace.s4),
                  Semantics(
                    header: true,
                    child: Text(title, style: DaylightType.heading5),
                  ),
                  const SizedBox(height: DaylightSpace.s8),
                  Text(
                    line,
                    style: DaylightType.body6.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                  const SizedBox(height: DaylightSpace.s24),
                  TactileButton(
                    label: yes,
                    icon: PhosphorBold.bell,
                    tone: TactileTone.recall,
                    onPressed: onYes,
                  ),
                  const SizedBox(height: DaylightSpace.s8),
                  TactileButton(
                    label: notNow,
                    tone: TactileTone.quiet,
                    onPressed: onNotNow,
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

/// Centred while the card fits; scrolls when it doesn't (2x text on a small phone), so the
/// two answers are always reachable.
class _CentredScroll extends StatelessWidget {
  const _CentredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Center(child: SingleChildScrollView(child: child));
}
