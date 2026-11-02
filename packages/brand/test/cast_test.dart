import 'dart:io';

import 'package:brand/brand.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cast as data: four people, seven expressions, and the JSON the web draws from.
void main() {
  test('assets/cast/cast.json is the Dart cast, exported (run tool/export_cast.dart)', () {
    expect(File(CastJson.path).readAsStringSync(), CastJson.encode());
  });

  test('four people, each found by content id', () {
    expect(CastPeople.all.map((p) => p.id), ['priya', 'marcus', 'lena', 'sam']);
    for (final p in CastPeople.all) {
      expect(CastPeople.byId(p.id), same(p));
      expect(p.front, isNotEmpty, reason: p.id);
      expect(p.clothes, isNotEmpty, reason: p.id);
    }
    expect(CastPeople.byId('nobody'), same(CastPeople.priya));
  });

  test('every person paints every role', () {
    for (final p in CastPeople.all) {
      for (final ink in CastInk.values) {
        expect(p.palette.of(ink).a, 1, reason: '${p.id} ${ink.name}');
      }
    }
  });

  test('the seven expressions are seven different faces', () {
    expect(CastExpression.values.map((e) => e.name), [
      'neutral',
      'listening',
      'thinking',
      'nod',
      'smile',
      'hmm',
      'talk',
    ]);
    final faces = {
      for (final e in CastExpression.values)
        (
          e.pose.eyes,
          e.pose.browLeft,
          e.pose.browRight,
          e.pose.mouth,
          e.pose.rotation,
        ),
    };
    expect(faces, hasLength(CastExpression.values.length));
  });

  test('brows that rise lift the lid crease with them', () {
    expect(CastExpression.listening.pose.creaseLift, CastFeatures.creaseLift);
    expect(CastExpression.thinking.pose.creaseLift, CastFeatures.creaseLift);
    expect(CastExpression.neutral.pose.creaseLift, 0);
  });

  test('the eyes are small almonds, about 16% of the face', () {
    const faceWidth = 80;
    final eye = CastFeatures.eye(CastEyes.open, CastFeatures.eyeLeftX).first;
    final d = (eye as CastPath).d;
    final xs = RegExp(r'M([\d.]+) [\d.]+ Q[\d.]+ [\d.]+ ([\d.]+)')
        .firstMatch(d)!;
    final width = double.parse(xs.group(2)!) - double.parse(xs.group(1)!);
    expect(width / faceWidth, closeTo(0.16, 0.02));
  });

  test('numbers in paths have at most two decimals and no float noise', () {
    expect(castNumber(84 - 6.6), '77.4');
    expect(castNumber(84), '84');
    expect(castNumber(-0.001), '0');
    expect(castNumber(116 + 1.9), '117.9');
  });
}
