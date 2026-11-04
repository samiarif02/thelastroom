import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';

/// A one-line field inside a white card (the email and the code of "Save your progress"): the
/// paper ground on the sand edge, the floor's ring when focused, the trap's when [error] is
/// set. The placeholder is [label], which screen readers also hear. No Material: an
/// [EditableText], like the name field of onboarding.
class EntryField extends StatefulWidget {
  const EntryField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.autofillHints = const [],
    this.inputFormatters = const [],
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.enabled = true,
    this.error = false,
    this.code = false,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<String> autofillHints;
  final List<TextInputFormatter> inputFormatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// False while the step it belongs to is sending: the text stays, it can't be changed.
  final bool enabled;

  /// The last try failed: the ring is the trap's.
  final bool error;

  /// A one-time code: big tabular figures, spaced. Start-aligned like any field, so the empty
  /// field's cursor never sits on the label.
  final bool code;
  final bool autofocus;

  @override
  State<EntryField> createState() => _EntryFieldState();
}

class _EntryFieldState extends State<EntryField> {
  final FocusNode _focus = FocusNode();

  static const double _ring = 2;
  static const double _codeSpacing = 8;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(EntryField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final focused = _focus.hasFocus;
    final ring = widget.error
        ? DaylightColors.trap
        : focused
        ? f.base
        : DaylightColors.paper;
    final base = widget.code
        ? DaylightType.tabular(DaylightType.heading5)
              .copyWith(letterSpacing: _codeSpacing)
        : DaylightType.body3;
    final style = widget.enabled
        ? base
        : base.copyWith(color: DaylightColors.ink2);
    return GestureDetector(
      onTap: widget.enabled ? _focus.requestFocus : null,
      child: AnimatedContainer(
        duration: still ? Duration.zero : DaylightMotion.colour,
        curve: DaylightMotion.ease,
        constraints: const BoxConstraints(minHeight: DaylightSize.button),
        padding: const EdgeInsets.symmetric(
          horizontal: DaylightSpace.s16,
          vertical: DaylightSpace.s12,
        ),
        decoration: BoxDecoration(
          color: DaylightColors.paper,
          borderRadius: BorderRadius.circular(DaylightRadius.tile),
          border: Border.all(color: ring, width: _ring),
          boxShadow: DaylightElevation.edgeOf(
            DaylightColors.sand2,
            depth: DaylightSize.edgeSmall,
          ),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (widget.controller.text.isEmpty)
              ExcludeSemantics(
                child: Text(
                  widget.label,
                  style: (widget.code ? DaylightType.body3 : base).copyWith(
                    color: DaylightColors.ink3,
                    letterSpacing: 0,
                  ),
                ),
              ),
            // One node for screen readers, enabled (the name field's lessons, briefs 31, 44).
            MergeSemantics(
              child: Semantics(
                label: widget.label,
                enabled: widget.enabled,
                child: EditableText(
                  controller: widget.controller,
                  focusNode: _focus,
                  readOnly: !widget.enabled,
                  autofocus: widget.autofocus,
                  style: style,
                  cursorColor: f.base,
                  backgroundCursorColor: DaylightColors.sand2,
                  selectionColor: f.soft,
                  keyboardType: widget.keyboardType,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: widget.autofillHints,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                    ...widget.inputFormatters,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
