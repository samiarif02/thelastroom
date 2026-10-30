import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/audio/cue.dart';

// Tests run from apps/mobile, so the repo root is two levels up.
const String _credits = '../../docs/audio-credits.md';
const String _recipes = '../../tools/audio/cues.py';

void main() {
  test('every cue has a file in each format', () {
    for (final cue in Cue.values) {
      for (final format in CueFormat.values) {
        final file = File(cue.assetPath(format));
        expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
        expect(file.lengthSync(), greaterThan(0));
      }
    }
  });

  test('every bundled file belongs to a cue (no orphans)', () {
    final expected = {
      for (final cue in Cue.values)
        for (final format in CueFormat.values) cue.assetPath(format),
    };
    final shipped = Directory('assets/audio')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .toSet();
    expect(shipped, expected);
  });

  test('every cue has a recipe and a credits row with a real licence', () {
    final credits = File(_credits).readAsLinesSync();
    final recipes = File(_recipes).readAsStringSync();
    for (final cue in Cue.values) {
      final row = credits.where(
        (l) => l.startsWith('| `${cue.asset}.ogg`, `${cue.asset}.m4a`'),
      );
      expect(row, hasLength(1), reason: 'no credits row for ${cue.asset}');
      expect(row.single, contains('CC0 1.0'));
      expect(recipes, contains('@cue("${cue.asset}"'));
    }
  });

  test('asset names are unique, and loops follow the ambience volume', () {
    expect(
      Cue.values.map((c) => c.asset).toSet(),
      hasLength(Cue.values.length),
    );
    for (final cue in Cue.values.where((c) => c.loops)) {
      expect(cue.bus, CueBus.ambience, reason: '$cue');
    }
  });

  test('Apple gets M4A; Android, desktop and the web get OGG', () {
    expect(CueFormat.forPlatform(isWeb: true), CueFormat.ogg);
    expect(
      CueFormat.forPlatform(isWeb: false, platform: TargetPlatform.iOS),
      CueFormat.m4a,
    );
    expect(
      CueFormat.forPlatform(isWeb: false, platform: TargetPlatform.android),
      CueFormat.ogg,
    );
    expect(Cue.stamp.assetPath(CueFormat.m4a), 'assets/audio/m4a/stamp.m4a');
  });

  test('the library stays small (aim: under 3 MB, both formats)', () {
    final bytes = Directory('assets/audio')
        .listSync(recursive: true)
        .whereType<File>()
        .fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(bytes, lessThan(3 * 1024 * 1024));
  });
}
