import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/scene/mission_card.dart';
import 'package:the_last_room/features/mission/widgets/beat_timer.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/mission/widgets/draft_panel.dart';
import 'package:the_last_room/features/mission/widgets/next_control.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'mission_harness.dart';

/// The owner's first-play fixes 1 and 2 (brief 13): the Next control and auto-advance.
void main() {
  /// Boots Mission 1 and waits for its first line to finish typing.
  Future<MissionRig> firstLineTyped(
    WidgetTester tester, {
    PlayerProfile profile = onboardedPlayer,
    double textScale = 1,
  }) async {
    final rig = MissionRig(tester, profile: profile);
    await rig.boot(Routes.mission(1), textScale: textScale);
    await rig.until(find.byType(MissionCard));
    await rig.tapScene();
    await rig.until(find.byType(NextControl));
    return rig;
  }

  String lineOnScreen(WidgetTester tester) =>
      tester.widget<TypewriterText>(find.byType(TypewriterText)).text;

  testWidgets('the Next control is at least 48 dp tall and labelled', (
    tester,
  ) async {
    await firstLineTyped(tester);
    final size = tester.getSize(find.byType(NextControl));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.textContaining('NEXT'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Next')), findsOneWidget);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('one tap on Next always moves on (${textScale}x text)', (
      tester,
    ) async {
      final rig = await firstLineTyped(tester, textScale: textScale);
      final first = lineOnScreen(tester);
      await rig.tapNext();
      expect(lineOnScreen(tester), isNot(first));
    });
  }

  testWidgets('a tap anywhere in the lower third moves on, first time', (
    tester,
  ) async {
    final rig = await firstLineTyped(tester);
    final first = lineOnScreen(tester);
    // On the subtitle itself, where the old ▸ sat above: this tap used to be swallowed.
    await tester.tapAt(tester.getCenter(find.byType(TypewriterText)));
    await tester.pump();
    expect(lineOnScreen(tester), isNot(first));
    await rig.run(const Duration(milliseconds: 100));
  });

  testWidgets('a line moves on by itself 6 s after it has typed', (
    tester,
  ) async {
    final rig = await firstLineTyped(tester);
    final first = lineOnScreen(tester);
    await rig.run(
      MissionPlayer.autoAdvanceAfter - const Duration(milliseconds: 300),
    );
    expect(lineOnScreen(tester), first, reason: 'not before 6 s');
    expect(find.textContaining('·  1'), findsOneWidget, reason: 'countdown');
    await rig.run(const Duration(milliseconds: 400));
    expect(lineOnScreen(tester), isNot(first));
  });

  testWidgets('touching the scene pauses the countdown', (tester) async {
    final rig = await firstLineTyped(tester);
    final first = lineOnScreen(tester);
    await rig.run(const Duration(seconds: 2));
    await rig.tapScene();
    expect(
      find.textContaining(NextControl.pausedLabel.toUpperCase()),
      findsOne,
    );
    await rig.run(const Duration(seconds: 10));
    expect(lineOnScreen(tester), first, reason: 'paused, it waits');
    await rig.tapNext();
    expect(lineOnScreen(tester), isNot(first));
  });

  testWidgets('auto-advance can be switched off', (tester) async {
    final rig = await firstLineTyped(
      tester,
      profile: onboardedPlayer.copyWith(autoAdvance: false),
    );
    final first = lineOnScreen(tester);
    await rig.run(const Duration(seconds: 12));
    expect(lineOnScreen(tester), first);
    expect(find.textContaining('·  '), findsNothing, reason: 'no countdown');
  });

  testWidgets('the question never auto-advances; the cards wait untimed', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await rig.run(const Duration(seconds: 20));
    // Still on the draft step: nothing moved the player on.
    expect(find.text(DraftPanel.skip), findsOneWidget);
  });

  testWidgets('calm mode hides the answer timer on a timed mission', (
    tester,
  ) async {
    final rig = MissionRig(
      tester,
      profile: onboardedPlayer.copyWith(calmMode: true),
    );
    await rig.boot(Routes.mission(2));
    await rig.playLines(2);
    await rig.until(find.byType(ChoiceCard));
    await rig.run(const Duration(seconds: 70));
    expect(find.byType(BeatTimer), findsNothing);
    expect(rig.sounds.count('timerPulse'), 0);
  });
}
