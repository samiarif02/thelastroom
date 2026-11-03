import 'package:brand/brand.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';
import 'package:the_last_room/ui/subtitle/typewriter_text.dart';

import 'mission_harness.dart';

/// The interviewer's face follows the scene (brief 16; Daylight's cast, brief 46): a smile on
/// the title card, talking as the line types, listening while you choose, a nod when you lock
/// in, thinking on "why?", warm after a strong answer. The question stays in the bubble above
/// the cards.
void main() {
  /// The face in the room (the feedback sheet's small arch comes after it in the tree).
  CastExpression face(MissionRig rig) =>
      rig.tester.widget<CastFigure>(find.byType(CastFigure).first).expression;

  testWidgets('she smiles on the card, listens while you read, nods when you '
      'lock in, thinks on "why?", warms to a strong answer', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.until(find.byType(CastFigure));
    expect(face(rig), CastExpression.smile);

    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(ChoiceCard));
    expect(face(rig), CastExpression.listening);

    final mission = rig.state(1).mission;
    final beats = mission.beats;
    final open = beats.first;
    final strongest = open.options.firstWhere((o) => open.isStrongest(o.id));
    await rig.pick(strongest);
    expect(face(rig), CastExpression.nod);

    // "Why that line?": she thinks it over.
    final name = rig.state(1).playerName;
    await rig.until(find.text(open.why!.line.addressedTo(name).text));
    expect(face(rig), CastExpression.thinking);

    // A strong line with the right reasoning: she warms.
    await rig.pick(
      open.why!.reasons.firstWhere((r) => r.isSoundFor(strongest.id)),
    );
    await rig.until(find.text(open.reaction!.strong.addressedTo(name).text));
    expect(face(rig), CastExpression.smile);

    for (final beat in beats.skip(1)) {
      await rig.say(beat.options.first);
    }
    await rig.until(find.text(rig.state(1).followUpLine!.text));
    expect(face(rig), CastExpression.talk);
  });

  testWidgets('the question stays in the bubble above the cards', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(ChoiceCard));
    final bubble = tester.widget<TypewriterText>(find.byType(TypewriterText));
    expect(bubble.text, rig.state(1).question.text);
    expect(bubble.characters, bubble.text.length);
    expect(
      tester.getRect(find.byType(TypewriterText)).bottom,
      lessThan(tester.getRect(find.byType(ChoiceCard).first).top),
    );
  });

  test('the bubble is AA on every floor: ink and the speaker on white', () {
    for (final f in DaylightFloors.all) {
      expect(
        contrastRatio(f.deep, DaylightColors.raised),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
    }
    expect(
      contrastRatio(DaylightColors.ink, DaylightColors.raised),
      greaterThanOrEqualTo(wcagAaNormalText),
    );
  });
}
