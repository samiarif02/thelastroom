import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'direction.dart';

const String _display = 'InstrumentSerif';
const String _sans = 'Geist';
const String _package = 'brand';

const Color _void = Color(0xFF04060A);
const Color _surface = Color(0xFF080B11);
const Color _raised = Color(0xFF10151D);
const Color _line = Color(0xFF232B36);
const Color _textPrimary = Color(0xFFE6EBF0);
const Color _textSecondary = Color(0xFF8F9BA8);
const Color _paper = Color(0xFFE4E7EA);
const Color _ink = Color(0xFF12161C);
const Color _inkSoft = Color(0xFF4A5260);
const Color _redPen = Color(0xFFB8291F);
const Color _lobbyKey = Color(0xFFE8B169);

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

/// Direction A: quiet glass-and-night minimalism. Instrument Serif + Geist.
const CinematicDirection nightGlass = CinematicDirection(
  id: 'night-glass',
  letter: 'A',
  name: 'Night Glass',
  mood: 'A glass tower at 3 a.m.: cold, hushed, perfectly still, and watching you.',
  references: 'Severance, A24 title cards, Michael Mann night exteriors',
  palette: _palette,
  grades: [
    DirectionGrade(
      name: 'Lobby',
      key: _lobbyKey,
      shadow: Color(0xFF120C06),
      tint: Color(0xFF3A2A16),
    ),
    DirectionGrade(
      name: 'Pressure',
      key: Color(0xFF8FB3D9),
      shadow: Color(0xFF060B12),
      tint: Color(0xFF1B2A3C),
    ),
    DirectionGrade(
      name: 'Final round',
      key: Color(0xFFD4B36A),
      shadow: Color(0xFF16070A),
      tint: Color(0xFF4A1218),
    ),
  ],
  type: DirectionType(
    eyebrow: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 11,
      height: 1.4,
      letterSpacing: 4,
      fontWeight: FontWeight.w500,
      color: _textSecondary,
    ),
    titleCard: TextStyle(
      fontFamily: _display,
      package: _package,
      fontStyle: FontStyle.italic,
      fontSize: 54,
      height: 1.02,
      letterSpacing: -0.8,
      color: _textPrimary,
    ),
    display: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 34,
      height: 1.1,
      letterSpacing: -0.3,
      color: _textPrimary,
    ),
    body: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 15,
      height: 1.55,
      color: _textPrimary,
    ),
    subtitle: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 17,
      height: 1.5,
      letterSpacing: 0.1,
      color: _textPrimary,
    ),
    speaker: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 10.5,
      height: 1.4,
      letterSpacing: 3.2,
      fontWeight: FontWeight.w500,
      color: _lobbyKey,
    ),
    choice: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 15,
      height: 1.45,
      color: _textPrimary,
    ),
    label: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 10.5,
      height: 1.4,
      letterSpacing: 2.6,
      fontWeight: FontWeight.w500,
      color: _textSecondary,
    ),
    score: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 40,
      height: 1,
      letterSpacing: -1.6,
      fontWeight: FontWeight.w400,
      fontFeatures: [FontFeature.tabularFigures()],
      color: _ink,
    ),
    stamp: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 9,
      height: 1,
      letterSpacing: 2.4,
      fontWeight: FontWeight.w500,
      color: _ink,
    ),
    note: TextStyle(
      fontFamily: _display,
      package: _package,
      fontStyle: FontStyle.italic,
      fontSize: 22,
      height: 1.15,
      color: _redPen,
    ),
  ),
  // Long dissolves, slow focus pulls. Nothing snaps.
  motion: DirectionMotion(
    letterbox: Duration(milliseconds: 1400),
    letterboxCurve: Cubic(0.33, 0, 0.1, 1),
    cut: Duration(milliseconds: 1600),
    cutCurve: Cubic(0.45, 0, 0.15, 1),
    perCharacter: Duration(milliseconds: 34),
    titleCard: Duration(milliseconds: 4200),
    dossierSlide: Duration(milliseconds: 1500),
    dossierCurve: Cubic(0.2, 0.9, 0.1, 1),
  ),
);
