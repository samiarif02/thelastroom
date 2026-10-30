import 'package:brand/brand.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the theme has no ripple and no stock page transition', () {
    final theme = BrandTheme.dark();
    expect(theme.splashFactory, NoSplash.splashFactory);
    for (final platform in TargetPlatform.values) {
      final builder = theme.pageTransitionsTheme.builders[platform];
      expect(builder, isNotNull, reason: platform.name);
      expect(builder, isNot(isA<ZoomPageTransitionsBuilder>()));
      expect(builder, isNot(isA<CupertinoPageTransitionsBuilder>()));
    }
  });

  test('each chapter grade re-tints the accent', () {
    for (final grade in ChapterGrade.values) {
      expect(BrandTheme.dark(grade: grade).colorScheme.primary, grade.key);
    }
  });

  test(
    'Material text that slips through still renders in the bundled sans',
    () {
      final theme = BrandTheme.dark();
      expect(
        theme.textTheme.bodyMedium!.fontFamily,
        'packages/brand/${BrandFonts.sans}',
      );
      expect(
        theme.textTheme.displayLarge!.fontFamily,
        BrandType.titleCard.fontFamily,
      );
    },
  );
}
