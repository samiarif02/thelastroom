import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  group('shuffledOrder', () {
    test('is a permutation of every index', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final length in [0, 1, 3, 4]) {
          final order = shuffledOrder(length, seed: seed);
          expect(order.toSet(), {for (var i = 0; i < length; i++) i});
          expect(order, hasLength(length));
        }
      }
    });

    test('the same seed and salt give the same order (an attempt replays)', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(
          shuffledOrder(4, seed: seed, salt: 2),
          shuffledOrder(4, seed: seed, salt: 2),
        );
      }
    });

    test(
      'pinned orders, so the VM and the web build can be checked to agree',
      () {
        // If these change, every stored attempt replays in a different order: don't.
        expect(shuffledOrder(4, seed: 42), _pinned42);
        expect(shuffledOrder(3, seed: 7, salt: 1), _pinned7);
      },
    );

    test('the best option (file order: first) is not always shown first', () {
      const seeds = 200;
      var firstStaysFirst = 0;
      for (var seed = 0; seed < seeds; seed++) {
        if (shuffledOrder(4, seed: seed).first == 0) firstStaysFirst++;
      }
      // A fair shuffle puts it first about a quarter of the time.
      expect(firstStaysFirst, greaterThan(0));
      expect(firstStaysFirst, lessThan(seeds ~/ 2));
    });

    test('every position is reachable', () {
      final seen = <int>{};
      for (var seed = 0; seed < 100; seed++) {
        seen.add(shuffledOrder(4, seed: seed).indexOf(0));
      }
      expect(seen, {0, 1, 2, 3});
    });

    test('the beats of one attempt get different orders from the one seed', () {
      var differs = 0;
      for (var seed = 0; seed < 50; seed++) {
        final open = shuffledOrder(4, seed: seed);
        final evidence = shuffledOrder(4, seed: seed, salt: 1);
        if (open.toString() != evidence.toString()) differs++;
      }
      expect(differs, greaterThan(25));
    });

    test('a seed that mixes to zero still shuffles', () {
      final order = shuffledOrder(4, seed: 0);
      expect(order.toSet(), {0, 1, 2, 3});
    });

    test('a negative length is an error', () {
      expect(() => shuffledOrder(-1, seed: 1), throwsRangeError);
    });
  });

  test('shuffled reorders the items by shuffledOrder', () {
    const items = ['a', 'b', 'c', 'd'];
    final order = shuffledOrder(items.length, seed: 9, salt: 3);
    expect(shuffled(items, seed: 9, salt: 3), [
      for (final i in order) items[i],
    ]);
  });
}

const List<int> _pinned42 = [3, 2, 1, 0];
const List<int> _pinned7 = [0, 2, 1];
