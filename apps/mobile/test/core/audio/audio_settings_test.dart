import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/audio/audio_settings.dart';
import 'package:the_last_room/core/audio/cue.dart';
import 'package:the_last_room/core/logging/log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [logProvider.overrideWithValue(Log(sink: (_) {}))],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults: on, ambience 35%, effects 60%', () {
    const s = AudioSettings();
    expect(s.enabled, isTrue);
    expect(s.ambienceVolume, 0.35);
    expect(s.effectsVolume, 0.6);
    expect(s.volumeFor(CueBus.effects), 0.6);
    expect(s.volumeFor(CueBus.ambience), 0.35);
  });

  test('master off makes every bus silent', () {
    const s = AudioSettings(enabled: false);
    for (final bus in CueBus.values) {
      expect(s.volumeFor(bus), 0);
    }
  });

  test('volumes are clamped to 0..1', () {
    final s = const AudioSettings().copyWith(
      ambienceVolume: 2,
      effectsVolume: -1,
    );
    expect(s.ambienceVolume, 1);
    expect(s.effectsVolume, 0);
  });

  test('first run: the defaults, and nothing saved yet', () async {
    final c = container();
    final controller = c.read(audioSettingsProvider.notifier);
    await controller.restored;
    expect(c.read(audioSettingsProvider), const AudioSettings());
    expect(await const SharedPreferencesAudioSettingsStore().load(), isNull);
  });

  test('changes persist and come back on the next launch', () async {
    final first = container();
    await first.read(audioSettingsProvider.notifier).restored;
    first.read(audioSettingsProvider.notifier)
      ..setEnabled(false)
      ..setAmbienceVolume(0.2)
      ..setEffectsVolume(0.9);
    await pumpEventQueue();

    final next = container();
    await next.read(audioSettingsProvider.notifier).restored;
    expect(
      next.read(audioSettingsProvider),
      const AudioSettings(
        enabled: false,
        ambienceVolume: 0.2,
        effectsVolume: 0.9,
      ),
    );
  });

  test('a change made before the saved settings load wins', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesAudioSettingsStore.effectsKey: 0.1,
    });
    final c = container();
    c.read(audioSettingsProvider.notifier).setEffectsVolume(0.8);
    await c.read(audioSettingsProvider.notifier).restored;
    expect(c.read(audioSettingsProvider).effectsVolume, 0.8);
  });

  test('a store that fails leaves the defaults and only logs', () async {
    final records = <LogRecord>[];
    final c = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(Log(sink: records.add)),
        audioSettingsStoreProvider.overrideWithValue(_BrokenStore()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(audioSettingsProvider.notifier).restored;
    c.read(audioSettingsProvider.notifier).setEnabled(false);
    await pumpEventQueue();
    expect(c.read(audioSettingsProvider).enabled, isFalse);
    expect(records.map((r) => r.level), [LogLevel.warn, LogLevel.warn]);
  });
}

class _BrokenStore implements AudioSettingsStore {
  @override
  Future<AudioSettings?> load() => Future.error(StateError('disk'));

  @override
  Future<void> save(AudioSettings settings) => Future.error(StateError('disk'));
}
