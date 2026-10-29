import 'package:flutter/material.dart';

import 'colors.dart';
import 'motion.dart';
import 'typography.dart';

/// The app's [ThemeData]. Its job is mostly defensive: any Material widget that slips through
/// renders in brand colours with no ripple and no stock transitions, so nothing looks like a
/// default Material app (brief §9). Screens are built from our own components, not from this.
abstract final class BrandTheme {
  static ThemeData dark({ChapterGrade grade = ChapterGrade.lobby}) {
    final scheme = ColorScheme.dark(
      primary: grade.key,
      onPrimary: BrandColors.void_,
      secondary: grade.key,
      onSecondary: BrandColors.void_,
      surface: BrandColors.surface,
      onSurface: BrandColors.textPrimary,
      error: BrandColors.redPen,
      onError: BrandColors.textPrimary,
      outline: BrandColors.line,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: BrandColors.surface,
      canvasColor: BrandColors.surface,
      splashFactory: NoSplash.splashFactory,
      highlightColor: BrandColors.clear,
      splashColor: BrandColors.clear,
      hoverColor: grade.tint,
      focusColor: grade.tint,
      textTheme: const TextTheme(
        displayLarge: BrandType.titleCard,
        headlineMedium: BrandType.display,
        bodyLarge: BrandType.body,
        bodyMedium: BrandType.body,
        labelSmall: BrandType.label,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: grade.key,
        selectionColor: grade.tint,
        selectionHandleColor: grade.key,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeTransitionsBuilder(),
          TargetPlatform.iOS: _FadeTransitionsBuilder(),
          TargetPlatform.macOS: _FadeTransitionsBuilder(),
          TargetPlatform.linux: _FadeTransitionsBuilder(),
          TargetPlatform.windows: _FadeTransitionsBuilder(),
          TargetPlatform.fuchsia: _FadeTransitionsBuilder(),
        },
      ),
    );
  }
}

/// A plain cross-fade: the neutral default until the cinematic transitions (elevator, camera
/// cuts) are built. Also what reduced motion falls back to.
class _FadeTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeTransitionsBuilder();

  @override
  Duration get transitionDuration => BrandMotion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: BrandMotion.enter),
      child: child,
    );
  }
}
