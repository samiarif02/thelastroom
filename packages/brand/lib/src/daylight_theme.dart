import 'package:flutter/material.dart';

import 'colors.dart';
import 'daylight.dart';
import 'daylight_type.dart';

/// Daylight's [ThemeData]. Like the film theme, it is mostly defensive: screens are built from
/// the Daylight kit (`apps/mobile/lib/ui/daylight`), and anything Material that slips through
/// renders on paper, in ink and the floor's colour, with no ripple and no stock transition.
abstract final class DaylightTheme {
  static ThemeData light({ChapterGrade grade = ChapterGrade.lobby}) {
    final floor = grade.floor;
    final scheme = ColorScheme.light(
      primary: floor.base,
      secondary: DaylightColors.honey,
      onSecondary: DaylightColors.onHoney,
      surface: DaylightColors.paper,
      onSurface: DaylightColors.ink,
      onSurfaceVariant: DaylightColors.ink2,
      error: DaylightColors.trap,
      outline: DaylightColors.sand2,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: DaylightFonts.text,
      package: DaylightFonts.package,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: DaylightColors.paper,
      canvasColor: DaylightColors.paper,
      splashFactory: NoSplash.splashFactory,
      highlightColor: BrandColors.clear,
      splashColor: BrandColors.clear,
      hoverColor: floor.tint,
      focusColor: floor.tint,
      textTheme: TextTheme(
        displayLarge: DaylightType.heading2,
        displayMedium: DaylightType.heading3,
        displaySmall: DaylightType.heading4,
        headlineMedium: DaylightType.heading5,
        headlineSmall: DaylightType.heading6,
        titleLarge: DaylightType.title1,
        titleMedium: DaylightType.title3,
        titleSmall: DaylightType.title4,
        bodyLarge: DaylightType.body3,
        bodyMedium: DaylightType.body6,
        bodySmall: DaylightType.caption4,
        labelLarge: DaylightType.buttonMedium,
        labelMedium: DaylightType.caption3,
        labelSmall: DaylightType.caption4,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: floor.base,
        selectionColor: floor.soft,
        selectionHandleColor: floor.base,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _DaylightFade(),
          TargetPlatform.iOS: _DaylightFade(),
          TargetPlatform.macOS: _DaylightFade(),
          TargetPlatform.linux: _DaylightFade(),
          TargetPlatform.windows: _DaylightFade(),
          TargetPlatform.fuchsia: _DaylightFade(),
        },
      ),
    );
  }
}

/// A plain fade on the base curve between routes; screens choreograph their own entrances.
class _DaylightFade extends PageTransitionsBuilder {
  const _DaylightFade();

  @override
  Duration get transitionDuration => DaylightMotion.colour;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: DaylightMotion.ease),
    child: child,
  );
}
