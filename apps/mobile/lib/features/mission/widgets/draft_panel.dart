import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

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

  static const String heading = 'Your own words first';
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
    final f = widget.grade.floor;
    final hasText = _text.text.trim().isNotEmpty;
    return DaylightPanel(
      // The player's own page: a white card on the floor's tint.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              DraftPanel.heading,
              style: DaylightType.caption3.copyWith(color: f.deep),
            ),
          ),
          const SizedBox(height: DaylightSpace.s4),
          Text(draftPrompt, style: DaylightType.body6),
          const SizedBox(height: DaylightSpace.s12),
          GestureDetector(
            onTap: _focus.requestFocus,
            child: Container(
              constraints: const BoxConstraints(minHeight: DaylightSize.hit),
              padding: const EdgeInsets.all(DaylightSpace.s12),
              decoration: BoxDecoration(
                color: DaylightColors.sand,
                borderRadius: BorderRadius.circular(DaylightRadius.tile),
                border: Border.all(
                  color: _focus.hasFocus ? f.base : DaylightColors.sand,
                  width: _ring,
                ),
              ),
              child: Stack(
                children: [
                  if (!hasText)
                    ExcludeSemantics(
                      child: Text(
                        DraftPanel.placeholder,
                        style: DaylightType.body3.copyWith(
                          color: DaylightColors.ink2,
                        ),
                      ),
                    ),
                  // One node for screen readers: the label merges into EditableText's own
                  // text field. A second `textField: true` here made the web's textarea
                  // read as disabled until focused (brief 30, as 1e found on the name field).
                  // `enabled`: without it the web still marks the textarea `disabled` (brief 44).
                  MergeSemantics(
                    child: Semantics(
                      label: DraftPanel.heading,
                      enabled: true,
                      child: EditableText(
                        controller: _text,
                        focusNode: _focus,
                        style: DaylightType.body3,
                        cursorColor: f.base,
                        backgroundCursorColor: DaylightColors.ink2,
                        selectionColor: f.soft,
                        minLines: 1,
                        maxLines: _maxLines,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            DraftPanel.maxLength,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DaylightSpace.s16),
          Row(
            children: [
              Expanded(
                child: TactileButton(
                  label: DraftPanel.skip,
                  tone: TactileTone.quiet,
                  compact: true,
                  onPressed: () => _finish(null),
                ),
              ),
              const SizedBox(width: DaylightSpace.s8),
              Expanded(
                child: TactileButton(
                  label: DraftPanel.keep,
                  compact: true,
                  onPressed: hasText ? () => _finish(_text.text) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const double _ring = 2;
}
