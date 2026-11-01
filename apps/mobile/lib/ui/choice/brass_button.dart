import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../vivid/vivid_button.dart';

/// The action under a state scene ("Try again", "Back to the lobby"). Brief 23 made the app one
/// button style: this is now the vivid sunflower pill ([VividButton]), kept under its old name
/// so its callers don't change. Null [onTap] is disabled.
class BrassButton extends StatelessWidget {
  const BrassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.grade = ChapterGrade.lobby,
  });

  final String label;
  final VoidCallback? onTap;

  /// Kept for the old callers; the pill is the same in every chapter.
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) =>
      VividButton(label: label, onPressed: onTap);
}
