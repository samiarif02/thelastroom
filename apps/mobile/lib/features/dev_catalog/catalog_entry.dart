import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// One state of a component, drawn full frame in the catalog and in its golden.
class CatalogShot {
  const CatalogShot({
    required this.id,
    required this.label,
    required this.build,
    this.settle = BrandMotion.cinematic,
  });

  /// Stable, file-name safe: the golden is `<entry>-<shot>.png`.
  final String id;
  final String label;

  /// Draws the shot in the catalog's chosen grade.
  final Widget Function(ChapterGrade grade) build;

  /// How long the shot's choreography takes to come to rest: the golden is taken after it.
  final Duration settle;
}

/// A film-kit component and every state worth seeing (`/dev/catalog/<id>`).
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.note,
    required this.shots,
  });

  final String id;
  final String name;

  /// One line on what it is and its seams.
  final String note;
  final List<CatalogShot> shots;

  CatalogShot shot(String? id) =>
      shots.firstWhere((s) => s.id == id, orElse: () => shots.first);
}
