import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/ui/film_kit.dart';

void main() {
  Future<void> boot(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize =
        const Size(375, 667) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const ProviderScope(child: TheLastRoomApp()),
      ),
    );
    // The room never settles (grain, lamp, dust), so pump through the card.
    for (var e = Duration.zero; e < BrandMotion.titleCard; e += _step) {
      await tester.pump(_step);
      expect(tester.takeException(), isNull);
    }
  }

  testWidgets('the app opens on the Boardroom title card', (tester) async {
    await boot(tester);
    expect(find.byType(TitleScreen), findsOneWidget);
    final words = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(TrackedTitle),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .join(' ');
    expect(words, TitleScreen.title);
    expect(find.text(TitleScreen.tagline), findsOneWidget);
    expect(find.byType(BankersLamp), findsOneWidget);
  });

  testWidgets('every frame is on film stock: grain and vignette', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byType(FilmOverlay), findsOneWidget);
    expect(find.byType(AmbientClock), findsOneWidget);
  });

  testWidgets('text inherits the brand style, not the debug fallback', (
    tester,
  ) async {
    await boot(tester);
    // Without a DefaultTextStyle ancestor Flutter draws a yellow double underline.
    final style = DefaultTextStyle.of(
      tester.element(find.text(TitleScreen.tagline)),
    ).style;
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(style.fontFamily, BrandType.body.fontFamily);
  });

  testWidgets('the title card survives 2x text without overflow', (
    tester,
  ) async {
    await boot(tester, textScale: 2);
    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets('announced as one header', (tester) async {
    final handle = tester.ensureSemantics();
    await boot(tester);
    expect(
      find.bySemanticsLabel('${TitleScreen.eyebrow}: ${TitleScreen.title}'),
      findsOneWidget,
    );
    handle.dispose();
  });
}

const Duration _step = Duration(milliseconds: 100);
