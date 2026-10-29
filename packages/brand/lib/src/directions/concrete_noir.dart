import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'direction.dart';

const String _display = 'BigShouldersDisplay';
const String _sans = 'InterTight';
const String _package = 'brand';

const Color _void = Color(0xFF050505);
const Color _surface = Color(0xFF0B0B0A);
const Color _raised = Color(0xFF161614);
const Color _line = Color(0xFF2E2D29);
const Color _textPrimary = Color(0xFFF1EBDD);
const Color _textSecondary = Color(0xFFA39D8F);
const Color _paper = Color(0xFFD8C8A2);
const Color _ink = Color(0xFF1A1712);
const Color _inkSoft = Color(0xFF4A4235);
const Color _redPen = Color(0xFF9E1F17);
const Color _lobbyKey = Color(0xFFF0A836);

const DirectionPalette _palette = DirectionPalette(
  void_: _void,
  surface: _surface,
  raised: _raised,
  line: _line,
  textPrimary: _textPrimary,
  textSecondary: _textSecondary,
  paper: _paper,
  ink: _ink,
  inkSoft: _inkSoft,
  redPen: _redPen,
);

/// Direction B: bold condensed neo-noir, big type as architecture. Big Shoulders Display +
/// Inter Tight.
const CinematicDirection concreteNoir = CinematicDirection(
  id: 'concrete-noir',
  letter: 'B',
  name: 'Concrete Noir',
  mood: 'An interrogation lit through blinds: hard light, hard cuts, words as tall as walls.',
  references: 'Fincher title sequences (Se7en, Zodiac, Mindhunter), Saul Bass',
  palette: _palette,
  grades: [
    DirectionGrade(
      name: 'Lobby',
      key: _lobbyKey,
      shadow: Color(0xFF140C02),
      tint: Color(0xFF3D2A0C),
    ),
    DirectionGrade(
      name: 'Pressure',
      key: Color(0xFF6FA0C8),
      shadow: Color(0xFF050A10),
      tint: Color(0xFF14283A),
    ),
    DirectionGrade(
      name: 'Final round',
      key: Color(0xFFD9B24C),
      shadow: Color(0xFF1A0405),
      tint: Color(0xFF7A1A1E),
    ),
  ],
  type: DirectionType(
    eyebrow: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 11,
      height: 1.3,
      letterSpacing: 2.2,
      fontWeight: FontWeight.w600,
      color: _lobbyKey,
    ),
    titleCard: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 112,
      height: 0.84,
      letterSpacing: -1,
      fontWeight: FontWeight.w800,
      color: _textPrimary,
    ),
    display: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 44,
      height: 0.9,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w800,
      color: _textPrimary,
    ),
    body: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 15,
      height: 1.45,
      color: _textPrimary,
    ),
    subtitle: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 18,
      height: 1.38,
      letterSpacing: -0.2,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    speaker: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 15,
      height: 1,
      letterSpacing: 3,
      fontWeight: FontWeight.w800,
      fontFeatures: [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
      color: _lobbyKey,
    ),
    choice: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 15,
      height: 1.4,
      color: _textPrimary,
    ),
    label: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 10.5,
      height: 1.3,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w600,
      color: _textSecondary,
    ),
    // Big Shoulders' figures are proportional, so scores use Inter Tight's tabular figures.
    score: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 44,
      height: 1,
      letterSpacing: -2,
      fontWeight: FontWeight.w600,
      fontFeatures: [FontFeature.tabularFigures()],
      color: _ink,
    ),
    stamp: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 15,
      height: 1,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w800,
      color: _redPen,
    ),
    note: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 24,
      height: 1,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w600,
      color: _redPen,
    ),
  ),
  // Hard cuts and snap moves that land heavily. Short, decisive.
  motion: DirectionMotion(
    letterbox: Duration(milliseconds: 520),
    letterboxCurve: Cubic(0.8, 0, 0.2, 1),
    cut: Duration(milliseconds: 380),
    cutCurve: Cubic(0.9, 0, 0.1, 1),
    perCharacter: Duration(milliseconds: 22),
    titleCard: Duration(milliseconds: 3000),
    dossierSlide: Duration(milliseconds: 700),
    dossierCurve: Cubic(0.7, 0, 0.1, 1),
  ),
);
