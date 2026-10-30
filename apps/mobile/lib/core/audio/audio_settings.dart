import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import 'cue.dart';

/// The player's sound settings. Defaults (owner, D5): on, and clearly audible on a phone speaker
/// at a normal media volume. 0.6 / 0.35 measured about 20 dB under target on the owner's realme 8
/// (2026-10-30), so they went up; `gain_staging_test.dart` holds the floor.
class AudioSettings {
  const AudioSettings({
    this.enabled = true,
    this.ambienceVolume = defaultAmbienceVolume,
    this.effectsVolume = defaultEffectsVolume,
  });

  static const double defaultAmbienceVolume = 0.5;
  static const double defaultEffectsVolume = 0.8;

  /// The master switch: off mutes everything.
  final bool enabled;

  /// Room tone and the music-like stings (title, chapter card, cliffhanger), 0..1.
  final double ambienceVolume;

  /// Every other cue, 0..1.
  final double effectsVolume;

  /// The gain a cue on [bus] plays at right now (0 when sound is off).
  double volumeFor(CueBus bus) => !enabled
      ? 0
      : switch (bus) {
          CueBus.effects => effectsVolume,
          CueBus.ambience => ambienceVolume,
        };

  AudioSettings copyWith({
    bool? enabled,
    double? ambienceVolume,
    double? effectsVolume,
  }) => AudioSettings(
    enabled: enabled ?? this.enabled,
    ambienceVolume: (ambienceVolume ?? this.ambienceVolume).clamp(0, 1),
    effectsVolume: (effectsVolume ?? this.effectsVolume).clamp(0, 1),
  );

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.enabled == enabled &&
      other.ambienceVolume == ambienceVolume &&
      other.effectsVolume == effectsVolume;

  @override
  int get hashCode => Object.hash(enabled, ambienceVolume, effectsVolume);
}

/// Where [AudioSettings] persist between launches.
abstract interface class AudioSettingsStore {
  /// The saved settings, or null on first run.
  Future<AudioSettings?> load();

  Future<void> save(AudioSettings settings);
}

/// [AudioSettingsStore] on `shared_preferences` (a few keys on the device; no account needed).
class SharedPreferencesAudioSettingsStore implements AudioSettingsStore {
  const SharedPreferencesAudioSettingsStore();

  static const String enabledKey = 'audio.enabled';
  static const String ambienceKey = 'audio.ambience_volume';
  static const String effectsKey = 'audio.effects_volume';

  @override
  Future<AudioSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(enabledKey);
    final ambience = prefs.getDouble(ambienceKey);
    final effects = prefs.getDouble(effectsKey);
    if (enabled == null && ambience == null && effects == null) return null;
    return const AudioSettings().copyWith(
      enabled: enabled,
      ambienceVolume: ambience,
      effectsVolume: effects,
    );
  }

  @override
  Future<void> save(AudioSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, settings.enabled);
    await prefs.setDouble(ambienceKey, settings.ambienceVolume);
    await prefs.setDouble(effectsKey, settings.effectsVolume);
  }
}

final audioSettingsStoreProvider = Provider<AudioSettingsStore>(
  (ref) => const SharedPreferencesAudioSettingsStore(),
);

/// The live settings. Starts at the defaults, then switches to the saved ones as soon as they
/// load, unless the player already changed something (their change wins and is saved).
final audioSettingsProvider =
    NotifierProvider<AudioSettingsController, AudioSettings>(
      AudioSettingsController.new,
    );

class AudioSettingsController extends Notifier<AudioSettings> {
  bool _changedByPlayer = false;

  @override
  AudioSettings build() {
    unawaited(_restore());
    return const AudioSettings();
  }

  /// Completes once the saved settings are applied (tests and the dev board await it).
  Future<void> get restored => _restored.future;
  final Completer<void> _restored = Completer<void>();

  Future<void> _restore() async {
    try {
      final saved = await ref.read(audioSettingsStoreProvider).load();
      if (saved != null && !_changedByPlayer && ref.mounted) state = saved;
    } on Object catch (e) {
      ref.read(logProvider).warn('audio settings not restored', {
        'error': e.runtimeType,
      });
    } finally {
      _restored.complete();
    }
  }

  void setEnabled(bool enabled) => _set(state.copyWith(enabled: enabled));

  void setAmbienceVolume(double volume) =>
      _set(state.copyWith(ambienceVolume: volume));

  void setEffectsVolume(double volume) =>
      _set(state.copyWith(effectsVolume: volume));

  void _set(AudioSettings next) {
    _changedByPlayer = true;
    if (next == state) return;
    state = next;
    unawaited(_save(next));
  }

  Future<void> _save(AudioSettings settings) async {
    try {
      await ref.read(audioSettingsStoreProvider).save(settings);
    } on Object catch (e) {
      ref.read(logProvider).warn('audio settings not saved', {
        'error': e.runtimeType,
      });
    }
  }
}
