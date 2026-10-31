import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/back_to_exit.dart';
import '../../core/profile/profile_repository.dart';
import '../intro/title_gate.dart';
import '../tower/tower_screen.dart';

/// The app's front door: a returning player goes straight to the Tower; a new one gets the
/// title card, the welcome cards and onboarding. The profile loads from the device, so the
/// dark frame shows for a moment at most. A profile that fails to load counts as new.
class HomeGate extends ConsumerWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(profileProvider)) {
        AsyncData(:final value) when value.onboarded => const TowerScreen(),
        AsyncData() || AsyncError() => const BackToExit(child: TitleGate()),
        _ => const ColoredBox(color: BrandColors.void_),
      };
}
