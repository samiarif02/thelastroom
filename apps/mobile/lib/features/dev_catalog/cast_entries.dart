import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'catalog_entry.dart';
import 'daylight_backdrop.dart';

/// The Daylight cast in the catalog (`/dev/catalog/cast`): the sheet (four people, seven
/// expressions), each expression large, and the arches they're framed in.
abstract final class CastEntries {
  static final CatalogEntry cast = CatalogEntry(
    id: 'cast',
    name: 'The cast',
    note:
        'CastFigure (direction.md, "Characters"): Priya, Marcus, Lena and Sam drawn from '
        'packages/brand\'s cast data, seven expressions, idle = blink, breath, sway. '
        'Reduced motion stills it; expression changes blend over 300 ms.',
    shots: [
      CatalogShot(id: 'sheet', label: 'Sheet', build: (_) => const _Sheet()),
      for (final e in CastExpression.values)
        CatalogShot(
          id: e.name,
          label: _title(e.name),
          build: (_) => _Expression(expression: e),
        ),
      CatalogShot(id: 'arches', label: 'Arches', build: (_) => const _Arches()),
    ],
  );

  static String _title(String s) => s[0].toUpperCase() + s.substring(1);
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  /// From this width the sheet is laid out like the mockup: a row per person.
  static const double _wide = 720;
  static const double _labelColumn = 64;
  static const double _nameColumn = 120;

  Widget _label(String text, {TextAlign align = TextAlign.center}) => Text(
    text,
    textAlign: align,
    style: DaylightType.caption3.copyWith(color: DaylightColors.ink2),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= _wide;
      final rows = wide ? CastPeople.all : CastExpression.values;
      final columns = wide ? CastExpression.values : CastPeople.all;
      Widget cell(Object row, Object column) {
        final (p, e) = wide
            ? (row as CastPerson, column as CastExpression)
            : (column as CastPerson, row as CastExpression);
        return _Tile(person: p, expression: e, idle: false);
      }

      String nameOf(Object o) => switch (o) {
        CastPerson(:final name) => name,
        CastExpression(:final name) => CastEntries._title(name),
        _ => '',
      };

      final lead = wide ? _nameColumn : _labelColumn;
      return CatalogPaper(
        gap: DaylightSpace.s8,
        children: [
          Text('The cast, seven states', style: DaylightType.heading5),
          Text(
            'Neutral, listening, thinking, nod, smile, hmm, talking. Plain shapes on one '
            '200 grid, drawn by CastPainter from packages/brand.',
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
          Row(
            children: [
              SizedBox(width: lead),
              for (final (i, c) in columns.indexed) ...[
                if (i > 0) const SizedBox(width: DaylightSpace.s8),
                Expanded(child: _label(nameOf(c))),
              ],
            ],
          ),
          for (final r in rows)
            Row(
              children: [
                SizedBox(
                  width: lead,
                  child: wide && r is CastPerson
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: DaylightType.title2),
                            Text(
                              r.role,
                              style: DaylightType.caption4.copyWith(
                                color: DaylightColors.ink2,
                              ),
                            ),
                          ],
                        )
                      : _label(nameOf(r), align: TextAlign.start),
                ),
                for (final (i, c) in columns.indexed) ...[
                  if (i > 0) const SizedBox(width: DaylightSpace.s8),
                  Expanded(child: cell(r, c)),
                ],
              ],
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.person,
    required this.expression,
    this.idle = true,
    this.radius = DaylightRadius.inner,
  });

  final CastPerson person;
  final CastExpression expression;
  final bool idle;
  final double radius;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: DaylightColors.sand,
        child: CastFigure(
          person: person,
          expression: expression,
          idle: idle,
          semanticLabel: '${person.name}, ${expression.name}',
        ),
      ),
    ),
  );
}

class _Expression extends StatelessWidget {
  const _Expression({required this.expression});

  final CastExpression expression;

  @override
  Widget build(BuildContext context) => CatalogPaper(
    children: [
      Text(CastEntries._title(expression.name), style: DaylightType.heading5),
      for (final pair in [
        CastPeople.all.sublist(0, 2),
        CastPeople.all.sublist(2),
      ])
        Row(
          children: [
            for (final (i, p) in pair.indexed) ...[
              if (i > 0) const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tile(
                      person: p,
                      expression: expression,
                      radius: DaylightRadius.card,
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Text(p.name, style: DaylightType.body4),
                  ],
                ),
              ),
            ],
          ],
        ),
    ],
  );
}

class _Arches extends StatelessWidget {
  const _Arches();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    children: [
      const CatalogLabel('Welcome back · the why step · the debrief'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ArchPortrait(
            person: CastPeople.priya,
            expression: CastExpression.smile,
            width: 56,
            height: 64,
            ground: DaylightColors.recallSoft,
          ),
          const SizedBox(width: DaylightSpace.s16),
          ArchPortrait(
            person: CastPeople.marcus,
            expression: CastExpression.thinking,
            ground: DaylightFloors.one.soft,
          ),
          const SizedBox(width: DaylightSpace.s16),
          ArchPortrait(
            person: CastPeople.lena,
            expression: CastExpression.hmm,
            width: 88,
            height: 104,
            ground: DaylightFloors.two.soft,
          ),
        ],
      ),
      const CatalogLabel('The up-next window · the top floor'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ArchPortrait(
            person: CastPeople.marcus,
            width: 120,
            height: 148,
            border: DaylightSpace.s4,
            sill: DaylightFloors.one.deep,
          ),
          const SizedBox(width: DaylightSpace.s16),
          ArchPortrait(
            person: CastPeople.sam,
            expression: CastExpression.listening,
            ground: DaylightFloors.three.soft,
          ),
        ],
      ),
      const CatalogLabel('The floor cleared: lit, all smiling'),
      ColoredBox(
        color: DaylightFloors.one.base,
        child: Padding(
          padding: const EdgeInsets.all(DaylightSpace.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final p in [
                CastPeople.priya,
                CastPeople.marcus,
                CastPeople.lena,
              ])
                ArchPortrait(
                  person: p,
                  expression: CastExpression.smile,
                  width: 80,
                  height: 96,
                  ground: DaylightColors.honey,
                  border: DaylightSpace.s4,
                  borderColor: DaylightColors.deskTop,
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
