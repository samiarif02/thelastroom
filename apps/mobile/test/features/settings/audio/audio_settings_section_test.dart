import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/audio/audio_engine.dart';
import 'package:the_last_room/core/audio/audio_providers.dart';
import 'package:the_last_room/core/audio/audio_settings.dart';
import 'package:the_last_room/core/audio/cue.dart';
import 'package:the_last_room/core/audio/dev/sound_board_screen.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/features/settings/audio/audio_settings_section.dart';

import '../../../core/audio/fake_audio_engine.dart';

void main() {
  late ProviderContainer container;
  late FakeAudioEngine engine;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    engine = FakeAudioEngine();
    container = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(Log(sink: (_) {})),
        audioEngineProvider.overrideWithValue(engine as AudioEngine),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    Size size = const Size(375, 667),
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(style: BrandType.body, child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the defaults and toggles sound off', (tester) async {
    await pump(tester, const AudioSettingsSection());
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);

    await tester.tap(find.text(AudioSettingsSection.masterLabel));
    await tester.pump();
    expect(container.read(audioSettingsProvider).enabled, isFalse);
    expect(find.text('OFF'), findsOneWidget);
  });

  testWidgets('dragging a volume to the end sets it to 100%', (tester) async {
    await pump(tester, const AudioSettingsSection());
    final track = find.byType(CustomPaint).last;
    await tester.drag(track, const Offset(400, 0));
    await tester.pump();
    expect(container.read(audioSettingsProvider).effectsVolume, 1);
  });

  testWidgets('screen readers get a toggle and two sliders', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const AudioSettingsSection());
    expect(
      tester.getSemantics(find.bySemanticsLabel('Effects')),
      matchesSemantics(
        label: 'Effects',
        value: '80%',
        increasedValue: '90%',
        decreasedValue: '70%',
        isSlider: true,
        isEnabled: true,
        hasEnabledState: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('survives 2x text', (tester) async {
    await pump(tester, const AudioSettingsSection(), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sound board plays a cue once sound has started', (
    tester,
  ) async {
    await pump(tester, const SoundBoardScreen(), size: const Size(800, 4000));
    await tester.runAsync(container.read(audioServiceProvider).preload);
    await tester.pump();
    expect(find.textContaining('Sound is on'), findsOneWidget);

    await tester.tap(find.text(Cue.stamp.name));
    await tester.pump();
    expect(engine.cues, contains(Cue.stamp));

    await tester.tap(find.text(Cue.ambienceBoardroom.name).first);
    await tester.pump();
    expect(engine.live.where((p) => p.loop).single.cue, Cue.ambienceBoardroom);
  });
}
