import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'reminder_outlook.dart';
import 'reminder_primer.dart';
import 'reminder_settings.dart';
import 'reminders.dart';

/// The Reminders panel of Settings: one switch (FR-51's off switch), the next reminder's day,
/// time and sender or why there's none (brief 42), and "Send a test reminder", which shows
/// tomorrow's reminder now. On the web: a plain note that reminders are phone-only (FR-53).
class ReminderSettingsRow extends ConsumerStatefulWidget {
  const ReminderSettingsRow({super.key});

  static const String heading = 'Reminders';
  static const String label = 'Send me reminders';
  static const String line = 'At most once a day, never after 9 pm.';
  static const String denied =
      'Your phone is blocking them. Allow notifications for The Last Room in its settings.';

  static const String test = 'Send a test reminder';
  static const String testSent =
      'Sent. Pull down your notifications: this is the reminder you will get next, and a tap '
      'opens where it points.';
  static const String testNothing =
      'Nothing to send: every room is done and no cards are due.';
  static const String testFailed =
      'Your phone did not show it. Check that notifications are allowed for The Last Room.';
  static const String testWeb =
      'Reminders are phone-only. Open The Last Room on your Android phone or iPhone, finish '
      'Mission 1, then send a test from here.';

  @override
  ConsumerState<ReminderSettingsRow> createState() =>
      _ReminderSettingsRowState();
}

class _ReminderSettingsRowState extends ConsumerState<ReminderSettingsRow> {
  bool _denied = false;
  bool _sending = false;

  /// What the last "Send a test reminder" did, under the button; null before one.
  String? _testNote;

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

  Future<void> _sendTest() async {
    if (!ref.read(remindersSupportedProvider)) {
      setState(() => _testNote = ReminderSettingsRow.testWeb);
      return;
    }
    setState(() => _sending = true);
    try {
      final reminders = ref.read(remindersProvider);
      if (!await reminders.hasPermission()) {
        // Never the system prompt cold: the same explainer as after Mission 1 comes first.
        if (!mounted || !await showReminderPrimer(context, ref)) return;
        final granted = await reminders.enable();
        if (!mounted) return;
        if (!granted) {
          setState(() => _denied = true);
          return;
        }
      }
      final result = await reminders.sendTest();
      if (!mounted) return;
      setState(() {
        _denied = false;
        _testNote = switch (result) {
          TestReminderResult.sent => ReminderSettingsRow.testSent,
          TestReminderResult.nothingPlanned => ReminderSettingsRow.testNothing,
          TestReminderResult.unsupported => ReminderSettingsRow.testWeb,
          TestReminderResult.failed => ReminderSettingsRow.testFailed,
        };
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = ref.watch(remindersSupportedProvider);
    final settings = ref.watch(reminderSettingsProvider);
    final outlook = ref.watch(reminderOutlookProvider).value;
    final now = ref.watch(reminderClockProvider)();
    final note = _testNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            ReminderSettingsRow.heading,
            style: DaylightType.heading6,
          ),
        ),
        const SizedBox(height: DaylightSpace.s8),
        if (supported) ...[
          SwitchRow(
            label: ReminderSettingsRow.label,
            value: settings.enabled,
            onChanged: _change,
          ),
          const SizedBox(height: DaylightSpace.s4),
        ],
        // Empty for the moment it takes to plan; the line keeps its place so nothing jumps.
        Semantics(
          liveRegion: true,
          child: Text(
            outlook == null ? '' : nextReminderLine(outlook, now),
            style: DaylightType.body2,
          ),
        ),
        if (supported) ...[
          const SizedBox(height: DaylightSpace.s4),
          Text(
            _denied ? ReminderSettingsRow.denied : ReminderSettingsRow.line,
            style: DaylightType.body6.copyWith(
              color: _denied ? DaylightColors.trap : DaylightColors.ink2,
            ),
          ),
        ],
        const SizedBox(height: DaylightSpace.s16),
        TactileButton(
          label: ReminderSettingsRow.test,
          icon: PhosphorBold.bell,
          tone: TactileTone.quiet,
          compact: true,
          onPressed: _sending ? null : _sendTest,
        ),
        if (note != null) ...[
          const SizedBox(height: DaylightSpace.s12),
          Semantics(
            liveRegion: true,
            child: Text(
              note,
              style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
            ),
          ),
        ],
      ],
    );
  }
}
