import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The first-name question (brief 17): a big glassy field on colour, "Let's go" in sunflower,
/// and "Skip, call me Candidate". [onDone] gets the trimmed name, or null for the skip.
class NameField extends StatefulWidget {
  const NameField({super.key, required this.onDone});

  final ValueChanged<String?> onDone;

  static const String label = 'Your first name';
  static const String confirm = 'Let’s go';
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

  static const double _fieldAlpha = 0.14;
  static const double _fontSize = 22;

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
    final name = _name;
    final focused = _focus.hasFocus;
    final style = BrandVividType.title.copyWith(fontSize: _fontSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _focus.requestFocus,
          child: AnimatedContainer(
            duration: BrandMotion.quick,
            constraints: const BoxConstraints(minHeight: BrandSpace.xxl),
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSpace.md,
              vertical: BrandSpace.md,
            ),
            decoration: BoxDecoration(
              color: BrandVivid.onDeep.withValues(alpha: _fieldAlpha),
              borderRadius: BorderRadius.circular(BrandRadius.lg),
              border: Border.all(
                color: focused ? BrandVivid.accent : BrandVivid.hairline(0.3),
                width: focused ? 2 : 1,
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
                      style: style.copyWith(
                        color: BrandVivid.onDeepSoft,
                        fontWeight: FontWeight.w600,
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
                      style: style,
                      cursorColor: BrandVivid.accent,
                      backgroundCursorColor: BrandVivid.onDeepSoft,
                      selectionColor: BrandVivid.accent.withValues(alpha: 0.4),
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
        VividButton(
          label: NameField.confirm,
          expand: true,
          onPressed: name == null ? null : () => _finish(name),
        ),
        const SizedBox(height: BrandSpace.sm),
        Center(
          child: VividButton(
            label: NameField.skip,
            primary: false,
            onPressed: () => _finish(null),
          ),
        ),
      ],
    );
  }
}
