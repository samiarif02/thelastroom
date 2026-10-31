import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tests in this folder measure layout ("everything fits the realme 8 without scrolling"),
/// which only means something with real type: `flutter test` otherwise draws every glyph as a
/// 1 em box, about twice as wide as Manrope. Load the bundled pair (as the catalog's goldens do).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = await rootBundle.loadString('FontManifest.json');
  final families = (jsonDecode(manifest) as List<Object?>)
      .cast<Map<String, Object?>>();
  for (final family in families) {
    final loader = FontLoader(family['family']! as String);
    for (final font
        in (family['fonts']! as List<Object?>).cast<Map<String, Object?>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }
  await testMain();
}
