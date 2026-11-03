import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/choice/answer_card.dart' show AnswerCardState;
import '../../../ui/film/cue.dart';
import '../../../ui/film/timeline.dart';
import '../widgets/choice_card.dart';

/// The question, once it's been asked, as the "answer so far" strip above the cards
/// (direction.md §2: white 60%, r12): the player can still see what they're answering, or,
/// once a beat is said, the line they gave.
class QuestionReminder extends StatelessWidget {
  const QuestionReminder({
    super.key,
    required this.text,
    required this.grade,
    this.label,
  });

  final String text;
  final ChapterGrade grade;

  /// "Open": the beat already said, with a check. Null: the question, with a speech mark.
  final String? label;

  static const double _icon = 20;
  static const double _veil = 0.6;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    final said = label;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.raised.withValues(alpha: _veil),
        borderRadius: BorderRadius.circular(DaylightRadius.tile),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DaylightSpace.s12,
          vertical: DaylightSpace.s8,
        ),
        child: Row(
          children: [
            Icon(
              said == null ? PhosphorFill.chatCircle : PhosphorFill.checkCircle,
              size: _icon,
              color: f.base,
            ),
            const SizedBox(width: DaylightSpace.s8),
            if (said != null) ...[
              Text(said, style: DaylightType.body4),
              const SizedBox(width: DaylightSpace.s4),
            ],
            Expanded(
              child: Text(
                '“$text”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The beat's name in the top bar's progress ("Open", "Evidence", "Land").
String beatName(BeatKind kind) => _beatNames[kind]!;

const Map<BeatKind, String> _beatNames = {
  BeatKind.open: 'Open',
  BeatKind.evidence: 'Evidence',
  BeatKind.land: 'Land',
};

/// "Pick your evidence": the heading over a beat's cards. [index] and [count] are kept for
/// screen readers ("2 of 3").
String beatLabel(BeatKind kind, int index, int count) =>
    'Pick your ${_pickNouns[kind]}';

const Map<BeatKind, String> _pickNouns = {
  BeatKind.open: 'opening',
  BeatKind.evidence: 'evidence',
  BeatKind.land: 'close',
};

/// "Build your answer": above a built beat's fragments (brief 27).
String buildLabel(int index, int count) => buildKicker;

const String buildKicker = 'Build your answer';

/// Above the follow-up's replies.
const String replyLabel = 'Your reply';

/// Above the reasons, when the interviewer asks why.
const String reasonLabel = 'What makes it work?';

/// Under [reasonLabel].
const String reasonHelper = 'Pick the principle. It is the part you keep.';

/// Beside a beat's heading.
const String pickHelper = 'Tap a line, then lock it in';

/// Replaces the helper while a pick can still be changed.
const String changeHint = 'Tap another line to change';

/// A principle's glyph on its reason card, from what the principle is about. Cosmetic: the
/// content names no icons.
IconData principleIcon(String text) {
  final t = text.toLowerCase();
  if (RegExp(r'number|data|figure|percent|\d').hasMatch(t)) {
    return PhosphorBold.hash;
  }
  if (RegExp(r'\bwe\b|team|credit|together').hasMatch(t)) {
    return PhosphorBold.usersThree;
  }
  if (RegExp(r'ask|question|asked').hasMatch(t)) return PhosphorBold.chatCircle;
  if (RegExp(r'story|example').hasMatch(t)) return PhosphorBold.bookOpen;
  if (RegExp(r'role|job|company|hiring').hasMatch(t)) {
    return PhosphorBold.target;
  }
  if (RegExp(r'honest|confiden|passion|modest').hasMatch(t)) {
    return PhosphorBold.handshake;
  }
  return _fallback[t.length % _fallback.length];
}

const List<IconData> _fallback = [
  PhosphorBold.lightbulbFilament,
  PhosphorBold.target,
  PhosphorBold.sparkle,
  PhosphorBold.flag,
];

/// The lines to pick from, arriving one after another (60 ms apart): a beat's answers, a
/// follow-up's replies or the reasons for "why that line?". **One tap picks** ([onPick]); the
/// picked card lifts ([selected]) and, once [locked], the others dim. [onArrived] fires when
/// the last card has arrived: the moment the player can read them all, when the stopwatch
/// starts. The [label] heads them (Title 3) with a [helper] beside or under it.
class AnswerCards<T extends Object> extends StatelessWidget {
  const AnswerCards({
    super.key,
    required this.label,
    required this.items,
    required this.textOf,
    required this.grade,
    required this.onPick,
    this.helper,
    this.iconOf,
    this.selected,
    this.locked,
    this.onArrived,
  });

  final String label;
  final String? helper;

  /// In the attempt's shuffled order.
  final List<T> items;
  final String Function(T) textOf;

  /// A glyph per card instead of its letter (the reasons).
  final IconData Function(T)? iconOf;
  final ChapterGrade grade;
  final T? selected;
  final T? locked;
  final ValueChanged<T> onPick;
  final VoidCallback? onArrived;

  AnswerCardState _stateOf(T item) {
    if (locked != null) {
      return item == locked ? AnswerCardState.locked : AnswerCardState.disabled;
    }
    if (selected != null) {
      return item == selected ? AnswerCardState.selected : AnswerCardState.idle;
    }
    return AnswerCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final help = helper;
    final icons = iconOf;
    final arrive =
        DaylightMotion.move + DaylightMotion.stagger * (items.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: DaylightSpace.s12,
          runSpacing: DaylightSpace.s2,
          children: [
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                label,
                style: DaylightType.title3.copyWith(
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation.weight(600)],
                ),
              ),
            ),
            if (help != null)
              Text(
                help,
                style: DaylightType.caption4.copyWith(
                  color: DaylightColors.ink2,
                ),
              ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s8),
        Timeline(
          duration: arrive,
          onFinished: onArrived,
          builder: (context, t, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : DaylightSpace.s8),
                  child: _arrive(
                    cue(
                      t,
                      (DaylightMotion.stagger * i).inMicroseconds /
                          arrive.inMicroseconds,
                      ((DaylightMotion.stagger * i) + DaylightMotion.move)
                              .inMicroseconds /
                          arrive.inMicroseconds,
                      DaylightMotion.ease,
                    ),
                    ChoiceCard(
                      numeral: ChoiceCard.letterFor(i),
                      text: textOf(items[i]),
                      icon: icons?.call(items[i]),
                      grade: grade,
                      state: _stateOf(items[i]),
                      onTap: () => onPick(items[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrive(double t, Widget card) => Opacity(
    opacity: t,
    child: Transform.translate(
      offset: Offset(0, (1 - t) * DaylightSpace.s8),
      child: card,
    ),
  );
}
