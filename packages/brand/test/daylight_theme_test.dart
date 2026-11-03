import 'package:brand/brand.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no ripple, no stock page transition', () {
    final theme = DaylightTheme.light();
    expect(theme.splashFactory, NoSplash.splashFactory);
    for (final platform in TargetPlatform.values) {
      final builder = theme.pageTransitionsTheme.builders[platform];
      expect(builder, isNotNull, reason: platform.name);
      expect(builder, isNot(isA<ZoomPageTransitionsBuilder>()));
      expect(builder, isNot(isA<CupertinoPageTransitionsBuilder>()));
    }
  });

  test('paper and ink, the floor as primary, honey as the action', () {
    for (final grade in ChapterGrade.values) {
      final theme = DaylightTheme.light(grade: grade);
      expect(theme.colorScheme.primary, grade.floor.base);
      expect(theme.colorScheme.secondary, DaylightColors.honey);
      expect(theme.scaffoldBackgroundColor, DaylightColors.paper);
    }
  });

  test('Material text that slips through renders in Geist', () {
    expect(
      DaylightTheme.light().textTheme.bodyMedium!.fontFamily,
      'packages/brand/${DaylightFonts.text}',
    );
  });

  test('motion: the base curve, and nothing under 200 ms', () {
    expect(DaylightMotion.ease, const Cubic(0.22, 1, 0.36, 1));
    for (final d in [
      DaylightMotion.press,
      DaylightMotion.colour,
      DaylightMotion.move,
      DaylightMotion.nod,
      DaylightMotion.countUp,
      DaylightMotion.ringClose,
    ]) {
      expect(d, greaterThanOrEqualTo(const Duration(milliseconds: 200)));
    }
  });

  test('spacing and radii come only from the scales', () {
    const space = [2, 4, 8, 12, 16, 24, 32, 40, 48, 64, 80, 96];
    expect([
      DaylightSpace.s2,
      DaylightSpace.s4,
      DaylightSpace.s8,
      DaylightSpace.s12,
      DaylightSpace.s16,
      DaylightSpace.s24,
      DaylightSpace.s32,
      DaylightSpace.s40,
      DaylightSpace.s48,
      DaylightSpace.s64,
      DaylightSpace.s80,
      DaylightSpace.s96,
    ], space);
    expect(
      [
        DaylightRadius.tag,
        DaylightRadius.inner,
        DaylightRadius.tile,
        DaylightRadius.card,
        DaylightRadius.panel,
      ],
      [6, 8, 12, 16, 24],
    );
    // The nested rule: a button in a panel card with 16 of padding.
    expect(DaylightRadius.panel - DaylightSpace.s16, DaylightRadius.inner);
  });

  test('the only shadows: a hard edge and a soft lift', () {
    expect(DaylightElevation.edge.single.blurRadius, 0);
    expect(DaylightElevation.edge.single.offset.dy, DaylightSize.edge);
    expect(DaylightElevation.lift.single.offset.dy, greaterThan(0));
  });
}
