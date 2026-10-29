import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  test('the content schema version is positive', () {
    expect(contentSchemaVersion, greaterThan(0));
  });

  test('content resolves the engine through the workspace', () {
    expect(Dimension.values, hasLength(4));
  });
}
