import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the catalog shows every component: under reduced motion, at 2x text, in a grade.
@immutable
class CatalogSettings {
  const CatalogSettings({
    this.reduceMotion = false,
    this.largeText = false,
    this.grade = ChapterGrade.lobby,
  });

  final bool reduceMotion;
  final bool largeText;
  final ChapterGrade grade;

  static const double largeTextScale = 2;

  /// [base] with the catalog's toggles laid over it; a toggle that's off keeps the device's own
  /// setting.
  MediaQueryData apply(MediaQueryData base) => base.copyWith(
    disableAnimations: reduceMotion || base.disableAnimations,
    textScaler: largeText
        ? const TextScaler.linear(largeTextScale)
        : base.textScaler,
  );

  CatalogSettings copyWith({
    bool? reduceMotion,
    bool? largeText,
    ChapterGrade? grade,
  }) => CatalogSettings(
    reduceMotion: reduceMotion ?? this.reduceMotion,
    largeText: largeText ?? this.largeText,
    grade: grade ?? this.grade,
  );
}

final catalogSettingsProvider =
    NotifierProvider<CatalogSettingsNotifier, CatalogSettings>(
      CatalogSettingsNotifier.new,
    );

class CatalogSettingsNotifier extends Notifier<CatalogSettings> {
  @override
  CatalogSettings build() => const CatalogSettings();

  void toggleReduceMotion() =>
      state = state.copyWith(reduceMotion: !state.reduceMotion);

  void toggleLargeText() => state = state.copyWith(largeText: !state.largeText);

  /// Lobby → pressure → final round → lobby.
  void nextGrade() {
    const grades = ChapterGrade.values;
    state = state.copyWith(
      grade: grades[(state.grade.index + 1) % grades.length],
    );
  }
}
