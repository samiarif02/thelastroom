import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_settings.dart';
import '../../../ui/film_kit.dart';

/// The Sound section of the Settings screen: the master switch and the two volumes, in the
/// vivid look (brief 23: white on colour, sunflower for what's on). Embedded by the Settings
/// screen and by the `/dev/sound` board; it sits on a vivid panel or the sky.
class AudioSettingsSection extends ConsumerWidget {
  const AudioSettingsSection({super.key, this.grade = ChapterGrade.lobby});

  final ChapterGrade grade;

  static const String heading = 'SOUND';
  static const String masterLabel = 'Sound';
  static const String ambienceLabel = 'Ambience & music';
  static const String effectsLabel = 'Effects';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(audioSettingsProvider);
    final controller = ref.read(audioSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            heading,
            style: BrandVividType.kicker.copyWith(color: BrandVivid.accent),
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        VividToggle(
          label: masterLabel,
          value: settings.enabled,
          onChanged: controller.setEnabled,
        ),
        _VolumeRow(
          label: ambienceLabel,
          value: settings.ambienceVolume,
          enabled: settings.enabled,
          grade: grade,
          onChanged: controller.setAmbienceVolume,
        ),
        _VolumeRow(
          label: effectsLabel,
          value: settings.effectsVolume,
          enabled: settings.enabled,
          grade: grade,
          onChanged: controller.setEffectsVolume,
        ),
      ],
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.grade,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final ChapterGrade grade;
  final ValueChanged<double> onChanged;

  /// One step of the screen reader's increase/decrease actions.
  static const double step = 0.1;
  static const double _track = 4;
  static const double _thumb = 22;
  static const double _trackAlpha = 0.25;
  static const double _disabledOpacity = 0.45;

  void _setFrom(Offset local, double width) =>
      onChanged((local.dx / width).clamp(0, 1));

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).round()}%';
    return Semantics(
      slider: true,
      enabled: enabled,
      label: label,
      value: percent,
      increasedValue: '${((value + step).clamp(0, 1) * 100).round()}%',
      decreasedValue: '${((value - step).clamp(0, 1) * 100).round()}%',
      onIncrease: enabled ? () => onChanged((value + step).clamp(0, 1)) : null,
      onDecrease: enabled ? () => onChanged((value - step).clamp(0, 1)) : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : _disabledOpacity,
          child: Padding(
            padding: const EdgeInsets.only(top: BrandSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, style: BrandVividType.row)),
                    Text(
                      percent,
                      style: BrandVividType.row.copyWith(
                        color: BrandVivid.accent,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: enabled
                          ? (d) => _setFrom(d.localPosition, width)
                          : null,
                      onHorizontalDragUpdate: enabled
                          ? (d) => _setFrom(d.localPosition, width)
                          : null,
                      child: SizedBox(
                        height: BrandSpace.minTarget,
                        child: CustomPaint(
                          painter: _VolumePainter(
                            value: value,
                            key: BrandVivid.accent,
                            track: BrandVivid.hairline(_trackAlpha),
                            thumb: _thumb,
                            trackHeight: _track,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumePainter extends CustomPainter {
  const _VolumePainter({
    required this.value,
    required this.key,
    required this.track,
    required this.thumb,
    required this.trackHeight,
  });

  final double value;
  final Color key;
  final Color track;
  final double thumb;
  final double trackHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final x = (size.width * value).clamp(thumb / 2, size.width - thumb / 2);
    final line = Paint()
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(0, y), Offset(size.width, y), line..color = track)
      ..drawLine(Offset(0, y), Offset(x, y), line..color = key)
      ..drawCircle(Offset(x, y), thumb / 2, Paint()..color = BrandVivid.onDeep)
      ..drawCircle(
        Offset(x, y),
        thumb / 2,
        Paint()
          ..color = key
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackHeight,
      );
  }

  @override
  bool shouldRepaint(_VolumePainter old) =>
      old.value != value || old.key != key || old.track != track;
}
