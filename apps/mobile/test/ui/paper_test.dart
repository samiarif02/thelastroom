import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  const scores = [
    DossierScore(label: 'Relevance', value: 78),
    DossierScore(label: 'Specificity', value: 52),
    DossierScore(label: 'Structure', value: 70),
    DossierScore(label: 'Adaptability', value: 64),
  ];

  Widget onDesk(Widget dossier) => SingleChildScrollView(
    padding: const EdgeInsets.all(BrandSpace.lg),
    child: dossier,
  );

  Dossier dossier({
    bool play = true,
    ValueChanged<int>? onStamp,
    VoidCallback? onSeal,
    VoidCallback? onPen,
    VoidCallback? onFinished,
  }) => Dossier(
    title: 'Candidate assessment',
    subtitle: 'The Opportunity · with Priya',
    scores: scores,
    total: 66,
    note: 'Who is “we”? Say what you did.',
    markedIndex: 1,
    play: play,
    onStamp: onStamp,
    onSeal: onSeal,
    onPen: onPen,
    onFinished: onFinished,
  );

  testWidgets('beats: four stamps in order, the seal, the pen, then done', (
    tester,
  ) async {
    final beats = <String>[];
    await pumpKit(
      tester,
      onDesk(
        dossier(
          onStamp: (i) => beats.add('stamp $i'),
          onSeal: () => beats.add('seal'),
          onPen: () => beats.add('pen'),
          onFinished: () => beats.add('done'),
        ),
      ),
    );
    await pumpThrough(tester, BrandMotion.dossier * 1.1);
    expect(beats, [
      'stamp 0',
      'stamp 1',
      'stamp 2',
      'stamp 3',
      'seal',
      'pen',
      'done',
    ]);
    for (final s in scores) {
      expect(find.text(s.label), findsOneWidget);
    }
    expect(find.byType(WaxSeal), findsOneWidget);
    expect(find.byType(PenNote), findsOneWidget);
  });

  testWidgets('stamps are spread evenly whatever the number of scores', (
    tester,
  ) async {
    final at = [for (var i = 0; i < 4; i++) Dossier.stampAt(i, 4)];
    for (var i = 1; i < at.length; i++) {
      expect(at[i], greaterThan(at[i - 1]));
    }
    expect(Dossier.stampAt(5, 6), lessThan(0.64));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('fits a 375×667 desk at ${scale}x text, all the way through', (
      tester,
    ) async {
      await pumpKit(tester, onDesk(dossier()), textScale: scale);
      await pumpThrough(tester, BrandMotion.dossier * 1.1);
    });
  }

  testWidgets('reduced motion: already on the desk, no beats, still done', (
    tester,
  ) async {
    final beats = <String>[];
    await pumpKit(
      tester,
      onDesk(
        dossier(
          onStamp: (i) => beats.add('stamp $i'),
          onSeal: () => beats.add('seal'),
          onFinished: () => beats.add('done'),
        ),
      ),
      reduceMotion: true,
    );
    await tester.pump(BrandMotion.reducedMotionFade);
    expect(beats, ['done']);
  });

  testWidgets('screen readers hear each score and the total', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, onDesk(dossier(play: false)));
    await tester.pump();
    expect(find.bySemanticsLabel('Specificity: 52 out of 100'), findsOneWidget);
    expect(find.bySemanticsLabel('OVERALL 66'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Who is “we”? Say what you did.'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the seal keeps its size at 2x text', (tester) async {
    await pumpKit(
      tester,
      const Center(child: WaxSeal(value: 100)),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(WaxSeal)), const Size.square(84));
  });

  test('a stamp hits at 72% of its drop', () {
    expect(StampIn.hitAt, 0.72);
  });

  testWidgets('the pen note writes itself left to right', (tester) async {
    for (final t in [0.0, 0.5, 1.0]) {
      await pumpKit(
        tester,
        Center(
          child: PenNote(text: 'Say what you did.', t: t),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('a pen ring closes past where it started', () {
    final ring = PenStroke.ring(const Rect.fromLTWH(0, 0, 40, 20));
    final bounds = ring.getBounds();
    expect(bounds.width, greaterThan(40));
  });
}
