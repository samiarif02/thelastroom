import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/debrief/debrief_facts.dart';
import 'package:the_last_room/features/debrief/first_try_slip.dart';
import 'package:the_last_room/features/mission/widgets/draft_panel.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../mission/mission_harness.dart';

/// The owner's first-play fix 3: the saved draft shows on the dossier.
void main() {
  const beats = [
    'm01_open_role_fit',
    'm01_evidence_team_did',
    'm01_land_bring_habit',
  ];
  const reply = 'm01_reply_part_led_it';
  const words = 'I like talking to users and checking the numbers.';

  Future<void> finish(MissionRig rig) async {
    final m = rig.state(1).mission;
    AnswerOption byId(String id) => [
      for (final b in m.beats) ...b.options,
      for (final f in m.followUps) ...f.replies,
    ].firstWhere((o) => o.id == id);
    for (final id in beats) {
      await rig.say(byId(id));
    }
    await rig.until(find.text(rig.state(1).followUpLine!.text));
    await rig.run(const Duration(milliseconds: 300));
    if (rig.typing) await rig.tapScene();
    await rig.say(byId(reply));
    await rig.until(find.byType(Dossier));
    await rig.settleDossier();
  }

  testWidgets('the dossier shows "Your first try" beside a stronger version', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await rig.until(find.byType(DraftPanel));
    await tester.enterText(find.byType(EditableText), words);
    await tester.pump();
    final keep = find.text(DraftPanel.keep);
    await tester.ensureVisible(keep);
    await tester.tap(keep);
    await tester.pump();
    await finish(rig);

    final slip = find.byType(FirstTrySlip);
    await tester.ensureVisible(slip);
    expect(find.text('“$words”'), findsOneWidget);
    // The reasoning slip may quote the same line; this checks the first-try slip's.
    expect(
      find.descendant(
        of: slip,
        matching: find.text(
          '“${strongestOpening(missionTheOpportunity).text}”',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(FirstTrySlip.yours), findsOneWidget);
    expect(find.text(FirstTrySlip.strongerHeading), findsOneWidget);
    // The words stay on the device: no event carries them.
    for (final e in rig.analytics.events) {
      expect(e.wire.values.whereType<String>(), isNot(contains(words)));
    }
  });

  testWidgets('a skipped draft shows no first-try slip', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await rig.skipDraft();
    await finish(rig);
    expect(find.byType(FirstTrySlip), findsNothing);
  });

  test('the stronger version is the best-scoring opening line', () {
    final best = strongestOpening(missionTheOpportunity);
    final open = missionTheOpportunity.beats.first.options;
    expect(open, contains(best));
    expect(best.lessonId, isNull, reason: 'a strong line teaches no lesson');
  });
}
