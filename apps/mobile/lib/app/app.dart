import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      theme: BrandTheme.light(),
      themeMode: ThemeMode.light,
      color: BrandColors.void_,
      routerConfig: ref.watch(routerProvider),
      // Screens are built without Scaffold/Material (no stock look), so the brand body style
      // must be the root default; otherwise Flutter's yellow-underline debug style shows.
      // Every frame is shot on the same film stock: one ambient clock and its grain. The
      // vignette is each scene's, laid under its text (see FilmOverlay).
      builder: (context, child) => EdgeToEdge(
        child: DefaultTextStyle(
          style: BrandType.body,
          child: AmbientClock(
            child: FilmOverlay(
              vignette: 0,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every frame is shot full-bleed: the scene draws under the status and navigation bars, which
/// are transparent (owner's phone review, 2026-10-30: no flat bands), with light icons: every
/// screen is a dark sky now (lead's decision, 2026-11-01).
/// Screens keep their content clear of the bars with the view padding (`SafeArea`).
class EdgeToEdge extends StatefulWidget {
  const EdgeToEdge({super.key, required this.child});

  final Widget child;

  /// Transparent bars, light icons over the dark sky (on iOS `statusBarBrightness` names the
  /// background: dark).
  static const SystemUiOverlayStyle style = SystemUiOverlayStyle(
    statusBarColor: BrandColors.clear,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: BrandColors.clear,
    systemNavigationBarDividerColor: BrandColors.clear,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  @override
  State<EdgeToEdge> createState() => _EdgeToEdgeState();
}

class _EdgeToEdgeState extends State<EdgeToEdge> {
  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: EdgeToEdge.style,
    child: widget.child,
  );
}
