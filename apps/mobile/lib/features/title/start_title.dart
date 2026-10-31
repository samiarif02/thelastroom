import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'title_screen.dart';

/// A returning player's cold start (brief 20): the title plays for a moment over [child] (the
/// tower), then fades away; a tap skips it. Under reduced motion it isn't shown at all.
class StartTitle extends StatefulWidget {
  const StartTitle({super.key, required this.child});

  final Widget child;

  /// The title, then a beat on the name before it fades.
  static const Duration hold = Duration(milliseconds: 1700);

  static const String skipLabel = 'Skip the title';

  @override
  State<StartTitle> createState() => _StartTitleState();
}

class _StartTitleState extends State<StartTitle> {
  bool _shown = true;
  bool _gone = false;
  late final Timer _hold = Timer(StartTitle.hold, _skip);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _shown = false;
  }

  @override
  void initState() {
    super.initState();
    _hold; // starts the clock
  }

  @override
  void dispose() {
    _hold.cancel();
    super.dispose();
  }

  void _skip() {
    if (mounted && _shown) setState(() => _shown = false);
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (!_gone)
        IgnorePointer(
          ignoring: !_shown,
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: BrandMotion.standard,
            onEnd: () {
              if (!_shown && mounted) setState(() => _gone = true);
            },
            child: Semantics(
              button: true,
              label: StartTitle.skipLabel,
              onTap: _skip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _skip,
                child: const TitleScreen(),
              ),
            ),
          ),
        ),
    ],
  );
}
