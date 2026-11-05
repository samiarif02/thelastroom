import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A whole number that counts from [from] up to [to] over [DaylightMotion.countUp] (the XP that
/// changed since the player last looked). Reduced motion, or nothing to count: just [to].
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.to,
    this.from,
    required this.style,
    this.suffix = '',
  });

  final int to;
  final int? from;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final start = from;
    final still =
        MediaQuery.disableAnimationsOf(context) || start == null || start >= to;
    final text = DaylightType.tabular(style);
    if (still) return Text('${groupThousands(to)}$suffix', style: text);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: start.toDouble(), end: to.toDouble()),
      duration: DaylightMotion.countUp,
      curve: DaylightMotion.ease,
      builder: (context, v, _) =>
          Text('${groupThousands(v.round())}$suffix', style: text),
    );
  }
}

/// "1,200": thousands grouped with a comma.
String groupThousands(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % _group == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

const int _group = 3;
