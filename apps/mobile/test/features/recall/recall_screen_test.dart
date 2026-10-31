import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/recall/recall_card_view.dart';
import 'package:the_last_room/features/recall/recall_controller.dart';
import 'package:the_last_room/features/recall/recall_screen.dart';
import 'package:the_last_room/features/recall/recall_store.dart';
import 'package:the_last_room/features/tower/tower_extras.dart';

import 'recall_fixtures.dart';

void main() {
  late InMemoryProgressRepository progress;
  late DateTime now;

  setUp(() {
    progress = InMemoryProgressRepository();
    now = DateTime(2026, 10, 31, 18);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
  }) async {
    final container = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(Log(sink: (_) {})),
        progressRepositoryProvider.overrideWithValue(progress),
        recallStoreProvider.overrideWithValue(InMemoryRecallStore()),
        recallClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    const size = Size(390, 844);
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(style: BrandType.body, child: child),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('no mistakes yet: the room explains where cards come from', (
    tester,
  ) async {
    await pump(tester, const RecallScreen());
    expect(find.text(RecallScreen.noCardsTitle), findsOneWidget);
  });

  testWidgets('a trap card: one tap answers it, then the verdict and Next', (
    tester,
  ) async {
    final (weak, trap) = weakOf(m1.beats[0]);
    await progress.recordAttempt(
      m1Attempt([weak, strongestOf(m1.beats[1]), strongestOf(m1.beats[2])]),
    );
    final c = await pump(tester, const RecallScreen());
    expect(find.text('“${trap.text}”'), findsOneWidget);
    final playing = c.read(recallRoomProvider) as RecallPlaying;
    final right = playing.question.choices.firstWhere(
      (ch) => ch.id == playing.question.correctChoiceId,
    );
    now = now.add(const Duration(seconds: 4));
    await tester.ensureVisible(find.text(right.text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(right.text));
    await tester.pumpAndSettle();
    expect(find.text(RecallCardView.known), findsOneWidget);
    expect(find.text(RecallCardView.finish), findsOneWidget);
    await tester.ensureVisible(find.text(RecallCardView.finish));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RecallCardView.finish));
    await tester.pumpAndSettle();
    expect(find.text(RecallScreen.doneTitle), findsOneWidget);
  });

  testWidgets('survives 2x text', (tester) async {
    final (weak, _) = weakOf(m1.beats[0]);
    await progress.recordAttempt(
      m1Attempt([weak, strongestOf(m1.beats[1]), strongestOf(m1.beats[2])]),
    );
    await pump(tester, const RecallScreen(), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tower card shows how many cards are due', (tester) async {
    await pump(tester, const RecallRoomCardView(due: 3));
    expect(find.text(RecallRoomCardView.dueKicker(3)), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await pump(tester, const RecallRoomCardView(due: 0));
    expect(
      find.text(RecallRoomCardView.caughtUp.toUpperCase()),
      findsOneWidget,
    );
  });
}
