import 'package:flutter/services.dart';

// Haptics (brief §9: on choice, stamp and unlock). Sound is brief 09's; these are only touch.

/// The thud of a stamp or seal landing.
void stampThud() => HapticFeedback.heavyImpact();

/// A light tick when an answer is chosen.
void choiceTick() => HapticFeedback.selectionClick();

/// A light impact when a Daylight control is pressed.
void pressTap() => HapticFeedback.lightImpact();

/// A sound pick, a ring closing: medium, the moment of meaning.
void successTap() => HapticFeedback.mediumImpact();
