import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens are drawn on macOS and checked on CI's Linux: the same fonts and Skia, but the two
/// hosts anti-alias glyph edges a little differently. A golden passes within [_tolerance] of
/// its pixels; a real regression (a moved card, a lost bar, a new colour) changes far more.
const double _tolerance = 0.015;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  final base = goldenFileComparator;
  if (base is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(
      base.basedir.resolve('catalog_golden_test.dart'),
    );
  }
  await testMain();
}

/// `flutter test` draws every glyph as a box unless the fonts are loaded: load the bundled
/// pair (Cormorant Garamond, Manrope) from the test asset bundle, so goldens show real type.
Future<void> _loadBundledFonts() async {
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
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _tolerance) {
      if (!result.passed) {
        debugPrint(
          '$golden: ${(result.diffPercent * 100).toStringAsFixed(3)}% off, within tolerance',
        );
      }
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
