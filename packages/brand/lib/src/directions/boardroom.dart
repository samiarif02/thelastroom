import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'direction.dart';

const String _display = 'CormorantGaramond';
const String _sans = 'Manrope';
const String _package = 'brand';

const Color _void = Color(0xFF0C0806);
const Color _surface = Color(0xFF140E0B);
const Color _raised = Color(0xFF1F1712);
const Color _line = Color(0xFF3A2D24);
const Color _textPrimary = Color(0xFFF3E7D3);
const Color _textSecondary = Color(0xFFBBA990);
const Color _paper = Color(0xFFF1E7D3);
const Color _ink = Color(0xFF2A1E16);
const Color _inkSoft = Color(0xFF65513F);
const Color _redPen = Color(0xFFA3201B);
const Color _lobbyKey = Color(0xFFE2AE62);

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

/// Direction C: warm, expensive boardroom drama. Cormorant Garamond + Manrope.
const CinematicDirection boardroom = CinematicDirection(
  id: 'boardroom',
  letter: 'C',
  name: 'The Boardroom',
  mood: 'Old money after hours: walnut, brass, tungsten lamps and a city out of focus.',
  references: 'Succession, Michael Clayton, The Godfather office scenes',
  palette: _palette,
  grades: [
    DirectionGrade(
      name: 'Lobby',
      key: _lobbyKey,
      shadow: Color(0xFF1B1009),
      tint: Color(0xFF5A3518),
    ),
    DirectionGrade(
      name: 'Pressure',
      key: Color(0xFF9DB4C8),
      shadow: Color(0xFF0D1218),
      tint: Color(0xFF2A3644),
    ),
    DirectionGrade(
      name: 'Final round',
      key: Color(0xFFCFAE5E),
      shadow: Color(0xFF22080B),
      tint: Color(0xFF6E1A20),
    ),
  ],
  type: DirectionType(
    eyebrow: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 10.5,
      height: 1.4,
      letterSpacing: 4.2,
      fontWeight: FontWeight.w600,
      color: _lobbyKey,
    ),
    titleCard: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 40,
      height: 1.15,
      letterSpacing: 7,
      fontWeight: FontWeight.w500,
      color: _textPrimary,
    ),
    display: TextStyle(
      fontFamily: _display,
      package: _package,
      fontStyle: FontStyle.italic,
      fontSize: 34,
      height: 1.1,
      fontWeight: FontWeight.w500,
      color: _textPrimary,
    ),
    body: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 15,
      height: 1.6,
      color: _textPrimary,
    ),
    subtitle: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: _textPrimary,
    ),
    speaker: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 17,
      height: 1.2,
      letterSpacing: 2.4,
      fontWeight: FontWeight.w600,
      fontFeatures: [FontFeature.enable('smcp')],
      color: _lobbyKey,
    ),
    choice: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 14.5,
      height: 1.5,
      color: _textPrimary,
    ),
    label: TextStyle(
      fontFamily: _sans,
      package: _package,
      fontSize: 10,
      height: 1.4,
      letterSpacing: 2.8,
      fontWeight: FontWeight.w600,
      color: _textSecondary,
    ),
    score: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 46,
      height: 1,
      fontWeight: FontWeight.w600,
      fontFeatures: [FontFeature.tabularFigures(), FontFeature.liningFigures()],
      color: _ink,
    ),
    stamp: TextStyle(
      fontFamily: _display,
      package: _package,
      fontSize: 12,
      height: 1,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
      color: _redPen,
    ),
    note: TextStyle(
      fontFamily: _display,
      package: _package,
      fontStyle: FontStyle.italic,
      fontSize: 24,
      height: 1.1,
      fontWeight: FontWeight.w500,
      color: _redPen,
    ),
  ),
  // Slow dolly pushes and long glides: money doesn't hurry.
  motion: DirectionMotion(
    letterbox: Duration(milliseconds: 1100),
    letterboxCurve: Cubic(0.6, 0, 0.2, 1),
    cut: Duration(milliseconds: 2200),
    cutCurve: Cubic(0.55, 0, 0.25, 1),
    perCharacter: Duration(milliseconds: 30),
    titleCard: Duration(milliseconds: 4600),
    dossierSlide: Duration(milliseconds: 1300),
    dossierCurve: Cubic(0.3, 0.8, 0.2, 1),
  ),
);
