import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cue_button.dart';

/// Draft first (FR-11): before Jordan's lines appear, the player may start the answer in their
/// own words. A sheet of the candidate's notepad on the desk: the prompt, a ruled line to
/// write on, and "Skip" as plain as "Keep it". The words go to [onDone] and stay on the device.
class DraftPanel extends StatefulWidget {
  const DraftPanel({
    super.key,
    required this.onDone,
    this.grade = ChapterGrade.lobby,
  });

  /// The draft, or null when skipped.
  final ValueChanged<String?> onDone;
  final ChapterGrade grade;

  static const String heading = 'YOUR OWN WORDS FIRST';
  static const String placeholder = 'Start with one sentence…';
  static const String skip = 'Skip';
  static const String keep = 'Keep it';

  /// A first line, not an essay.
  static const int maxLength = 280;

  @override
  State<DraftPanel> createState() => _DraftPanelState();
}

class _DraftPanelState extends State<DraftPanel> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _done = false;

  static const int _maxLines = 4;
  static const double _hairline = 0.8;

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish(String? draft) {
    if (_done) return;
    _done = true;
    _focus.unfocus();
    widget.onDone(draft);
  }

  @override
  Widget build(BuildContext context) {
    final brass = widget.grade.key;
    final hasText = _text.text.trim().isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surfaceRaised.withValues(alpha: 0.94),
        border: Border.all(color: brass.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                DraftPanel.heading,
                style: BrandType.label.copyWith(color: brass),
              ),
            ),
            const SizedBox(height: BrandSpace.sm),
            Text(
              draftPrompt,
              style: BrandType.body.copyWith(color: BrandColors.textSecondary),
            ),
            const SizedBox(height: BrandSpace.md),
            GestureDetector(
              onTap: _focus.requestFocus,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: BrandSpace.minTarget,
                ),
                padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: brass.withValues(
                        alpha: _focus.hasFocus ? 0.9 : 0.4,
                      ),
                      width: _hairline,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    if (!hasText)
                      ExcludeSemantics(
                        child: Text(
                          DraftPanel.placeholder,
                          style: BrandType.choice.copyWith(
                            color: BrandColors.textSecondary,
                          ),
                        ),
                      ),
                    Semantics(
                      label: DraftPanel.heading,
                      textField: true,
                      child: EditableText(
                        controller: _text,
                        focusNode: _focus,
                        style: BrandType.choice,
                        cursorColor: brass,
                        backgroundCursorColor: BrandColors.textSecondary,
                        selectionColor: brass.withValues(alpha: 0.3),
                        minLines: 1,
                        maxLines: _maxLines,
                        keyboardType: TextInputType.multiline,
                        keyboardAppearance: Brightness.dark,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            DraftPanel.maxLength,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: BrandSpace.md),
            Row(
              children: [
                Expanded(
                  child: CueButton(
                    label: DraftPanel.skip,
                    quiet: true,
                    grade: widget.grade,
                    onPressed: () => _finish(null),
                  ),
                ),
                const SizedBox(width: BrandSpace.sm),
                Expanded(
                  child: CueButton(
                    label: DraftPanel.keep,
                    grade: widget.grade,
                    onPressed: hasText ? () => _finish(_text.text) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
