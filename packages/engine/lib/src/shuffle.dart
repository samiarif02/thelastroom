/// The on-screen order of [length] options for one attempt: a permutation of `0..length-1`,
/// reproducible from [seed] and [salt] (owner's note, brief 10: options are shuffled per
/// attempt, never shown in file order, where the best line is often first).
///
/// [seed] is the attempt's seed, stored with the attempt, so a replay shows the same order;
/// [salt] tells the beats of one attempt apart (the beat's index), so each beat gets its own
/// order from the one seed.
///
/// The generator is xorshift32 with every step masked to 32 bits, so the same seed gives the
/// same order on the Dart VM (64-bit ints) and on the web (JavaScript numbers), where
/// `dart:math`'s seeded `Random` isn't guaranteed to agree.
List<int> shuffledOrder(int length, {required int seed, int salt = 0}) {
  RangeError.checkNotNegative(length, 'length');
  final order = List<int>.generate(length, (i) => i);
  final next = _XorShift32(_mix(seed, salt));
  // Fisher–Yates, from the end.
  for (var i = length - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final swap = order[i];
    order[i] = order[j];
    order[j] = swap;
  }
  return List.unmodifiable(order);
}

/// [items] in the order [shuffledOrder] gives them.
List<T> shuffled<T>(List<T> items, {required int seed, int salt = 0}) => [
  for (final i in shuffledOrder(items.length, seed: seed, salt: salt)) items[i],
];

const int _mask32 = 0xFFFFFFFF;

/// A non-zero 32-bit state from a seed and a salt (xorshift is stuck at zero). The salt is
/// spread by an odd constant so salts 0, 1, 2 land far apart.
int _mix(int seed, int salt) {
  final state = (seed ^ (salt * _saltSpread)) & _mask32;
  return state == 0 ? _zeroSeedState : state;
}

/// The golden-ratio constant, 2³² / φ: spreads consecutive salts across the 32-bit space.
const int _saltSpread = 0x9E3779B9;

/// Any fixed non-zero state for a seed that mixes to zero.
const int _zeroSeedState = 0x6D2B79F5;

class _XorShift32 {
  _XorShift32(this._state);

  int _state;

  static const int _a = 13;
  static const int _b = 17;
  static const int _c = 5;

  int call() {
    var x = _state;
    x ^= (x << _a) & _mask32;
    x ^= x >> _b;
    x ^= (x << _c) & _mask32;
    return _state = x & _mask32;
  }
}
