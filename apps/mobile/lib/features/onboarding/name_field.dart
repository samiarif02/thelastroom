import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';

/// The first-name question (brief 17; Daylight in brief 48): a big white field on its edge (the
/// floor's ring when focused), "Let's go" in honey, and "Skip, call me Candidate" as the quiet
/// second action. [onDone] gets the trimmed name, or null for the skip.
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

  static const double _ring = 2;

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
    final f = ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final style = DaylightType.heading5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _focus.requestFocus,
          child: AnimatedContainer(
            duration: still ? Duration.zero : DaylightMotion.colour,
            curve: DaylightMotion.ease,
            constraints: const BoxConstraints(minHeight: DaylightSpace.s64),
            padding: const EdgeInsets.symmetric(
              horizontal: DaylightSpace.s16,
              vertical: DaylightSpace.s16,
            ),
            decoration: BoxDecoration(
              color: DaylightColors.raised,
              borderRadius: BorderRadius.circular(DaylightRadius.card),
              border: Border.all(
                color: focused ? f.base : DaylightColors.raised,
                width: _ring,
              ),
              boxShadow: DaylightElevation.edgeOf(
                focused ? f.deep : DaylightColors.sand2,
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
                      style: style.copyWith(color: DaylightColors.ink3),
                    ),
                  ),
                // One node for screen readers: the label merged into EditableText's own text
                // field. (A second `textField: true` here made web screen readers see a dead,
                // disabled input: brief 31.) `enabled`, because the web marks a text field
                // without an enabled state `disabled`, and nothing could be typed (brief 44).
                MergeSemantics(
                  child: Semantics(
                    label: NameField.label,
                    enabled: true,
                    child: EditableText(
                      controller: _text,
                      focusNode: _focus,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: style,
                      cursorColor: f.base,
                      backgroundCursorColor: DaylightColors.sand2,
                      selectionColor: f.soft,
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
        const SizedBox(height: DaylightSpace.s24),
        TactileButton(
          label: NameField.confirm,
          icon: PhosphorBold.arrowRight,
          onPressed: name == null ? null : () => _finish(name),
        ),
        const SizedBox(height: DaylightSpace.s12),
        TactileButton(
          label: NameField.skip,
          tone: TactileTone.quiet,
          compact: true,
          onPressed: () => _finish(null),
        ),
      ],
    );
  }
}
