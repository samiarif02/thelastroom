import 'package:brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/film_kit.dart';
import 'router.dart';

class TheLastRoomApp extends ConsumerWidget {
  const TheLastRoomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'The Last Room',
      debugShowCheckedModeBanner: false,
      theme: BrandTheme.dark(),
      darkTheme: BrandTheme.dark(),
      themeMode: ThemeMode.dark,
      color: BrandColors.void_,
      routerConfig: ref.watch(routerProvider),
      // Screens are built without Scaffold/Material (no stock look), so the brand body style
      // must be the root default; otherwise Flutter's yellow-underline debug style shows.
      // Every frame is shot on the same film stock: one ambient clock, one grain + vignette.
      builder: (context, child) => DefaultTextStyle(
        style: BrandType.body,
        child: AmbientClock(
          child: FilmOverlay(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
