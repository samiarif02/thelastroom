import 'package:flutter/services.dart';

/// The thud of a stamp landing (brief §9: haptics on choice, stamp and unlock).
void stampThud() => HapticFeedback.heavyImpact();
