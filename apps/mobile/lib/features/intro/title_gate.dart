import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/film_kit.dart';
import '../title/title_screen.dart';

/// The first launch's way in (brief 20): the title, then one sunflower "Begin" straight into
/// onboarding (which explains the game). A tap anywhere, also during the title, does the same.
class TitleGate extends ConsumerStatefulWidget {
  const TitleGate({super.key});

  static const String prompt = 'Begin';

  @override
  ConsumerState<TitleGate> createState() => _TitleGateState();
}

class _TitleGateState extends ConsumerState<TitleGate> {
  late final GameSounds _sounds = ref.read(gameSoundsProvider);
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _sounds.titleOpened();
  }

  void _begin() {
    if (_gone) return;
    _gone = true;
    _sounds.uiTap();
    context.go(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // The whole frame is the way in; the button is its accessible, obvious form.
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _begin,
        child: TitleScreen(
          footer: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BrandSpace.xl),
            child: VividButton.play(
              label: TitleGate.prompt,
              expand: true,
              onPressed: _begin,
            ),
          ),
        ),
      ),
    ],
  );
}
