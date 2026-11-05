import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import 'explainer_deck.dart';

/// "How it works" again, from Settings (issue 75): the explainer on its own, without
/// onboarding's questions. Close, "Done" or back on its first page returns to Settings; back on
/// a later page turns back a page.
class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  final GlobalKey<ExplainerDeckState> _deck = GlobalKey();

  void _done({required bool skipped}) {
    if (mounted) context.go(Routes.settings);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      final deck = _deck.currentState;
      if (deck == null) return;
      if (!deck.back()) deck.close();
    },
    child: ExplainerDeck(key: _deck, replay: true, onDone: _done),
  );
}
