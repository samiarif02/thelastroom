import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';

/// Where the player's theme pick lives on the device.
abstract interface class ThemeStore {
  Future<String?> load();
  Future<void> save(String id);
}

class SharedPreferencesThemeStore implements ThemeStore {
  const SharedPreferencesThemeStore();

  static const String key = 'vivid.theme';

  @override
  Future<String?> load() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> save(String id) async =>
      (await SharedPreferences.getInstance()).setString(key, id);
}

final themeStoreProvider = Provider<ThemeStore>(
  (ref) => const SharedPreferencesThemeStore(),
);

/// The vivid theme (brief 28): the default at first, then the saved pick as soon as it loads,
/// unless the player already picked (their pick wins and is saved). The app sets
/// `BrandVivid.current` from it and rebuilds, so every screen follows.
final themeProvider = NotifierProvider<ThemeController, VividPalette>(
  ThemeController.new,
);

class ThemeController extends Notifier<VividPalette> {
  bool _picked = false;

  @override
  VividPalette build() {
    unawaited(_restore());
    return VividThemes.eveningForest;
  }

  Future<void> _restore() async {
    try {
      final id = await ref.read(themeStoreProvider).load();
      if (id != null && !_picked && ref.mounted) state = VividThemes.byId(id);
    } on Object catch (e) {
      ref.read(logProvider).warn('theme not restored', {
        'error': e.runtimeType,
      });
    }
  }

  void pick(VividPalette theme) {
    _picked = true;
    if (theme == state) return;
    state = theme;
    unawaited(_save(theme));
  }

  Future<void> _save(VividPalette theme) async {
    try {
      await ref.read(themeStoreProvider).save(theme.id);
    } on Object catch (e) {
      ref.read(logProvider).warn('theme not saved', {'error': e.runtimeType});
    }
  }
}
