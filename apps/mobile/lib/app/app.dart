import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/film_kit.dart';
import 'router.dart';
import 'vivid_theme.dart';

class TheLastRoomApp extends ConsumerWidget {
  const TheLastRoomApp({super.key});

  /// Marks every element below [context] to rebuild. Keys (go_router's navigator has a global
  /// one) and const widgets would otherwise keep their old colours after a theme change.
  static void _rebuildAll(BuildContext context) {
    void mark(Element e) {
      e
        ..markNeedsBuild()
        ..visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The look is Daylight (brief 46). The vivid tokens the screens Daylight leaves alone still
    // read (the debrief behind the kept dossier, the file, the report) follow the player's
    // earlier theme pick: set it before the tree builds, and rebuild every screen once it loads.
    final theme = ref.watch(themeProvider);
    BrandVivid.current = theme;
    ref.listen(themeProvider, (previous, next) {
      if (previous != next) _rebuildAll(context);
    });
    return MaterialApp.router(
      title: 'The Last Room',
      debugShowCheckedModeBanner: false,
      theme: DaylightTheme.light(),
      themeMode: ThemeMode.light,
      color: BrandColors.void_,
      routerConfig: ref.watch(routerProvider),
      // Screens are built without Scaffold/Material (no stock look), so a brand body style
      // must be the root default; otherwise Flutter's yellow-underline debug style shows.
      // Daylight screens set their own (`DaylightGround`). One ambient clock drives the film
      // grain the screens Daylight leaves alone still wear (`FilmGrain`).
      builder: (context, child) => EdgeToEdge(
        child: DefaultTextStyle(
          style: BrandType.body,
          child: AmbientClock(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Every frame is shot full-bleed: the scene draws under the status and navigation bars, which
/// are transparent (owner's phone review, 2026-10-30: no flat bands), with light icons over the
/// screens still on the dark sky. Daylight's light grounds turn them dark (`DaylightGround`).
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
