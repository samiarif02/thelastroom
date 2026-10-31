import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/title/vivid_title.dart';
import 'package:the_last_room/ui/film_kit.dart';

void main() {
  Future<void> boot(
    WidgetTester tester, {
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize =
        const Size(375, 667) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: const ProviderScope(child: TheLastRoomApp()),
      ),
    );
    // The sky never settles (its lights drift), so pump through the title.
    for (var e = Duration.zero; e < VividTitle.length * 2; e += _step) {
      await tester.pump(_step);
      expect(tester.takeException(), isNull);
    }
  }

  testWidgets('a first launch opens on the vivid title, the tower lit', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.byType(VividBackdrop), findsWidgets);
    expect(find.text(TitleScreen.title), findsOneWidget);
    expect(find.text(TitleScreen.tagline), findsOneWidget);
    final tower = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<TowerPainter>()
        .single;
    expect(tower.lit, 1);
  });

  testWidgets('the title lasts about a second and a half', (tester) async {
    expect(VividTitle.length, lessThanOrEqualTo(const Duration(seconds: 2)));
  });

  testWidgets('under reduced motion it shows its last frame at once', (
    tester,
  ) async {
    await boot(tester, reduceMotion: true);
    final tower = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<TowerPainter>()
        .single;
    expect(tower.lit, 1);
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

  testWidgets('the title survives 2x text without overflow', (tester) async {
    await boot(tester, textScale: 2);
    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets('the name is announced as a header', (tester) async {
    final handle = tester.ensureSemantics();
    await boot(tester);
    expect(
      tester.getSemantics(find.text(TitleScreen.title)),
      isSemantics(isHeader: true),
    );
    handle.dispose();
  });
}

const Duration _step = Duration(milliseconds: 100);
