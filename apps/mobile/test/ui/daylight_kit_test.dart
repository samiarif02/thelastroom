import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';

import 'harness.dart';

/// The Daylight kit's behaviour: presses, disabled and locked states, what screen readers hear,
/// reduced motion, and large text. How each state looks is in the catalog goldens.
void main() {
  Widget column(List<Widget> children) => SingleChildScrollView(
    padding: const EdgeInsets.all(DaylightSpace.s16),
    child: Column(children: children),
  );

  group('TactileButton', () {
    testWidgets('presses, and is a labelled 48+ button', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await pumpKit(
        tester,
        column([TactileButton(label: 'Start room 4', onPressed: () => taps++)]),
      );
      await tester.tap(find.text('Start room 4'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(Tactile)),
        matchesSemantics(
          label: 'Start room 4',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSize(find.byType(Tactile)).height,
        greaterThanOrEqualTo(DaylightSize.button),
      );
      handle.dispose();
    });

    testWidgets('disabled: no tap, sand face', (tester) async {
      await pumpKit(
        tester,
        column([const TactileButton(label: 'Lock in line B', onPressed: null)]),
      );
      await tester.tap(find.text('Lock in line B'), warnIfMissed: false);
      final face = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Tactile),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        face.map((d) => (d.decoration as BoxDecoration).color),
        contains(DaylightColors.sand),
      );
    });

    testWidgets('the face sinks onto its edge while held', (tester) async {
      await pumpKit(
        tester,
        column([TactileButton(label: 'Go', onPressed: () {})]),
      );
      final before = tester.getTopLeft(find.text('Go')).dy;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      // A tap-down lands after the press timeout, then the face takes its time to sink.
      await tester.pump(DaylightMotion.press);
      await tester.pump(DaylightMotion.press);
      expect(
        tester.getTopLeft(find.text('Go')).dy,
        closeTo(before + DaylightSize.edge, 0.01),
      );
      await gesture.up();
      await tester.pump();
      await tester.pump(DaylightMotion.press);
      expect(tester.getTopLeft(find.text('Go')).dy, closeTo(before, 0.01));
    });

    testWidgets('under reduced motion it doesn\'t move', (tester) async {
      await pumpKit(
        tester,
        column([TactileButton(label: 'Go', onPressed: () {})]),
        reduceMotion: true,
      );
      final before = tester.getTopLeft(find.text('Go')).dy;
      await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump(DaylightMotion.press);
      expect(tester.getTopLeft(find.text('Go')).dy, before);
    });
  });

  group('PickCard', () {
    testWidgets('locked can\'t be tapped; dimmed fades', (tester) async {
      var taps = 0;
      await pumpKit(
        tester,
        column([
          PickCard(
            letter: 'B',
            text: 'Locked',
            state: PickState.locked,
            onTap: () => taps++,
          ),
          PickCard(
            letter: 'C',
            text: 'Dimmed',
            state: PickState.dimmed,
            onTap: () => taps++,
          ),
        ]),
      );
      await tester.pump(DaylightMotion.colour);
      await tester.tap(find.text('Locked'), warnIfMissed: false);
      expect(taps, 0);
      await tester.tap(find.text('Dimmed'));
      expect(taps, 1);
      final dimmed = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Dimmed'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(dimmed.opacity, lessThan(1));
    });

    testWidgets('a selected card is a selected button with its line', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpKit(
        tester,
        column([
          PickCard(
            letter: 'B',
            text: 'I tagged 600 tickets.',
            state: PickState.selected,
            onTap: () {},
          ),
        ]),
      );
      expect(
        find.bySemanticsLabel('Line B: I tagged 600 tickets.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('survives doubled text', (tester) async {
      await pumpKit(
        tester,
        column([
          for (final s in PickState.values)
            PickCard(
              letter: 'A',
              text: 'We went through a month of tickets and cut resets.',
              state: s,
              onTap: () {},
            ),
        ]),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('progress', () {
    testWidgets('beats and trust are announced, not drawn', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKit(
        tester,
        column([
          const BeatProgress(beats: ['Open', 'Evidence', 'Land'], current: 1),
          const TrustPips(trust: 3, icon: PhosphorFill.handshake),
        ]),
      );
      expect(find.bySemanticsLabel('Beat 2 of 3: Evidence'), findsOneWidget);
      expect(find.bySemanticsLabel('Trust, 3 of 5'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the score counts up, and is simply there under reduced '
        'motion', (tester) async {
      await pumpKit(tester, column([const ScoreDial(score: 78)]));
      await tester.pump(DaylightMotion.countUp ~/ 4);
      expect(find.text('78'), findsNothing);
      await tester.pump(DaylightMotion.countUp);
      expect(find.text('78'), findsOneWidget);

      await pumpKit(
        tester,
        column([const ScoreDial(score: 41, key: ValueKey('still'))]),
        reduceMotion: true,
      );
      expect(find.text('41'), findsOneWidget);
    });

    testWidgets('a closed week rings in honey', (tester) async {
      await pumpKit(tester, column([const WeeklyRing(done: 3)]));
      await tester.pump(DaylightMotion.ringClose);
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WeeklyRing),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as RingPainter).fill, DaylightColors.honey);
      expect(find.text('3/3'), findsOneWidget);
    });
  });

  group('structure', () {
    test('entrances are 60 ms apart, capped at 400', () {
      expect(Entrance.delayOf(0), Duration.zero);
      expect(Entrance.delayOf(2), const Duration(milliseconds: 120));
      expect(Entrance.delayOf(20), DaylightMotion.staggerCap);
    });

    testWidgets('ChapterTint sets the floor below it; floor 1 by default', (
      tester,
    ) async {
      late FloorColours outside;
      late FloorColours inside;
      await pumpKit(
        tester,
        Column(
          children: [
            Builder(
              builder: (c) {
                outside = ChapterTint.floorOf(c);
                return const SizedBox();
              },
            ),
            ChapterTint.of(
              ChapterGrade.pressure,
              child: Builder(
                builder: (c) {
                  inside = ChapterTint.floorOf(c);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );
      expect(outside, DaylightFloors.one);
      expect(inside, DaylightFloors.two);
    });

    testWidgets('the tab bar selects, and says what is waiting', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var picked = -1;
      await pumpKit(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: FloatingTabBar(
            current: 0,
            onSelect: (i) => picked = i,
            items: const [
              TabItem(icon: PhosphorBold.buildings, label: 'Tower'),
              TabItem(icon: PhosphorBold.cards, label: 'Recall', badge: 2),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Recall'));
      expect(picked, 1);
      expect(find.bySemanticsLabel('Recall, 2 waiting'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the feedback sheet rises, and fades in under reduced '
        'motion', (tester) async {
      Widget sheet() => Align(
        alignment: Alignment.bottomCenter,
        child: FeedbackSheet(
          person: CastPeople.marcus,
          tone: FeedbackTone.sound,
          title: "That's the principle.",
          xp: 10,
          actionLabel: 'Next: land the answer',
          onAction: () {},
        ),
      );
      await pumpKit(tester, sheet());
      expect(find.byType(SlideTransition), findsWidgets);
      await pumpThrough(tester, DaylightMotion.move * 2);
      expect(find.text('+10 XP'), findsOneWidget);

      await pumpKit(tester, sheet(), reduceMotion: true);
      await pumpThrough(tester, DaylightMotion.move);
      expect(find.text("That's the principle."), findsOneWidget);
    });
  });
}
