import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'mission_harness.dart';

/// Brief 16 in the mission: the interviewer's face follows the scene, and the question's recap
/// sits on the speech panel, so it stays AA where it falls over her jacket.
void main() {
  InterviewerExpression face(MissionRig rig) => rig.tester
      .widget<FriendlyInterviewer>(find.byType(FriendlyInterviewer))
      .expression;

  testWidgets('she smiles as she asks, thinks while you read, nods when you '
      'lock in, and goes "hmm" on the follow-up', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.until(find.byType(FriendlyInterviewer));
    expect(face(rig), InterviewerExpression.smile);

    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(ChoiceCard));
    expect(face(rig), InterviewerExpression.thinking);

    final mission = rig.state(1).mission;
    final beats = mission.beats;
    final open = beats.first;
    final strongest = open.options.firstWhere((o) => open.isStrongest(o.id));
    await rig.pick(strongest);
    expect(face(rig), InterviewerExpression.nod);

    // "Why that line?": curious.
    final name = rig.state(1).playerName;
    await rig.until(find.text(open.why!.line.addressedTo(name).text));
    expect(face(rig), InterviewerExpression.hmm);

    // A strong line with the right reasoning: she warms.
    await rig.pick(
      open.why!.reasons.firstWhere((r) => r.isSoundFor(strongest.id)),
    );
    await rig.until(find.text(open.reaction!.strong.addressedTo(name).text));
    expect(face(rig), InterviewerExpression.smile);

    for (final beat in beats.skip(1)) {
      await rig.say(beat.options.first);
    }
    await rig.until(find.text(rig.state(1).followUpLine!.text));
    expect(face(rig), InterviewerExpression.hmm);
  });

  testWidgets('the question recap sits on the speech panel', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(QuestionReminder));
    expect(
      find.descendant(
        of: find.byType(QuestionReminder),
        matching: find.byType(SpeechPanel),
      ),
      findsOneWidget,
    );
  });

  test('the recap is AA on the panel over every colour of the cast', () {
    // SpeechPanel: void at 94% (packages/brand/test/contrast_test.dart tests every text).
    const panelAlpha = 0.94;
    for (final cast in [BrandCast.priya, BrandCast.marcus, BrandCast.lena]) {
      for (final under in [cast.outer, cast.inner, cast.skin, cast.hair]) {
        final panel = Color.alphaBlend(
          BrandColors.void_.withValues(alpha: panelAlpha),
          under,
        );
        expect(
          contrastRatio(BrandColors.textSecondary, panel),
          greaterThanOrEqualTo(wcagAaNormalText),
        );
      }
    }
  });
}
