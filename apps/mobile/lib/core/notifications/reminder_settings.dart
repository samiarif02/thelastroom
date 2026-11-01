import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';

/// The player's reminder choices, on the device.
class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.offered = false});

  /// Reminders are on: the player said yes in the explainer (or switched them on in Settings)
  /// and the system allowed them. Off until then: nothing is sent without asking.
  final bool enabled;

  /// The explainer has been shown once; it's never shown again (Settings has the switch).
  final bool offered;

  ReminderSettings copyWith({bool? enabled, bool? offered}) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    offered: offered ?? this.offered,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.offered == offered;

  @override
  int get hashCode => Object.hash(enabled, offered);
}

/// Where [ReminderSettings] persist.
abstract interface class ReminderSettingsStore {
  Future<ReminderSettings> load();
  Future<void> save(ReminderSettings settings);
}

class SharedPreferencesReminderSettingsStore implements ReminderSettingsStore {
  const SharedPreferencesReminderSettingsStore();

  static const String enabledKey = 'reminders.enabled';
  static const String offeredKey = 'reminders.offered';

  @override
  Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(enabledKey) ?? false,
      offered: prefs.getBool(offeredKey) ?? false,
    );
  }

  @override
  Future<void> save(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, settings.enabled);
    await prefs.setBool(offeredKey, settings.offered);
  }
}

final reminderSettingsStoreProvider = Provider<ReminderSettingsStore>(
  (ref) => const SharedPreferencesReminderSettingsStore(),
);

/// The live choices: the defaults until the saved ones load.
final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
      ReminderSettingsController.new,
    );

class ReminderSettingsController extends Notifier<ReminderSettings> {
  final Completer<void> _loaded = Completer<void>();
  bool _changed = false;

  /// Completes once the saved choices are in [state].
  Future<void> get loaded => _loaded.future;

  @override
  ReminderSettings build() {
    unawaited(_load());
    return const ReminderSettings();
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(reminderSettingsStoreProvider).load();
      if (!_changed && ref.mounted) state = saved;
    } on Object catch (e) {
      ref.read(logProvider).warn('reminder settings not loaded', {
        'error': e.runtimeType.toString(),
      });
    } finally {
      _loaded.complete();
    }
  }

  Future<void> set(ReminderSettings next) async {
    _changed = true;
    state = next;
    try {
      await ref.read(reminderSettingsStoreProvider).save(next);
    } on Object catch (e) {
      ref.read(logProvider).warn('reminder settings not saved', {
        'error': e.runtimeType.toString(),
      });
    }
  }
}
