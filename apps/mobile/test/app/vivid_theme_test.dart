import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/app/vivid_theme.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../features/mission/mission_harness.dart';

class _MemoryStore implements ThemeStore {
  _MemoryStore([this.saved]);

  String? saved;
  final Completer<void> loaded = Completer<void>();

  @override
  Future<String?> load() async {
    await loaded.future;
    return saved;
  }

  @override
  Future<void> save(String id) async => saved = id;
}

void main() {
  tearDown(() => BrandVivid.current = VividThemes.eveningForest);

  group('ThemeController', () {
    ProviderContainer containerWith(_MemoryStore store) {
      final c = ProviderContainer(
        overrides: [themeStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('starts on Evening Forest, then the saved pick', () async {
      final store = _MemoryStore(VividThemes.oceanNight.id);
      final c = containerWith(store);
      expect(c.read(themeProvider), VividThemes.eveningForest);
      store.loaded.complete();
      await pumpEventQueue();
      expect(c.read(themeProvider), VividThemes.oceanNight);
    });

    test('a pick is saved, and wins over a late restore', () async {
      final store = _MemoryStore(VividThemes.oceanNight.id);
      final c = containerWith(store);
      c.read(themeProvider.notifier).pick(VividThemes.sunsetCity);
      store.loaded.complete();
      await pumpEventQueue();
      expect(c.read(themeProvider), VividThemes.sunsetCity);
      expect(store.saved, VividThemes.sunsetCity.id);
    });

    test('an unknown saved id falls back to the default', () async {
      final store = _MemoryStore('neon-disco');
      final c = containerWith(store);
      store.loaded.complete();
      await pumpEventQueue();
      expect(c.read(themeProvider), VividThemes.eveningForest);
    });
  });

  testWidgets('Settings no longer offers themes (one Daylight look)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final rig = MissionRig(tester);
    await rig.boot(Routes.settings, reduceMotion: true);
    await rig.until(find.byType(SettingsScreen));
    await rig.run(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel(RegExp('theme')), findsNothing);
  });

  // An earlier pick still colours the screens Daylight leaves alone (the debrief's ground), so
  // they look exactly as they did for that player.
  testWidgets('a saved theme is back after a restart', (tester) async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesThemeStore.key: VividThemes.sunsetCity.id,
    });
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 500));
    expect(BrandVivid.current, VividThemes.sunsetCity);
  });
}
