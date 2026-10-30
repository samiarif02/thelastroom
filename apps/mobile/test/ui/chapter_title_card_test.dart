import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  testWidgets('fires onTitleLanded, then onFinished, once each', (
    tester,
  ) async {
    final beats = <String>[];
    await pumpKit(
      tester,
      ChapterTitleCard(
        eyebrow: 'CHAPTER ONE',
        title: 'GET THROUGH THE DOOR',
        subtitle: 'in which we meet Priya',
        onTitleLanded: () => beats.add('landed'),
        onFinished: () => beats.add('finished'),
      ),
    );
    await pumpThrough(tester, BrandMotion.titleCard * 1.2);
    expect(beats, ['landed', 'finished']);
    expect(find.text('in which we meet Priya'), findsOneWidget);
  });

  testWidgets('is announced as one header: eyebrow and title', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(
      tester,
      const ChapterTitleCard(
        eyebrow: 'CHAPTER ONE',
        title: 'GET THROUGH\nTHE DOOR',
        play: false,
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('CHAPTER ONE: GET THROUGH THE DOOR'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('reduced motion: settled at once, still finishes', (
    tester,
  ) async {
    var finished = 0;
    await pumpKit(
      tester,
      ChapterTitleCard(
        eyebrow: 'CHAPTER ONE',
        title: 'GET THROUGH THE DOOR',
        onFinished: () => finished++,
      ),
      reduceMotion: true,
    );
    await tester.pump(BrandMotion.reducedMotionFade);
    expect(finished, 1);
    final title = tester.widget<TrackedTitle>(find.byType(TrackedTitle));
    expect(title.t, 1);
  });

  testWidgets('shows its footer once settled', (tester) async {
    await pumpKit(
      tester,
      const ChapterTitleCard(
        eyebrow: 'E',
        title: 'T',
        play: false,
        footer: Text('footer'),
      ),
    );
    await tester.pump();
    expect(find.text('footer'), findsOneWidget);
  });
}
