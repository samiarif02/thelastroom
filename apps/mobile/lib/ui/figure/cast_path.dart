import 'dart:ui' show Offset, Path, lerpDouble;

import 'package:flutter/foundation.dart';

/// One command of a cast path: `M`, `L`, `Q`, `C` or `Z`, with its absolute points.
@immutable
class CastCommand {
  const CastCommand(this.op, this.points);

  final String op;
  final List<Offset> points;
}

/// An SVG path string from the cast (`packages/brand` `CastPath.d`) parsed once into commands,
/// so it can be drawn every frame and blended into another path of the same shape. The cast
/// only uses absolute `M L Q C Z`, which is all this reads.
@immutable
class CastPathData {
  const CastPathData(this.commands);

  final List<CastCommand> commands;

  static final Map<String, CastPathData> _parsed = {};
  static final Map<String, Path> _paths = {};

  /// [d] parsed (cached: the cast reuses a few dozen strings).
  static CastPathData parse(String d) => _parsed[d] ??= _parse(d);

  /// [d] as a [Path] (cached; a [Path] is immutable once drawn, so it's shared).
  static Path pathOf(String d) => _paths[d] ??= parse(d).toPath();

  static const Map<String, int> _arity = {
    'M': 1,
    'L': 1,
    'Q': 2,
    'C': 3,
    'Z': 0,
  };

  static CastPathData _parse(String d) {
    final tokens = RegExp(r'[A-Za-z]|-?\d*\.?\d+')
        .allMatches(d)
        .map((m) => m.group(0)!)
        .toList();
    final commands = <CastCommand>[];
    var i = 0;
    while (i < tokens.length) {
      final op = tokens[i++];
      final arity = _arity[op];
      if (arity == null) {
        throw FormatException('Unsupported path command "$op"', d);
      }
      final points = <Offset>[];
      for (var p = 0; p < arity; p++) {
        points.add(
          Offset(double.parse(tokens[i]), double.parse(tokens[i + 1])),
        );
        i += 2;
      }
      commands.add(CastCommand(op, points));
    }
    return CastPathData(commands);
  }

  /// Whether this and [other] have the same commands in the same order, so they can blend.
  bool matches(CastPathData other) {
    if (other.commands.length != commands.length) return false;
    for (var i = 0; i < commands.length; i++) {
      if (other.commands[i].op != commands[i].op) return false;
    }
    return true;
  }

  /// The point-by-point blend of two [matches]ing paths.
  static CastPathData lerp(CastPathData a, CastPathData b, double t) =>
      CastPathData([
        for (var i = 0; i < a.commands.length; i++)
          CastCommand(a.commands[i].op, [
            for (var p = 0; p < a.commands[i].points.length; p++)
              Offset.lerp(a.commands[i].points[p], b.commands[i].points[p], t)!,
          ]),
      ]);

  Path toPath() {
    final path = Path();
    for (final c in commands) {
      final p = c.points;
      switch (c.op) {
        case 'M':
          path.moveTo(p[0].dx, p[0].dy);
        case 'L':
          path.lineTo(p[0].dx, p[0].dy);
        case 'Q':
          path.quadraticBezierTo(p[0].dx, p[0].dy, p[1].dx, p[1].dy);
        case 'C':
          path.cubicTo(p[0].dx, p[0].dy, p[1].dx, p[1].dy, p[2].dx, p[2].dy);
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  /// The blend of two numbers, for the shapes that aren't paths.
  static double mix(double a, double b, double t) => lerpDouble(a, b, t)!;
}
