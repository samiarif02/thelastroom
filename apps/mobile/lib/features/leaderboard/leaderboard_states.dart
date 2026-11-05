import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../core/backend/remote_rows.dart';
import '../../ui/daylight/daylight_kit.dart';

/// The board's calm states: nobody has scored yet, no backend in this build, the board out of
/// reach. Each one is a white card with a member of the cast and one clear next step.
class BoardNotice extends StatelessWidget {
  const BoardNotice({
    super.key,
    required this.person,
    required this.title,
    required this.line,
    this.action,
    this.actionIcon,
    this.onAction,
    this.quiet = false,
  });

  final CastPerson person;
  final String title;
  final String line;
  final String? action;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// A quiet button (a retry) instead of the honey one.
  final bool quiet;

  static String emptyTitle(LeaderboardScope scope) =>
      scope == LeaderboardScope.week
      ? 'Be the first on the board this week'
      : 'Be the first on the board';
  static const String emptyLine =
      'Play a room: every answer earns XP, and this week’s board starts again on Monday '
      '(00:00 UTC).';
  static const String play = 'Play a room';

  static const String noBackendTitle = 'The board lives on the tower’s server';
  static const String noBackendLine =
      'This copy of the game plays fully offline, so there’s no shared board to show. '
      'Your league above still counts every XP you earn.';

  static const String offlineTitle = 'Can’t reach the board right now';
  static const String offlineLine =
      'You’re offline, or the server is busy. Your XP is saved on this phone and joins '
      'the board when you’re back.';
  static const String retry = 'Try again';

  @override
  Widget build(BuildContext context) {
    final label = action;
    return DaylightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArchPortrait(
                person: person,
                expression: CastExpression.smile,
                width: 64,
                height: 78,
                ground: DaylightColors.honeyTint,
                idle: false,
              ),
              const SizedBox(width: DaylightSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: DaylightType.heading6),
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Text(
                      line,
                      style: DaylightType.body6.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: DaylightSpace.s16),
            TactileButton(
              label: label,
              icon: actionIcon,
              tone: quiet ? TactileTone.quiet : TactileTone.honey,
              compact: true,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// While the board loads: the podium's three arches and a few rows in sand, still shapes (no
/// shimmer to sit through). Screen readers hear "Loading the leaderboard".
class BoardSkeleton extends StatelessWidget {
  const BoardSkeleton({super.key});

  static const String label = 'Loading the leaderboard';
  static const int _rows = 4;
  static const List<double> _steps = [56, 76, 44];

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in _steps)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DaylightSpace.s4,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 68,
                        height: 82,
                        child: ArchFrame(
                          ground: DaylightColors.sand,
                          child: SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: DaylightSpace.s12),
                      _bar(64, 12),
                      const SizedBox(height: DaylightSpace.s12),
                      Container(
                        height: h,
                        decoration: const BoxDecoration(
                          color: DaylightColors.sand,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(DaylightRadius.card),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s16),
        DaylightPanel(
          child: Column(
            children: [
              for (var i = 0; i < _rows; i++) ...[
                if (i > 0) const SizedBox(height: DaylightSpace.s16),
                Row(
                  children: [
                    _bar(24, 24, round: true),
                    const SizedBox(width: DaylightSpace.s12),
                    Expanded(child: _bar(double.infinity, 14)),
                    const SizedBox(width: DaylightSpace.s40),
                    _bar(48, 14),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  static Widget _bar(double w, double h, {bool round = false}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: DaylightColors.sand,
      borderRadius: BorderRadius.circular(round ? h / 2 : DaylightRadius.tag),
    ),
  );
}
