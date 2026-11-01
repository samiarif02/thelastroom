import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/film_kit.dart';
import 'reminder_settings.dart';
import 'reminders.dart';

/// The Reminders panel of Settings: one switch (FR-51's off switch), what it means, and on the
/// web a plain note that reminders live in the mobile app (FR-53).
class ReminderSettingsRow extends ConsumerStatefulWidget {
  const ReminderSettingsRow({super.key});

  static const String heading = 'REMINDERS';
  static const String label = 'Reminders';
  static const String line = 'At most once a day, never after 9 pm.';
  static const String webOnly = 'Reminders are in the mobile app.';
  static const String denied =
      'Your phone is blocking them. Allow notifications for The Last Room in its settings.';

  @override
  ConsumerState<ReminderSettingsRow> createState() =>
      _ReminderSettingsRowState();
}

class _ReminderSettingsRowState extends ConsumerState<ReminderSettingsRow> {
  bool _denied = false;

  Future<void> _change(bool on) async {
    final reminders = ref.read(remindersProvider);
    if (!on) {
      await reminders.disable();
      if (mounted) setState(() => _denied = false);
      return;
    }
    final granted = await reminders.enable();
    if (mounted) setState(() => _denied = !granted);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(reminderSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            ReminderSettingsRow.heading,
            style: BrandVividType.kicker,
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        if (!remindersSupported)
          Text(ReminderSettingsRow.webOnly, style: BrandVividType.body)
        else ...[
          VividToggle(
            label: ReminderSettingsRow.label,
            value: settings.enabled,
            onChanged: _change,
          ),
          const SizedBox(height: BrandSpace.xs),
          Text(
            _denied ? ReminderSettingsRow.denied : ReminderSettingsRow.line,
            style: BrandVividType.body,
          ),
        ],
      ],
    );
  }
}
