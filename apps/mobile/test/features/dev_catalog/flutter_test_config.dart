import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens are drawn and checked on **Linux** (CI's host, Flutter 3.47.8). macOS draws the same
/// frames with different glyph anti-aliasing (1.5–6% of pixels off), so on any other host the
/// golden tests still build and play every state (an exception still fails them) but skip the
/// pixel comparison. Redraw them on Linux: see `goldens/README.md`.
///
/// On Linux a golden passes within [_tolerance] of its pixels, room for nothing but rounding.
const double _tolerance = 0.002;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  final base = goldenFileComparator;
  if (base is LocalFileComparator) {
    final testFile = base.basedir.resolve('catalog_golden_test.dart');
    goldenFileComparator = Platform.isLinux
        ? _TolerantComparator(testFile)
        : _RenderOnlyComparator(testFile);
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
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Off Linux: the frame was rendered (that's the test), the pixels aren't compared, and
/// `--update-goldens` refuses rather than commit macOS pixels.
class _RenderOnlyComparator extends LocalFileComparator {
  _RenderOnlyComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(
    Uri golden,
    Uint8List imageBytes,
  ) => throw UnsupportedError(
    'Goldens are drawn on Linux only (CI renders text differently from '
    '${Platform.operatingSystem}). See test/features/dev_catalog/goldens/README.md.',
  );
}
