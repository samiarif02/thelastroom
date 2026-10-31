import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../set/office_set.dart';

/// The scene's practical light, on title cards and state screens: in the Morning Office it is
/// the mug on the desk ([DeskMug]) with its steam; [lit] false is the offline state, the
/// coffee gone cold ("the lights are out"). The name dates from the Boardroom's banker's lamp
/// and stays because the title and mission screens use it.
///
/// Drawn in code on a [aspectRatio] box; give it a width and it sizes itself.
class BankersLamp extends StatelessWidget {
  const BankersLamp({
    super.key,
    this.grade = ChapterGrade.lobby,
    this.lit = true,
    this.semanticLabel,
  });

  /// Width / height of the box.
  static const double aspectRatio = DeskMug.aspectRatio;

  final ChapterGrade grade;
  final bool lit;

  /// Null leaves it decorative (excluded from semantics).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mug = DeskMug(grade: grade, hot: lit);
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: mug);
    return Semantics(image: true, label: label, child: mug);
  }
}
