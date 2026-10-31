import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import 'debrief_facts.dart';
import 'red_pen_slip.dart';

/// "Your reasoning": each beat's line with the reason the player gave, marked right or not, and
/// the right reasoning beside a wrong one, so the lesson is about thinking, not about which
/// card was lucky. A guessed beat is marked in red pen with how fast it was picked.
class ReasoningSlip extends StatelessWidget {
  const ReasoningSlip({super.key, required this.beats});

  final List<BeatReasoning> beats;

  static const String heading = 'YOUR REASONING';
  static const String yourReason = 'You said';
  static const String principle = 'What holds';
  static const String fellFor = 'You fell for';
  static const String sound = 'SOUND';
  static const String unsound = 'NOT WHY IT WORKS';

  static String guessedNote(Duration? decidedIn) {
    final ms = decidedIn?.inMilliseconds ?? 0;
    return 'GUESSED IN ${(ms / _msPerSecond).toStringAsFixed(1)} SECONDS';
  }

  static const int _msPerSecond = 1000;

  static const Map<BeatKind, String> _names = {
    BeatKind.open: 'OPEN',
    BeatKind.evidence: 'EVIDENCE',
    BeatKind.land: 'LAND',
  };

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(heading, style: soft)),
          for (final beat in beats) ...[
            const SizedBox(height: BrandSpace.md),
            _BeatRow(beat: beat, name: _names[beat.kind]!),
          ],
        ],
      ),
    );
  }
}

class _BeatRow extends StatelessWidget {
  const _BeatRow({required this.beat, required this.name});

  final BeatReasoning beat;
  final String name;

  static const double _bar = 2;

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    final ink = BrandType.body.copyWith(color: BrandColors.ink);
    final given = beat.given;
    final principle = beat.principle;
    final fellFor = beat.fellFor;
    final sound = beat.sound;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: beat.guessed || sound == false || !beat.strongest
                ? BrandColors.redPen
                : BrandColors.inkSoft.withValues(alpha: 0.4),
            width: _bar,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: BrandSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: soft),
            const SizedBox(height: BrandSpace.xs),
            Text(
              '“${beat.line.text}”',
              style: BrandType.choice.copyWith(
                color: BrandColors.ink,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (beat.guessed) ...[
              const SizedBox(height: BrandSpace.xs),
              Text(
                ReasoningSlip.guessedNote(beat.decidedIn),
                style: BrandType.label.copyWith(color: BrandColors.redPen),
              ),
            ],
            // The misconception the line fell for says it all when it's what the player said.
            if (given != null && given != fellFor) ...[
              const SizedBox(height: BrandSpace.sm),
              Text('${ReasoningSlip.yourReason}: ${given.text}', style: ink),
              Text(
                sound! ? ReasoningSlip.sound : ReasoningSlip.unsound,
                style: BrandType.label.copyWith(
                  color: sound ? BrandColors.inkSoft : BrandColors.redPen,
                ),
              ),
            ],
            if (fellFor != null) ...[
              const SizedBox(height: BrandSpace.xs),
              Text(
                '${ReasoningSlip.fellFor}: ${fellFor.text}',
                style: ink.copyWith(color: BrandColors.redPen),
              ),
            ],
            if (principle != null && sound != true) ...[
              const SizedBox(height: BrandSpace.xs),
              Text(
                '${ReasoningSlip.principle}: ${principle.text}',
                style: ink.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
