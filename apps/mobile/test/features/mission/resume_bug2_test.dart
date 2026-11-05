import 'dart:convert';

import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/debrief/reasoning_slip.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/scene/room_intro.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/tips/tip_overlay.dart';
import 'package:the_last_room/features/tips/tips.dart';
import 'package:the_last_room/ui/daylight/trust_pips.dart';

import 'mission_harness.dart';

/// QA 51, BUG-2, both hypotheses (brief 56): room 5, resumed from a save an older build wrote,
/// re-showed the open beat's cards; after line C was locked the why step seemed skipped, and
/// the debrief credited "Labelling each STAR step…", which the tester says they never picked.
void main() {
  final m5 = missions.firstWhere((m) => m.number == 5);
  final open = m5.beats[0];
  final evidence = m5.beats[1];
  final land = m5.beats[2];
  AnswerOption strongest(Beat beat) =>
      beat.options.firstWhere((o) => beat.isStrongest(o.id));
  Reason soundFor(Beat beat, AnswerOption o) =>
      beat.why!.reasons.firstWhere((r) => r.isSoundFor(o.id));
  final labels = open.why!.reasons.firstWhere(
    (r) => r.id == 'm05_open_why_labels',
  );

  /// The QA phone (realme RMX3085: 1080 × 2400 px at 2.625).
  const realme = Size(411, 914);

  int pips(WidgetTester tester) =>
      tester.widget<TrustPips>(find.byType(TrustPips)).trust;

  /// The resume store's value as every build since the store arrived (cc3e8c0) has written it:
  /// `LocalResumeStore` keeps exactly this JSON under `mission_resume.<id>`. The format has
  /// never changed, so an "older build's" save differs only in where the player left.
  String storedJson(List<Map<String, Object?>> plays) => jsonEncode({
    'mission_id': m5.id,
    'seed': testSeed,
    'attempt_number': 1,
    'draft': null,
    // Room 5 is hinted, so it offers no draft: an older build never set this.
    'draft_done': false,
    'plays': plays,
  });

  Map<String, Object?> play(AnswerOption o, {Reason? reason, int? ms}) => {
    'option_id': o.id,
    'decided_ms': ms,
    'reason_id': reason?.id,
  };

  Future<MissionRig> resumeFrom(
    WidgetTester tester,
    String json, {
    Set<Tip> unseen = const {},
    Size size = MissionRig.phone,
  }) async {
    final rig = MissionRig(tester);
    rig.tips.flags.removeAll(unseen);
    await rig.unlockThrough(5);
    final saved = SavedAttempt.fromJson(jsonDecode(json));
    expect(saved, isNotNull, reason: 'the stored shape still parses');
    await rig.resume.save(saved!);
    await rig.boot(Routes.mission(5), size: size);
    await rig.until(find.text(RoomIntro.resume));
    await tester.tap(find.text(RoomIntro.resume));
    await tester.pump();
    return rig;
  }

  /// The rest of the room from wherever the scene is, with the strongest lines and sound
  /// reasons, to the dossier's reasoning slip.
  Future<void> finish(MissionRig rig, List<Beat> beats) async {
    for (final beat in beats) {
      await rig.until(
        find.text(beatLabel(beat.kind, m5.beats.indexOf(beat), 3)),
      );
      await rig.say(strongest(beat));
    }
    await rig.until(find.text(rig.state(5).followUpLine!.text));
    await rig.run(const Duration(milliseconds: 300));
    if (rig.typing) await rig.tapScene();
    await rig.say(rig.state(5).replyOptions.first);
    await rig.until(find.byType(ReasoningSlip));
  }

  group('(a) a save from an older build', () {
    testWidgets(
      'left at the open cards (the phone: 3 pips): the why step comes '
      'after the lock, and only the reason given is credited',
      (tester) async {
        final rig = await resumeFrom(tester, storedJson(const []));
        expect(rig.state(5).plays, isEmpty);
        await rig.until(find.text(beatLabel(open.kind, 0, 3)));
        expect(pips(tester), 3, reason: 'trust 50, as on the phone (qa-04)');

        await rig.pick(strongest(open));
        await rig.until(find.text(reasonLabel));
        expect(
          rig.state(5).awaitingWhy,
          isTrue,
          reason: 'the why step is asked',
        );
        await rig.pick(soundFor(open, strongest(open)));
        expect(
          rig.state(5).plays.single.reason,
          soundFor(open, strongest(open)),
        );
        await finish(rig, [evidence, land]);
        expect(rig.state(5).plays.map((p) => p.reason), [
          for (final b in m5.beats) soundFor(b, strongest(b)),
        ]);
        expect(find.textContaining(labels.text), findsNothing);
        await rig.run(const Duration(seconds: 2));
      },
    );

    testWidgets('left on the open why step: it resumes there and asks it', (
      tester,
    ) async {
      final rig = await resumeFrom(
        tester,
        storedJson([play(strongest(open), ms: 4200)]),
      );
      await rig.until(find.text(reasonLabel));
      expect(rig.state(5).awaitingWhy, isTrue);
      await rig.pick(soundFor(open, strongest(open)));
      await finish(rig, [evidence, land]);
      expect(rig.state(5).plays.first.reason, soundFor(open, strongest(open)));
      await rig.run(const Duration(seconds: 2));
    });

    testWidgets('left after the open reason: the evidence cards, the open '
        'reason kept as given', (tester) async {
      final rig = await resumeFrom(
        tester,
        storedJson([play(strongest(open), reason: labels, ms: 4200)]),
      );
      await rig.until(find.text(beatLabel(evidence.kind, 1, 3)));
      expect(pips(tester), 2, reason: 'trust 48: strongest line, unsound why');
      await finish(rig, [evidence, land]);
      expect(rig.state(5).plays.first.reason, labels);
      await rig.run(const Duration(seconds: 2));
    });

    testWidgets('an old save with no timings (decided_ms null) still resumes', (
      tester,
    ) async {
      final rig = await resumeFrom(
        tester,
        storedJson([
          play(strongest(open), reason: soundFor(open, strongest(open))),
          play(strongest(evidence)),
        ]),
      );
      await rig.until(find.text(reasonLabel));
      expect(rig.state(5).plays, hasLength(2));
      expect(rig.state(5).awaitingWhy, isTrue);
      await rig.pick(soundFor(evidence, strongest(evidence)));
      await finish(rig, [land]);
      await rig.run(const Duration(seconds: 2));
    });
  });

  group('(b) the first why_step tip', () {
    /// A tap where the reason card shows through the tip's cut-out, clear of the bubble.
    Offset throughTheSpotlight(WidgetTester tester, Reason reason) {
      final hole = tester.widget<TipOverlay>(find.byType(TipOverlay)).hole;
      final card = tester
          .getRect(find.widgetWithText(ChoiceCard, reason.text))
          .intersect(hole);
      final bubble = tester.getRect(
        find.ancestor(
          of: find.byType(TipBubble),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      final top = bubble.bottom > card.top && bubble.top < card.top
          ? bubble.bottom
          : card.top;
      expect(card.height, greaterThan(0), reason: 'the card shows through');
      return Offset(card.center.dx, (top + card.bottom) / 2);
    }

    testWidgets('the phone\'s run: one tap meant for the tip never gives a '
        'reason; the player then picks deliberately', (tester) async {
      // Room 5 resumed at the open cards, as on the phone; the tips were new to that build.
      final rig = await resumeFrom(
        tester,
        storedJson(const []),
        unseen: {Tip.whyStep},
        size: realme,
      );
      await rig.until(find.text(beatLabel(open.kind, 0, 3)));
      await rig.pick(strongest(open));
      await rig.until(find.byType(TipOverlay));
      expect(find.text(Tip.whyStep.line), findsOneWidget);
      await rig.run(const Duration(milliseconds: 600));

      // The tap lands on "Labelling each STAR step…" inside the spotlight.
      await tester.tapAt(throughTheSpotlight(tester, labels));
      await tester.pump();
      await rig.run(const Duration(seconds: 2));

      expect(find.byType(TipOverlay), findsNothing, reason: 'the tip is gone');
      expect(rig.tips.flags, contains(Tip.whyStep));
      expect(
        rig.state(5).plays.single.reason,
        isNull,
        reason: 'the tap only put the tip away: no reason was given',
      );
      expect(rig.state(5).awaitingWhy, isTrue);
      expect(find.text(reasonLabel), findsOneWidget);
      expect(pips(tester), 3, reason: 'trust unmoved (the phone fell to 2)');

      // Now the player reads the reasons and gives one on purpose.
      final sound = soundFor(open, strongest(open));
      await rig.pick(sound);
      expect(rig.state(5).plays.single.reason, sound);
      await finish(rig, [evidence, land]);
      expect(find.textContaining(labels.text), findsNothing);
      await rig.run(const Duration(seconds: 2));
    });
  });
}
