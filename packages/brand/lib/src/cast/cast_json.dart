import 'dart:convert';
import 'dart:ui' show Color;

import 'cast_features.dart';
import 'cast_people.dart';
import 'cast_shape.dart';

/// The cast as data, for every renderer that isn't this package (the web's React portraits):
/// `assets/cast/cast.json`. Generated from the Dart geometry by `tool/export_cast.dart`, and
/// `test/cast_json_test.dart` fails if the committed file drifts, so the app and the site can
/// never draw different people.
abstract final class CastJson {
  /// Where the export lives, relative to the package.
  static const String path = 'assets/cast/cast.json';

  /// The file's text: two-space JSON, a trailing newline.
  static String encode() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';

  static Map<String, Object?> toJson() => {
    'about':
        'The Last Room cast (docs/design/direction.md, "Characters"). Generated from '
        'packages/brand/lib/src/cast by tool/export_cast.dart; do not edit by hand. Every '
        'shape is on a 200 x 200 grid. Draw the layers in order; "head:" layers sit in a '
        'group transformed by "translate(0 dy) rotate(rotation pivotX pivotY)" with the '
        "expression's rotation and dy. A shape's fill or stroke names a colour role: look it "
        "up in the person's colours, then in shared.",
    'grid': CastBody.grid,
    'pivot': [CastFeatures.pivot.dx, CastFeatures.pivot.dy],
    'layers': const [
      'head:back',
      'neck',
      'torso',
      'clothes',
      'head:ears',
      'head:head',
      'head:shading',
      'head:cheeks',
      'head:creases',
      'head:eyes',
      'head:brows',
      'head:nose',
      'head:mouth',
      'head:front',
      'head:rim',
    ],
    'shared': _colours(CastShared.all),
    'body': {
      'head': _shape(CastBody.head),
      'neck': _shapes(CastBody.neck),
      'torso': _shape(CastBody.torso),
      'ears': _shapes(CastBody.ears),
      'shading': _shape(CastBody.shading),
      'nose': _shapes(CastBody.nose),
      'rim': _shape(CastBody.rim),
      'cheeks': _shapes(CastFeatures.cheeks(1)),
    },
    'eyes': {
      for (final e in CastEyes.values)
        e.name: {
          'left': _shapes(CastFeatures.eye(e, CastFeatures.eyeLeftX)),
          'right': _shapes(CastFeatures.eye(e, CastFeatures.eyeRightX)),
        },
    },
    'brows': {
      for (final b in CastBrow.named.entries)
        b.key: {
          'left': _shape(CastFeatures.brow(b.value, -1)),
          'right': _shape(CastFeatures.brow(b.value, 1)),
        },
    },
    'creases': {
      for (final (name, lift) in const [
        ('rest', 0.0),
        ('lifted', CastFeatures.creaseLift),
      ])
        name: {
          'left': _shape(CastFeatures.crease(CastFeatures.eyeLeftX, lift)),
          'right': _shape(CastFeatures.crease(CastFeatures.eyeRightX, lift)),
        },
    },
    'mouths': {
      for (final m in CastMouth.values) m.name: _shapes(CastFeatures.mouth(m)),
    },
    'expressions': {
      for (final x in CastExpression.values)
        x.name: {
          'eyes': x.pose.eyes.name,
          'brows': [_browName(x.pose.browLeft), _browName(x.pose.browRight)],
          'mouth': x.pose.mouth.name,
          'creases': x.pose.creaseLift > 0 ? 'lifted' : 'rest',
          'rotation': x.pose.rotation,
          'dy': x.pose.dy,
          'blush': x.pose.blush,
        },
    },
    'people': {
      for (final p in CastPeople.all)
        p.id: {
          'name': p.name,
          'role': p.role,
          'colours': _colours(p.palette.roles),
          'back': _shapes(p.back),
          'clothes': _shapes(p.clothes),
          'front': _shapes(p.front),
        },
    },
  };

  static String _browName(CastBrow b) =>
      CastBrow.named.entries.firstWhere((e) => e.value == b).key;

  static Map<String, String> _colours(Map<CastInk, Color> colours) => {
    for (final e in colours.entries) e.key.name: hex(e.value),
  };

  /// `#RRGGBB`.
  static String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static List<Map<String, Object?>> _shapes(List<CastShape> shapes) => [
    for (final s in shapes) _shape(s),
  ];

  static Map<String, Object?> _shape(CastShape s) => {
    'type': s.kind,
    ...switch (s) {
      CastPath(:final d) => {'d': d},
      CastEllipse(:final cx, :final cy, :final rx, :final ry) => {
        'cx': cx,
        'cy': cy,
        'rx': rx,
        'ry': ry,
      },
      CastCircle(:final cx, :final cy, :final r) => {
        'cx': cx,
        'cy': cy,
        'r': r,
      },
      CastRect() => {
        'x': s.x,
        'y': s.y,
        'width': s.width,
        'height': s.height,
        if (s.radius > 0) 'rx': s.radius,
        if (s.rotation != 0) 'rotate': [s.rotation, s.pivotX, s.pivotY],
      },
    },
    if (s.fill != null) 'fill': s.fill!.name,
    if (s.fillOpacity != 1) 'fillOpacity': s.fillOpacity,
    if (s.stroke != null) ...{
      'stroke': s.stroke!.name,
      'strokeWidth': s.strokeWidth,
      'cap': s.roundCap ? 'round' : 'butt',
    },
    if (s.opacity != 1) 'opacity': s.opacity,
  };
}
