import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';
import 'package:the_last_room/ui/subtitle/typewriter_subtitle.dart';

import 'mission_harness.dart';

/// The owner's three fixes from the 06a phone review (2026-10-30), brief 10, as they hold in
/// the Daylight room (brief 46).
void main() {
  /// The interviewer's face in the room: the top 55% of the bust's box (the head and neck;
  /// the shoulders below are what the bubble may overlap, by design).
  Rect face(WidgetTester tester) {
    final figure = tester.getRect(find.byType(CastFigure).first);
    return Rect.fromLTRB(
      figure.left,
      figure.top,
      figure.right,
      figure.top + figure.height * _head,
    );
  }

  group('1. the bubble never covers the face', () {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('375×667 at ${textScale}x text, from the first line to the '
          'follow-up', (tester) async {
        final rig = MissionRig(tester);
        await rig.boot(Routes.mission(1), textScale: textScale);
        await rig.startInterview();
        final bubble = find.byType(TypewriterSubtitle);
        var frames = 0;
        void check() {
          if (bubble.evaluate().isEmpty ||
              find.byType(RoomStage).evaluate().isEmpty) {
            return;
          }
          frames++;
          expect(
            tester.getRect(bubble).top,
            greaterThanOrEqualTo(face(tester).bottom),
            reason: 'frame $frames',
          );
        }

        final lines = rig.state(1).scene.length + 1;
        for (var i = 0; i < lines; i++) {
          await rig.until(bubble, eachFrame: check);
          await rig.run(const Duration(milliseconds: 400), eachFrame: check);
          if (rig.typing) await rig.tapScene();
          check();
          if (i < lines - 1) await rig.tapNext();
        }
        await rig.skipDraft();
        await rig.run(const Duration(seconds: 1), eachFrame: check);
        final m = rig.state(1).mission;
        for (final beat in m.beats) {
          await rig.say(beat.options.first);
          await rig.run(const Duration(milliseconds: 950), eachFrame: check);
        }
        await rig.until(
          find.text(rig.state(1).followUpLine!.text),
          eachFrame: check,
        );
        await rig.run(const Duration(seconds: 2), eachFrame: check);
        expect(frames, greaterThan(20));
      });
    }
  });

  // 2. "No stray rim-light dot" was the silhouette's; the Daylight cast has no dark to float
  // one in.

  group('3. edge to edge', () {
    testWidgets('transparent bars, edge-to-edge mode, dark icons on the '
        'daylit room', (tester) async {
      final modes = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
            modes.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final rig = MissionRig(tester);
      await rig.boot(Routes.mission(1));
      await rig.run(const Duration(seconds: 1));
      expect(modes, contains(SystemUiMode.edgeToEdge.toString()));
      final regions = tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .toList();
      // The app's root keeps the bars transparent; the room's ground sets the icons.
      expect(regions.first.value, EdgeToEdge.style);
      final room = regions.last.value;
      expect(room.statusBarColor!.a, 0);
      expect(room.systemNavigationBarColor!.a, 0);
    });

    testWidgets(
      'the room draws under the bars; its content stays clear of them',
      (tester) async {
        const insets = EdgeInsets.only(top: 32, bottom: 24);
        final rig = MissionRig(tester);
        await rig.boot(Routes.mission(1), viewPadding: insets);
        await rig.playLines(1);
        await rig.skipDraft();
        await rig.until(find.byType(ChoiceCard));
        await rig.run(const Duration(seconds: 1));

        // The ground fills the whole screen, bars included: no flat bands.
        expect(
          tester.getRect(find.byType(DaylightGround).last),
          Offset.zero & MissionRig.phone,
        );
        // The top bar and the dock keep clear of the status and navigation bars.
        expect(
          tester.getRect(find.byType(TrustPips)).top,
          greaterThanOrEqualTo(insets.top),
        );
        expect(
          tester.getRect(find.byType(TactileButton).last).bottom,
          lessThanOrEqualTo(MissionRig.phone.height - insets.bottom),
        );
      },
    );
  });
}

/// The head and neck's share of the bust's box.
const double _head = 0.55;
