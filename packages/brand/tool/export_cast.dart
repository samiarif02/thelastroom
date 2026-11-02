// Writes assets/cast/cast.json from the Dart cast (lib/src/cast): run from packages/brand with
// `flutter test tool/export_cast.dart` after changing a shape or a colour, then commit both.
// (A test entrypoint, because the cast's colours need dart:ui.)
import 'dart:io';

import 'package:brand/brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export the cast', () {
    File(CastJson.path)
      ..createSync(recursive: true)
      ..writeAsStringSync(CastJson.encode());
  });
}
