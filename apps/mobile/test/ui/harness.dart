import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

/// A phone-sized stage for one film-kit component: brand text style, the ambient clock, and
/// the given text scale and reduced-motion setting.
Future<void> pumpKit(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(375, 667),
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: BrandType.body,
          child: AmbientClock(child: child),
        ),
      ),
    ),
  );
}

/// Pumps [total] in [step]s, failing on the first frame that throws (an overflow mid-animation,
/// not only at the end).
Future<void> pumpThrough(
  WidgetTester tester,
  Duration total, {
  Duration step = const Duration(milliseconds: 100),
  void Function()? eachFrame,
}) async {
  for (var e = Duration.zero; e < total; e += step) {
    await tester.pump(step);
    expect(tester.takeException(), isNull, reason: 'at $e');
    eachFrame?.call();
  }
}
