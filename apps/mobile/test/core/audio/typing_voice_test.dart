import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/audio/cue.dart';
import 'package:the_last_room/core/audio/typing_voice.dart';

void main() {
  late Duration now;
  TypingTicker ticker({int seed = 1}) =>
      TypingTicker(random: Random(seed), now: () => now);

  // Types [text] one character per [step], like the typewriter, and returns the ticks.
  List<TypingTick?> type(
    TypingTicker t,
    String text, {
    TypingVoice voice = TypingVoice.priya,
    Duration step = const Duration(milliseconds: 35),
  }) {
    final ticks = <TypingTick?>[];
    for (final ch in text.split('')) {
      ticks.add(t.onCharacter(voice, ch));
      now += step;
    }
    return ticks;
  }

  setUp(() => now = Duration.zero);

  test('each interviewer has their own key; anyone else types as Priya', () {
    expect(TypingVoice.forInterviewer('priya').cue, Cue.typePriya);
    expect(TypingVoice.forInterviewer('marcus').cue, Cue.typeMarcus);
    expect(TypingVoice.forInterviewer('lena').cue, Cue.typeLena);
    expect(TypingVoice.forInterviewer('sam').cue, Cue.typeSam);
    expect(TypingVoice.forInterviewer('narrator'), TypingVoice.priya);
    expect(
      TypingVoice.values.map((v) => v.cue).toSet(),
      hasLength(TypingVoice.values.length),
    );
  });

  test('silent on spaces and punctuation', () {
    final t = ticker();
    final ticks = type(t, ' ,.;:!?\'"-—() \n\t' * 4);
    expect(ticks.whereType<TypingTick>(), isEmpty);
  });

  test('a tick every 2nd–3rd letter, never two letters in a row', () {
    for (var seed = 0; seed < 20; seed++) {
      now = Duration.zero;
      final ticks = type(ticker(seed: seed), 'abcdefghijklmnopqrstuvwxyz' * 3);
      final at = [
        for (var i = 0; i < ticks.length; i++)
          if (ticks[i] != null) i,
      ];
      expect(at.first, inInclusiveRange(1, 2));
      for (var k = 1; k < at.length; k++) {
        expect(at[k] - at[k - 1], inInclusiveRange(2, 3), reason: 'seed $seed');
      }
    }
  });

  test('spaces and punctuation do not count towards the next tick', () {
    final t = ticker(seed: 3);
    final plain = type(t, 'abcdef').map((x) => x != null).toList();
    now = Duration.zero;
    final spaced = type(
      ticker(seed: 3),
      'a b, c. d e f',
    ).where((x) => x != null).length;
    expect(spaced, plain.where((x) => x).length);
  });

  test('pitch varies within ±6%', () {
    final ticks = type(
      ticker(seed: 9),
      'abcdefghij' * 20,
    ).whereType<TypingTick>().toList();
    expect(ticks.length, greaterThan(30));
    for (final tick in ticks) {
      expect(tick.speed, inInclusiveRange(0.94, 1.06));
    }
    expect(ticks.map((t) => t.speed).toSet().length, greaterThan(10));
  });

  test('the same seed gives the same ticks', () {
    final a = type(ticker(seed: 5), 'reproducible sound');
    now = Duration.zero;
    final b = type(ticker(seed: 5), 'reproducible sound');
    expect(a.map((t) => t?.speed), b.map((t) => t?.speed));
  });

  test('at most 18 ticks a second, however fast the text types', () {
    final ticks = type(
      ticker(),
      'a' * 600,
      step: const Duration(milliseconds: 5),
    );
    // 600 characters at 5 ms is 3 seconds of typing.
    final count = ticks.whereType<TypingTick>().length;
    expect(count, lessThanOrEqualTo(3 * TypingTicker.maxPerSecond + 1));
    // Ticks can only land on 5 ms steps, so a little under the cap.
    expect(count, greaterThan(3 * TypingTicker.maxPerSecond * 0.85));
  });

  test('"…" gives a softer, lower pause tick, even right after a letter', () {
    final t = ticker();
    type(t, 'ab');
    now += const Duration(milliseconds: 200);
    final pause = t.onCharacter(TypingVoice.lena, TypingTicker.ellipsis)!;
    expect(pause.cue, Cue.typeLena);
    expect(pause.speed, TypingTicker.pauseSpeed);
    expect(pause.gain, lessThan(1));
  });

  test('reset starts the count again (tap to complete)', () {
    final t = ticker(seed: 2);
    expect(t.onCharacter(TypingVoice.sam, 'a'), isNull);
    t.reset();
    now += const Duration(seconds: 1);
    expect(t.onCharacter(TypingVoice.sam, 'b'), isNull);
  });

  test('letters in any script tick; symbols do not', () {
    expect(TypingTicker.isVoiced('é'), isTrue);
    expect(TypingTicker.isVoiced('7'), isTrue);
    expect(TypingTicker.isVoiced('ß'), isTrue);
    expect(TypingTicker.isVoiced('€'), isFalse);
    expect(TypingTicker.isVoiced(''), isFalse);
  });
}
