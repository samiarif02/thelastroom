import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

/// DESIGN.md "Known issues": the title's tracking-in broke "THROUGH" mid-word ("THROU / GH").
void main() {
  const title = 'GET THROUGH THE DOOR';
  final words = title.split(' ').toSet();

  group('layoutTitle', () {
    test('breaks only between words, at the final tracking', () {
      final layout = layoutTitle(title, BrandType.titleCard, maxWidth: 260);
      expect(layout.lines.length, greaterThan(1));
      for (final line in layout.lines) {
        expect(words, containsAll(line.split(' ')));
      }
      expect(layout.lines.join(' '), title);
    });

    test('honours a forced break', () {
      final layout = layoutTitle(
        'GET THROUGH\nTHE DOOR',
        BrandType.titleCard,
        maxWidth: 2000,
      );
      expect(layout.lines, ['GET THROUGH', 'THE DOOR']);
    });

    test('shrinks the whole title when one word cannot fit', () {
      final layout = layoutTitle('THROUGH', BrandType.titleCard, maxWidth: 80);
      expect(layout.lines, ['THROUGH']);
      expect(layout.style.fontSize, lessThan(BrandType.titleCard.fontSize!));
    });
  });

  for (final scale in [1.0, 2.0]) {
    for (final width in [320.0, 375.0, 412.0]) {
      testWidgets(
        'no word ever breaks while it tracks in ($width wide, ${scale}x text)',
        (tester) async {
          await pumpKit(
            tester,
            const ChapterTitleCard(eyebrow: 'CHAPTER ONE', title: title),
            size: Size(width, 700),
            textScale: scale,
          );
          final seen = <List<String>>{};
          await pumpThrough(
            tester,
            BrandMotion.titleCard + const Duration(milliseconds: 200),
            step: const Duration(milliseconds: 50),
            eachFrame: () {
              final lines = tester
                  .widgetList<Text>(
                    find.descendant(
                      of: find.byType(TrackedTitle),
                      matching: find.byType(Text),
                    ),
                  )
                  .toList();
              for (final line in lines) {
                expect(line.maxLines, 1);
                expect(line.softWrap, isFalse);
                expect(words, containsAll(line.data!.split(' ')));
              }
              seen.add(lines.map((l) => l.data!).toList());
            },
          );
          // The lines never change during the animation: only the tracking does.
          expect(seen.map((l) => l.join('|')).toSet(), hasLength(1));
        },
      );
    }
  }

  testWidgets('settled, every line fits inside the frame', (tester) async {
    await pumpKit(
      tester,
      const ChapterTitleCard(eyebrow: 'CHAPTER ONE', title: title, play: false),
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pump();
    final frame = tester.getRect(find.byType(TrackedTitle));
    for (final element
        in find
            .descendant(
              of: find.byType(TrackedTitle),
              matching: find.byType(Text),
            )
            .evaluate()) {
      // The box includes the tracking after the last letter, which holds no ink.
      final text = element.widget as Text;
      final trailing = text.style!.letterSpacing!;
      final rect = tester.getRect(find.byWidget(text));
      expect(rect.left, greaterThanOrEqualTo(frame.left - 0.5));
      expect(rect.right - trailing, lessThanOrEqualTo(frame.right + 0.5));
    }
  });
}
