import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/title/daylight_title.dart';

/// The first-launch title (#68: the tower's rooms are its doors) at the phone widths the app
/// meets, 360 to 411, mid-way and settled. Each still must draw without an exception; with
/// `WRITE_STILLS=1` each is saved as a PNG at 2x in `.pr-screenshots/68/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;

  Future<void> still(
    WidgetTester tester,
    Size phone,
    String name, {
    Duration? at,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = phone;
    addTearDown(tester.view.reset);
    // A fresh title each time, so its timeline starts over.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: phone),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: DaylightTitle(),
        ),
      ),
    );
    final end = at ?? DaylightTitle.length * 2;
    for (var e = Duration.zero; e < end; e += _step) {
      await tester.pump(_step);
    }
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & phone,
        pixelRatio: pixelRatio,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/68/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('the title at 360, 390 and 411, lighting and lit', (
    tester,
  ) async {
    await still(tester, const Size(360, 780), 'title-360');
    await still(tester, const Size(390, 844), 'title-390');
    await still(tester, const Size(411, 891), 'title-411');
    await still(
      tester,
      const Size(390, 844),
      'title-390-floor-1',
      at: const Duration(milliseconds: 250),
    );
    await still(
      tester,
      const Size(390, 844),
      'title-390-before-sam',
      at: const Duration(milliseconds: 450),
    );
    await tester.pumpWidget(const SizedBox());
  });
}

const Duration _step = Duration(milliseconds: 50);
