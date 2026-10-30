import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../mission/widgets/cue_button.dart';

/// The first-name question: a ruled line to write on (like the draft panel), "That's me", and
/// "Skip, call me Candidate". [onDone] gets the trimmed name, or null for the skip.
class NameField extends StatefulWidget {
  const NameField({super.key, required this.onDone, required this.grade});

  final ValueChanged<String?> onDone;
  final ChapterGrade grade;

  static const String label = 'Your first name';
  static const String confirm = "That's me";
  static const String skip = 'Skip, call me Candidate';

  /// A first name, not a bio.
  static const int maxLength = 24;

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _done = false;

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

  String? get _name {
    final name = _text.text.trim();
    return name.isEmpty ? null : name;
  }

  void _finish(String? name) {
    if (_done) return;
    _done = true;
    _focus.unfocus();
    widget.onDone(name);
  }

  @override
  Widget build(BuildContext context) {
    final brass = widget.grade.key;
    final name = _name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _focus.requestFocus,
          child: Container(
            constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
            padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: brass.withValues(alpha: _focus.hasFocus ? 0.9 : 0.4),
                  width: _hairline,
                ),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_text.text.isEmpty)
                  ExcludeSemantics(
                    child: Text(
                      NameField.label,
                      textAlign: TextAlign.center,
                      style: BrandType.choice.copyWith(
                        color: BrandColors.textSecondary,
                      ),
                    ),
                  ),
                // One node for screen readers: the label and the field (EditableText's own
                // node would otherwise be a second, unlabelled text field).
                MergeSemantics(
                  child: Semantics(
                    label: NameField.label,
                    textField: true,
                    child: EditableText(
                      controller: _text,
                      focusNode: _focus,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: BrandType.choice,
                      cursorColor: brass,
                      backgroundCursorColor: BrandColors.textSecondary,
                      selectionColor: brass.withValues(alpha: 0.3),
                      keyboardAppearance: Brightness.dark,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_name != null) _finish(_name);
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(NameField.maxLength),
                        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BrandSpace.lg),
        CueButton(
          label: NameField.confirm,
          grade: widget.grade,
          onPressed: name == null ? null : () => _finish(name),
        ),
        const SizedBox(height: BrandSpace.sm),
        CueButton(
          label: NameField.skip,
          quiet: true,
          grade: widget.grade,
          onPressed: () => _finish(null),
        ),
      ],
    );
  }
}
