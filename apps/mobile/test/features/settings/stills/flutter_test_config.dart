import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stills of the Daylight screens (brief 48): drawn with real type, like the catalog goldens,
/// because `flutter test` otherwise draws every glyph as a 1 em box. Load the bundled pair.
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
