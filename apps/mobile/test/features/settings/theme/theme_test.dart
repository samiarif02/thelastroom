import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';
import 'package:the_last_room/features/settings/theme/theme_controller.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../../mission/mission_harness.dart';

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

  testWidgets('picking a theme in Settings re-colours the app and is saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final rig = MissionRig(tester);
    await rig.boot(Routes.settings, reduceMotion: true);
    await rig.until(find.byType(SettingsScreen));
    await rig.run(const Duration(milliseconds: 300));
    final ocean = find.bySemanticsLabel(RegExp('^Ocean Night theme'));
    await tester.ensureVisible(ocean);
    await tester.pump();
    await tester.tap(ocean);
    await rig.run(const Duration(milliseconds: 300));
    expect(BrandVivid.current, VividThemes.oceanNight);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SharedPreferencesThemeStore.key), 'ocean-night');
    // ignore: avoid_print
    print([
      for (final b in tester.widgetList<ColoredBox>(find.byType(ColoredBox)))
        b.color,
    ]);
    // The screen was rebuilt in the new theme: its header band is the new sky.
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .any((b) => b.color == VividThemes.oceanNight.skyTop),
      isTrue,
    );
  });

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
