import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'boardroom/boardroom_dossier.dart';
import 'boardroom/boardroom_scene.dart';
import 'boardroom/boardroom_title.dart';

/// The three frames every direction shows (brief 03).
enum DirectionFrame {
  title('Title'),
  scene('Scene'),
  dossier('Dossier');

  const DirectionFrame(this.label);

  final String label;

  static DirectionFrame parse(String? name) =>
      values.firstWhere((f) => f.name == name, orElse: () => title);
}

/// A direction's tokens plus its three frames and its film stock (grain and vignette).
class DirectionStudio {
  const DirectionStudio({
    required this.direction,
    required this.title,
    required this.scene,
    required this.dossier,
    required this.grain,
    required this.vignette,
  });

  final CinematicDirection direction;
  final Widget title;
  final Widget scene;
  final Widget dossier;

  /// Grain opacity, 0–1.
  final double grain;

  /// Vignette strength, 0–1.
  final double vignette;

  Widget frame(DirectionFrame f) => switch (f) {
    DirectionFrame.title => title,
    DirectionFrame.scene => scene,
    DirectionFrame.dossier => dossier,
  };

  static const List<DirectionStudio> all = [
    DirectionStudio(
      direction: boardroom,
      title: BoardroomTitle(),
      scene: BoardroomScene(),
      dossier: BoardroomDossier(),
      grain: BrandFilm.grain,
      vignette: BrandFilm.vignette,
    ),
  ];

  static DirectionStudio? byId(String id) {
    for (final s in all) {
      if (s.direction.id == id) return s;
    }
    return null;
  }
}
