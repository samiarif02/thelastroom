import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/features/placeholder/placeholder_screen.dart';

void main() {
  testWidgets('the app boots to the title screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TheLastRoomApp()));
    await tester.pumpAndSettle();

    expect(find.text(PlaceholderScreen.title), findsOneWidget);
    expect(find.text(PlaceholderScreen.tagline), findsOneWidget);
  });

  testWidgets('text inherits the brand style, not the debug fallback', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TheLastRoomApp()));
    await tester.pumpAndSettle();

    // Without a DefaultTextStyle ancestor Flutter draws a yellow double underline.
    final style = DefaultTextStyle.of(
      tester.element(find.text(PlaceholderScreen.tagline)),
    ).style;
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(style.color, BrandType.body.color);
  });

  testWidgets('the title survives 2x text scaling without overflow', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(375, 667) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ProviderScope(child: TheLastRoomApp()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(PlaceholderScreen.title), findsOneWidget);
  });
}
