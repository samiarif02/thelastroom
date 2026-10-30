import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_settings.dart';

/// The Sound section of the Settings screen: the master switch and the two volumes. Embedded
/// by the Settings screen (a later brief) and by the `/dev/sound` board.
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
            style: BrandType.eyebrow.copyWith(color: grade.key),
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        _ToggleRow(
          label: masterLabel,
          value: settings.enabled,
          grade: grade,
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.grade,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ChapterGrade grade;
  final ValueChanged<bool> onChanged;

  static const double _trackWidth = 44;
  static const double _trackHeight = 24;
  static const double _knob = 16;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : BrandMotion.quick;
    return Semantics(
      toggled: value,
      label: label,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
            child: Row(
              children: [
                Expanded(child: Text(label, style: BrandType.body)),
                Text(
                  value ? 'ON' : 'OFF',
                  style: BrandType.label.copyWith(
                    color: value ? grade.key : BrandColors.textSecondary,
                  ),
                ),
                const SizedBox(width: BrandSpace.sm),
                AnimatedContainer(
                  duration: duration,
                  curve: BrandMotion.enter,
                  width: _trackWidth,
                  height: _trackHeight,
                  padding: const EdgeInsets.all((_trackHeight - _knob) / 2 - 1),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: value
                        ? grade.key.withValues(alpha: 0.22)
                        : BrandColors.surface,
                    border: Border.all(
                      color: value ? grade.key : BrandColors.line,
                    ),
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: value ? grade.key : BrandColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: _knob),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  static const double _track = 2;
  static const double _thumb = 14;
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
                    Expanded(child: Text(label, style: BrandType.body)),
                    Text(
                      percent,
                      style: BrandType.numeral.copyWith(color: grade.key),
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
                            key: grade.key,
                            track: BrandColors.line,
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
    final line = Paint()..strokeWidth = trackHeight;
    canvas
      ..drawLine(Offset(0, y), Offset(size.width, y), line..color = track)
      ..drawLine(Offset(0, y), Offset(x, y), line..color = key)
      ..drawCircle(Offset(x, y), thumb / 2, Paint()..color = key);
  }

  @override
  bool shouldRepaint(_VolumePainter old) =>
      old.value != value || old.key != key || old.track != track;
}
