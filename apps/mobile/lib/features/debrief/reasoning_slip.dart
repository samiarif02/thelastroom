import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import 'debrief_facts.dart';
import 'red_pen_slip.dart';

/// "Your reasoning": each beat's line with the reason the player gave, marked right or not, and
/// the right reasoning beside a wrong one, so the lesson is about thinking, not about which
/// card was lucky. A guessed beat is marked in red pen with how fast it was picked. A built beat
/// (brief 27) says what its answer lost and sets the strong one beside it.
class ReasoningSlip extends StatelessWidget {
  const ReasoningSlip({super.key, required this.beats});

  final List<BeatReasoning> beats;

  static const String heading = 'Your reasoning';
  static const String yourReason = 'You said';
  static const String principle = 'What holds';
  static const String fellFor = 'You fell for';
  static const String sound = 'Sound';
  static const String unsound = 'Not why it works';

  /// Above the strong answer, beside a built one that wasn't it (brief 27).
  static const String strongBuild = 'Built strong';

  /// What a built answer lost, piece by piece, or that it lost nothing.
  static String buildNote(BuildResult built) {
    if (built.perfect) return 'Built in order, nothing missing';
    String pieces(int n) => n == 1 ? '1 piece' : '$n pieces';
    final notes = [
      if (built.outOfOrder > 0) '${pieces(built.outOfOrder)} out of order',
      if (built.missing > 0) '${pieces(built.missing)} left out',
      if (built.decoysUsed.isNotEmpty) 'the decoy went in',
    ].join(' · ');
    return notes[0].toUpperCase() + notes.substring(1);
  }

  static String guessedNote(Duration? decidedIn) {
    final ms = decidedIn?.inMilliseconds ?? 0;
    return 'Guessed in ${(ms / _msPerSecond).toStringAsFixed(1)} seconds';
  }

  static const int _msPerSecond = 1000;

  static const Map<BeatKind, String> _names = {
    BeatKind.open: 'Open',
    BeatKind.evidence: 'Evidence',
    BeatKind.land: 'Land',
  };

  @override
  Widget build(BuildContext context) {
    final soft = SlipType.label.copyWith(color: SlipInk.soft);
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(heading, style: soft)),
          for (final beat in beats) ...[
            const SizedBox(height: DaylightSpace.s16),
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

  @override
  Widget build(BuildContext context) {
    final soft = SlipType.label.copyWith(color: SlipInk.soft);
    final ink = SlipType.body.copyWith(color: SlipInk.text);
    final given = beat.given;
    final principle = beat.principle;
    final fellFor = beat.fellFor;
    final sound = beat.sound;
    // Each beat on the sand well, the trap's tint where it cost (no one-sided bars).
    return DecoratedBox(
      decoration: BoxDecoration(
        color: beat.guessed || sound == false || !beat.strongest
            ? DaylightColors.trapTint
            : DaylightColors.paper,
        borderRadius: BorderRadius.circular(DaylightRadius.tile),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: soft),
            const SizedBox(height: DaylightSpace.s4),
            Text(
              '“${beat.line.text}”',
              style: SlipType.quote.copyWith(color: SlipInk.text),
            ),
            if (beat.built case final built?) ...[
              const SizedBox(height: DaylightSpace.s4),
              Text(
                ReasoningSlip.buildNote(built),
                style: SlipType.label.copyWith(
                  color: built.perfect ? SlipInk.soft : SlipInk.mark,
                ),
              ),
            ],
            if (beat.strongBuild case final strong?) ...[
              const SizedBox(height: DaylightSpace.s8),
              Text('${ReasoningSlip.strongBuild}:', style: soft),
              Text(
                '“${strong.text}”',
                style: SlipType.quote.copyWith(color: SlipInk.text),
              ),
            ],
            if (beat.guessed) ...[
              const SizedBox(height: DaylightSpace.s4),
              Text(
                ReasoningSlip.guessedNote(beat.decidedIn),
                style: SlipType.label.copyWith(color: SlipInk.mark),
              ),
            ],
            // The misconception the line fell for says it all when it's what the player said.
            if (given != null && given != fellFor) ...[
              const SizedBox(height: DaylightSpace.s8),
              Text('${ReasoningSlip.yourReason}: ${given.text}', style: ink),
              Text(
                sound! ? ReasoningSlip.sound : ReasoningSlip.unsound,
                style: SlipType.label.copyWith(
                  color: sound ? SlipInk.soft : SlipInk.mark,
                ),
              ),
            ],
            if (fellFor != null) ...[
              const SizedBox(height: DaylightSpace.s4),
              Text(
                '${ReasoningSlip.fellFor}: ${fellFor.text}',
                style: ink.copyWith(color: SlipInk.mark),
              ),
            ],
            if (principle != null && sound != true) ...[
              const SizedBox(height: DaylightSpace.s4),
              Text('${ReasoningSlip.principle}: ${principle.text}', style: ink),
            ],
          ],
        ),
      ),
    );
  }
}

/// No line had a lesson and nothing was guessed, yet points were lost: a built answer missing a
/// piece or out of order, or the right line for the wrong reason. Says which beats and why, so
/// the dossier never reads "nothing to mark" over a lower score (brief 30's playthrough).
class CostSlip extends StatelessWidget {
  const CostSlip({super.key, required this.beats});

  /// Every beat, in order; only the ones that lost points are named.
  final List<BeatReasoning> beats;

  static const String heading = 'What cost you';
  static const String rightLineWrongReason = 'the right line, not why it works';
  static const String notStrongest = 'not the strongest line';
  static const String takeaway =
      'Nothing to underline, but these beats kept less than full marks. Your reasoning, below, '
      'shows each one.';

  /// Whether [beat] lost points that no lesson explains.
  static bool lost(BeatReasoning beat) =>
      !beat.guessed &&
      ((beat.built?.perfect == false) ||
          beat.sound == false ||
          (beat.built == null && !beat.strongest));

  /// Whether any beat in [beats] did: the dossier shows this slip instead of the clean one.
  static bool applies(List<BeatReasoning> beats) => beats.any(lost);

  /// "The evidence: 1 piece out of order."
  static String line(BeatReasoning beat) {
    final what = switch (beat) {
      BeatReasoning(:final built?) => ReasoningSlip.buildNote(
        built,
      ).toLowerCase(),
      BeatReasoning(sound: false) => rightLineWrongReason,
      _ => notStrongest,
    };
    return 'The ${beat.kind.name}: $what.';
  }

  @override
  Widget build(BuildContext context) => PaperSlip(
    trap: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: SlipType.label.copyWith(color: SlipInk.mark)),
        const SizedBox(height: DaylightSpace.s8),
        for (final beat in beats.where(lost))
          Text(line(beat), style: SlipType.body.copyWith(color: SlipInk.mark)),
        const SizedBox(height: DaylightSpace.s8),
        Text(takeaway, style: SlipType.body.copyWith(color: SlipInk.text)),
      ],
    ),
  );
}
