import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/scene/mission_set.dart';
import 'package:the_last_room/features/mission/widgets/trust_meter.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../../ui/harness.dart';
import 'mission_harness.dart';

/// The owner's three fixes from the 06a phone review (2026-10-30), brief 10.
void main() {
  /// The face on screen, measured from the painted silhouette (not from the geometry the
  /// screen lays out with), so the test checks the frame and not the maths.
  Rect face(WidgetTester tester) {
    final figure = tester.getRect(find.byType(InterviewerSilhouette));
    const d = SilhouetteFigure.designSize;
    const f = MissionSet.faceInDesign;
    return Rect.fromLTRB(
      figure.left + figure.width * f.left / d.width,
      figure.top + figure.height * f.top / d.height,
      figure.left + figure.width * f.right / d.width,
      figure.top + figure.height * f.bottom / d.height,
    );
  }

  /// What's visible of [finder]: its rect clipped to the lower third it scrolls in.
  Rect? visible(WidgetTester tester, Finder finder) {
    if (finder.evaluate().isEmpty) return null;
    final view = tester.getRect(find.byType(LowerThird));
    final shown = tester.getRect(finder).intersect(view);
    return shown.isEmpty ? null : shown;
  }

  void expectClear(WidgetTester tester, Finder text, String when) {
    final shown = visible(tester, text);
    if (shown == null) return;
    final f = face(tester);
    expect(
      shown.top,
      greaterThanOrEqualTo(f.bottom),
      reason: '$when: text at ${shown.top} over the face ending at ${f.bottom}',
    );
  }

  group('1. the subtitle never covers the face', () {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        '375×667 at ${textScale}x text, through the push and the cut',
        (tester) async {
          final rig = MissionRig(tester);
          await rig.boot(Routes.mission(1), textScale: textScale);
          await rig.until(find.byType(ChapterTitleCard));
          await rig.tapScene();
          final subtitle = find.byType(TypewriterSubtitle);
          var frames = 0;
          void check() {
            frames++;
            expectClear(tester, subtitle, 'frame $frames');
            expectClear(tester, find.byType(QuestionReminder), 'frame $frames');
          }

          // Every frame from the first line to the end of the push.
          final lines = rig.state(1).scene.length + 1;
          for (var i = 0; i < lines; i++) {
            await rig.until(subtitle, eachFrame: check);
            await rig.run(const Duration(milliseconds: 400), eachFrame: check);
            if (rig.typing) await rig.tapScene();
            check();
            if (i < lines - 1) await rig.tapScene();
          }
          await rig.run(BrandMotion.dolly, eachFrame: check);
          await rig.skipDraft();
          await rig.run(const Duration(seconds: 1), eachFrame: check);

          // The follow-up's tight shot.
          final m = rig.state(1).mission;
          for (final beat in m.beats) {
            await rig.say(beat.options.first);
            await rig.run(const Duration(milliseconds: 950), eachFrame: check);
          }
          await rig.until(
            find.text(rig.state(1).followUp!.line.text),
            eachFrame: check,
          );
          await rig.run(const Duration(seconds: 2), eachFrame: check);
          expect(frames, greaterThan(50));
        },
      );
    }

    test('the layout rule holds on other phones too (geometry)', () {
      for (final size in const [
        Size(375, 667),
        Size(390, 844),
        Size(360, 800),
      ]) {
        for (final shot in SceneShot.values) {
          final f = MissionSet.faceRect(size, MissionSet.middle(shot));
          final bottom = MissionSet.faceBottom(size, [shot]);
          expect(bottom, greaterThanOrEqualTo(f.bottom - 0.001));
          // The close-ups leave about half the frame for the lower third.
          if (shot != SceneShot.wide) {
            expect(
              f.bottom / size.height,
              lessThan(_halfFrame),
              reason: '$size $shot',
            );
          }
        }
      }
    });
  });

  group('2. no stray rim-light dot', () {
    RenderObject paintOf(WidgetTester tester) => tester.renderObject(
      find.descendant(
        of: find.byType(InterviewerSilhouette),
        matching: find.byType(CustomPaint),
      ),
    );

    testWidgets(
      'lit from the left, Priya\'s glint (on her right) is not drawn',
      (tester) async {
        await pumpKit(
          tester,
          Center(
            child: SizedBox(
              width: 200,
              child: InterviewerSilhouette(figure: SilhouetteFigure.priya),
            ),
          ),
        );
        expect(paintOf(tester), isNot(paints..circle()));
      },
    );

    testWidgets('lit from her side, the glint catches the light', (
      tester,
    ) async {
      await pumpKit(
        tester,
        Center(
          child: SizedBox(
            width: 200,
            child: InterviewerSilhouette(
              figure: SilhouetteFigure.priya,
              lightFrom: 1,
            ),
          ),
        ),
      );
      expect(paintOf(tester), paints..circle());
    });

    test('the rule, for every figure', () {
      for (final figure in SilhouetteFigure.byId.values) {
        final onRight = figure.glint.dx > figure.neck.dx;
        expect(SilhouettePainter.catchesLight(figure, 1), onRight);
        expect(SilhouettePainter.catchesLight(figure, -1), !onRight);
      }
    });
  });

  group('3. edge to edge', () {
    testWidgets('transparent bars, light icons, edge-to-edge mode', (
      tester,
    ) async {
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
      expect(modes, contains(SystemUiMode.edgeToEdge.toString()));
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, EdgeToEdge.style);
      expect(region.value.statusBarColor!.a, 0);
      expect(region.value.systemNavigationBarColor!.a, 0);
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.systemNavigationBarIconBrightness, Brightness.light);
    });

    testWidgets(
      'the scene draws under the bars; its content stays clear of them',
      (tester) async {
        const insets = EdgeInsets.only(top: 32, bottom: 24);
        final rig = MissionRig(tester);
        await rig.boot(Routes.mission(1), viewPadding: insets);
        await rig.playLines(1);
        await rig.skipDraft();
        await rig.until(find.byType(AnswerCard));
        await rig.run(const Duration(seconds: 1));

        // The set fills the whole screen, bars included: no flat black bands.
        expect(
          tester.getRect(find.byType(DollyCamera)),
          Offset.zero & MissionRig.phone,
        );
        // The meter and the cards keep clear of the status and navigation bars.
        expect(
          tester.getRect(find.byType(TrustMeter)).top,
          greaterThanOrEqualTo(insets.top),
        );
        expect(
          tester.getRect(find.byType(LowerThird)).bottom,
          lessThanOrEqualTo(MissionRig.phone.height - insets.bottom),
        );
      },
    );
  });
}

/// "About half": the tight shot's chin sits at 51.6% of the height on a 360×800 phone.
const double _halfFrame = 0.55;
