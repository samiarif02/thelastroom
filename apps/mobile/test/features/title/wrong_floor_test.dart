import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/title/wrong_floor_screen.dart';

void main() {
  testWidgets('an unknown address is the wrong floor, with a way back', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(375, 667) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TheLastRoomApp(),
      ),
    );
    container.read(routerProvider).go('/no/such/room');
    await tester.pump();
    await tester.pump(BrandMotion.cinematic);
    expect(find.byType(WrongFloorScreen), findsOneWidget);
    expect(find.text(WrongFloorScreen.title), findsOneWidget);
    expect(find.text('Page Not Found'), findsNothing);

    await tester.tap(find.text(WrongFloorScreen.action));
    await tester.pump();
    await tester.pump(BrandMotion.standard);
    expect(find.byType(TitleScreen), findsOneWidget);
  });
}
