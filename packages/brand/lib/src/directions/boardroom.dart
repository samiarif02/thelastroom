import '../colors.dart';
import '../motion.dart';
import '../typography.dart';
import 'direction.dart';

/// Direction C, The Boardroom, the owner's pick (2026-10-30). Now a view over the real tokens
/// ([BrandColors], [ChapterGrade], [BrandType], [BrandMotion]) so `/dev/directions` keeps
/// running until brief 06b's `/dev/catalog` replaces it; then this file goes.
const CinematicDirection boardroom = CinematicDirection(
  id: 'boardroom',
  letter: 'C',
  name: 'The Boardroom',
  mood: 'Old money after hours: walnut, brass, tungsten lamps and a city out of focus.',
  references: 'Succession, Michael Clayton, The Godfather office scenes',
  palette: DirectionPalette(
    void_: BrandColors.void_,
    surface: BrandColors.surface,
    raised: BrandColors.surfaceRaised,
    line: BrandColors.line,
    textPrimary: BrandColors.textPrimary,
    textSecondary: BrandColors.textSecondary,
    paper: BrandColors.paper,
    ink: BrandColors.ink,
    inkSoft: BrandColors.inkSoft,
    redPen: BrandColors.redPen,
  ),
  grades: [
    DirectionGrade(
      name: 'Lobby',
      key: ChapterGrade.lobbyKey,
      shadow: ChapterGrade.lobbyShadow,
      tint: ChapterGrade.lobbyTint,
    ),
    DirectionGrade(
      name: 'Pressure',
      key: ChapterGrade.pressureKey,
      shadow: ChapterGrade.pressureShadow,
      tint: ChapterGrade.pressureTint,
    ),
    DirectionGrade(
      name: 'Final round',
      key: ChapterGrade.finalRoundKey,
      shadow: ChapterGrade.finalRoundShadow,
      tint: ChapterGrade.finalRoundTint,
    ),
  ],
  type: DirectionType(
    eyebrow: BrandType.eyebrow,
    titleCard: BrandType.titleCard,
    display: BrandType.display,
    body: BrandType.body,
    subtitle: BrandType.subtitle,
    speaker: BrandType.speaker,
    choice: BrandType.choice,
    label: BrandType.label,
    score: BrandType.score,
    stamp: BrandType.stamp,
    note: BrandType.note,
  ),
  motion: DirectionMotion(
    letterbox: BrandMotion.letterbox,
    letterboxCurve: BrandMotion.letterboxCurve,
    cut: BrandMotion.dolly,
    cutCurve: BrandMotion.dollyCurve,
    perCharacter: BrandMotion.perCharacter,
    titleCard: BrandMotion.titleCard,
    dossierSlide: BrandMotion.dossierSlide,
    dossierCurve: BrandMotion.paperSlide,
  ),
);
