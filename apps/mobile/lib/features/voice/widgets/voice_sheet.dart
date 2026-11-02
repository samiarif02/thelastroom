import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// A question the player must answer before going on, as a sheet over the scene: "Delete this
/// take?", "Leave the interview?". The mission player's sheets in the same look, with the voice
/// mission's own words (a recording is never kept, so "your progress is saved" would be untrue).
class VoiceSheet extends StatelessWidget {
  const VoiceSheet({
    super.key,
    required this.title,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    this.grade = ChapterGrade.lobby,
  });

  final String title;
  final String line;

  /// The safe choice ("Keep it", "Stay"), the sunflower button.
  final String primary;
  final VoidCallback onPrimary;

  /// The one that throws something away.
  final String secondary;
  final VoidCallback onSecondary;
  final ChapterGrade grade;

  static const double _scrim = 0.72;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    // Only the sheet reaches a screen reader while it's up.
    return BlockSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: BrandVivid.night.withValues(alpha: _scrim)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [grade.deep, grade.deeper],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_radius),
                  ),
                  boxShadow: BrandVivid.cardShadow,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    BrandSpace.lg,
                    BrandSpace.lg,
                    BrandSpace.lg,
                    insets.bottom + BrandSpace.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: BrandVividType.title,
                        ),
                      ),
                      const SizedBox(height: BrandSpace.sm),
                      Text(
                        line,
                        textAlign: TextAlign.center,
                        style: BrandVividType.body,
                      ),
                      const SizedBox(height: BrandSpace.lg),
                      VividButton(
                        label: primary,
                        expand: true,
                        onPressed: onPrimary,
                      ),
                      const SizedBox(height: BrandSpace.sm),
                      VividButton(
                        label: secondary,
                        primary: false,
                        expand: true,
                        onPressed: onSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
