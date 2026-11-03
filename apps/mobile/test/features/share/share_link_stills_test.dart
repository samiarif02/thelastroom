import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/audio/game_sounds.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/progression/floor_cleared_screen.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/share/card_renderer.dart';
import 'package:the_last_room/features/share/card_sharer.dart';
import 'package:the_last_room/features/share/share_floor_card_link.dart';

import '../progression/progression_test.dart' show attempt;

class _Quiet implements Analytics {
  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) {}
}

class _Renderer implements CardRenderer {
  @override
  Future<Uint8List> render(
    Widget child, {
    required Size size,
    required double pixelRatio,
    required ui.FlutterView view,
  }) async => Uint8List(0);
}

class _Failing implements CardSharer {
  @override
  Future<ShareOutcome> share({
    required Uint8List png,
    required String fileName,
    required String text,
    ui.Rect? origin,
  }) async => throw Exception('no share target');
}

/// The PR's stills of the link (brief 54): the floor-cleared screen scrolled to its foot, and
/// the calm bubble when sharing can't open. 360 × 800 at 3x, like the phone. Written to
/// `.pr-screenshots/54/` with `WRITE_STILLS=1`; otherwise only drawn.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  final now = DateTime(2026, 11, 4, 18);
  const size = Size(360, 800);
  const stage = ValueKey('stage');

  Future<void> shot(WidgetTester tester, String name) async {
    if (!write) return;
    final boundary =
        tester.renderObject(find.byKey(stage)) as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final out = File('../../.pr-screenshots/54/$name.png');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(png!.buffer.asUint8List());
    });
  }

  testWidgets('floor cleared, the link, then the bubble', (tester) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = size * 3;
    addTearDown(tester.view.reset);
    final progress = InMemoryProgressRepository();
    for (final m in missions.where((m) => m.chapter == 1)) {
      await progress.recordAttempt(attempt(m, 80, at: now));
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logProvider.overrideWithValue(Log(sink: (_) {})),
          analyticsProvider.overrideWithValue(_Quiet()),
          gameSoundsProvider.overrideWithValue(const SilentGameSounds()),
          progressRepositoryProvider.overrideWithValue(progress),
          progressionStoreProvider.overrideWithValue(
            InMemoryProgressionStore(),
          ),
          progressionClockProvider.overrideWithValue(() => now),
          profileRepositoryProvider.overrideWithValue(
            InMemoryProfileRepository(const PlayerProfile(firstName: 'Sami')),
          ),
          cardRendererProvider.overrideWithValue(_Renderer()),
          cardSharerProvider.overrideWithValue(_Failing()),
        ],
        child: RepaintBoundary(
          key: stage,
          child: MediaQuery(
            data: const MediaQueryData(
              size: size,
              devicePixelRatio: 3,
              disableAnimations: true,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: DefaultTextStyle(
                style: DaylightType.body5,
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (_) => const FloorClearedScreen(floor: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(ShareFloorCardLink.label),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await shot(tester, 'after-floor-cleared-link');

    await tester.tap(find.text(ShareFloorCardLink.label));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump();
    expect(find.text(ShareFloorCardLink.trouble), findsOneWidget);
    await shot(tester, 'after-share-failed-bubble');
    await tester.pump(ShareFloorCardLink.troubleFor);
  });
}
