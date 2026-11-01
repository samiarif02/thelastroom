import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  Widget toggle({required bool value, ValueChanged<bool>? onChanged}) => Center(
    child: VividToggle(
      label: 'Calm mode',
      value: value,
      onChanged: onChanged ?? (_) {},
    ),
  );

  testWidgets('a tap flips it', (tester) async {
    bool? got;
    await pumpKit(tester, toggle(value: false, onChanged: (v) => got = v));
    await tester.tap(find.byType(VividToggle));
    expect(got, isTrue);
  });

  testWidgets('screen readers hear a toggle and its state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, toggle(value: true));
    expect(
      tester.getSemantics(find.byType(VividToggle)),
      isSemantics(label: 'Calm mode', hasToggledState: true, isToggled: true),
    );
    handle.dispose();
  });

  testWidgets('it sinks under the finger, unless motion is reduced', (
    tester,
  ) async {
    for (final still in [false, true]) {
      await pumpKit(tester, toggle(value: false), reduceMotion: still);
      final press = await tester.startGesture(
        tester.getCenter(find.byType(VividToggle)),
      );
      await tester.pump();
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale < 1, !still, reason: 'reduced motion: $still');
      await press.up();
      await tester.pump(BrandMotion.quick);
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('a 44 pt row at ${scale}x text', (tester) async {
      await pumpKit(tester, toggle(value: true), textScale: scale);
      expect(
        tester.getSize(find.byType(VividToggle)).height,
        greaterThanOrEqualTo(BrandSpace.minTarget),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
