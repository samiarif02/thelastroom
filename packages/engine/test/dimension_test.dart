import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  test('the dimension weights sum to 100', () {
    final total = Dimension.values.fold<int>(
      0,
      (sum, d) => sum + d.weightPercent,
    );
    expect(total, 100);
  });

  test('specificity carries the most weight', () {
    final heaviest = Dimension.values.reduce(
      (a, b) => a.weightPercent >= b.weightPercent ? a : b,
    );
    expect(heaviest, Dimension.specificity);
  });
}
