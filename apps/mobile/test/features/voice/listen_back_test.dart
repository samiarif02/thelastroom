import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/voice/audio/listen_back.dart';
import 'package:the_last_room/features/voice/audio/take_playback.dart';
import 'package:the_last_room/features/voice/recorder/take_recorder.dart';
import 'package:the_last_room/features/voice/voice_scoring.dart';
import 'package:the_last_room/features/voice/widgets/listen_tile.dart';
import 'package:the_last_room/features/voice/widgets/self_check_panel.dart';

import 'voice_fixture.dart';

Take _take(int seconds, {int bytes = 10}) => Take(
  wav: Uint8List(bytes),
  length: Duration(seconds: seconds),
  pausedCount: 0,
  retakes: 0,
);

const Duration _tick = ListenBack.defaultTick;

void main() {
  group('ListenBack', () {
    testWidgets('play, pause, resume from the paused place', (tester) async {
      final playback = SilentTakePlayback();
      final player = ListenBack(playback);
      final a = _take(42);

      expect(player.stateOf(a), ListenState.idle);
      await player.toggle(a);
      expect(player.stateOf(a), ListenState.playing);
      expect(playback.played, [10]);

      playback.at = const Duration(seconds: 7);
      await tester.pump(_tick);
      expect(player.positionOf(a), const Duration(seconds: 7));

      await player.toggle(a);
      expect(player.stateOf(a), ListenState.paused);
      expect(playback.pauses, 1);
      // Paused: the place holds, even if the engine's clock moves.
      playback.at = const Duration(seconds: 9);
      await tester.pump(_tick * 3);
      expect(player.positionOf(a), const Duration(seconds: 7));

      await player.toggle(a);
      expect(player.stateOf(a), ListenState.playing);
      expect(playback.resumes, 1);
      expect(playback.played, [10], reason: 'resumes, never restarts');
      await tester.pump(_tick);
      expect(player.positionOf(a), const Duration(seconds: 9));
      player.dispose();
    });

    testWidgets('the end of the clip resets to the start', (tester) async {
      final playback = SilentTakePlayback();
      final player = ListenBack(playback);
      final a = _take(5);

      await player.toggle(a);
      playback.at = const Duration(seconds: 5);
      await tester.pump(_tick);
      expect(player.stateOf(a), ListenState.idle);
      expect(player.positionOf(a), Duration.zero);
      expect(player.current, isNull);

      // A clip the engine dropped by itself (it played out) resets too.
      await player.toggle(a);
      playback.finish();
      await tester.pump(_tick);
      expect(player.stateOf(a), ListenState.idle);
      // And the next tap plays it again from the start.
      await player.toggle(a);
      expect(playback.played, [10, 10, 10]);
      player.dispose();
    });

    testWidgets('only one clip at a time', (tester) async {
      final playback = SilentTakePlayback();
      final player = ListenBack(playback);
      final a = _take(42);
      final b = _take(20, bytes: 20);

      await player.toggle(a);
      playback.at = const Duration(seconds: 3);
      await tester.pump(_tick);
      await player.toggle(b);
      expect(player.stateOf(a), ListenState.idle);
      expect(player.positionOf(a), Duration.zero);
      expect(player.stateOf(b), ListenState.playing);
      expect(player.current, same(b));
      expect(playback.played, [10, 20]);
      player.dispose();
    });

    testWidgets('dispose stops the sound and the clock', (tester) async {
      final playback = SilentTakePlayback();
      final player = ListenBack(playback);
      await player.toggle(_take(42));
      player.dispose();
      expect(playback.stops, 1);
      expect(playback.position, isNull);
      // No poll left running (the test would fail on a pending timer).
      await tester.pump(_tick * 2);
    });
  });

  group('ListenTile', () {
    test('says what a tap does', () {
      ListenTile tile(ListenState s, int at) => ListenTile(
        label: SelfCheckPanel.listenAnswer,
        clip: SelfCheckPanel.answerClip,
        state: s,
        position: Duration(seconds: at),
        length: const Duration(seconds: 42),
        onToggle: () {},
      );
      expect(tile(ListenState.idle, 0).action, 'Listen to your answer');
      expect(tile(ListenState.playing, 7).action, 'Pause');
      expect(tile(ListenState.paused, 7).action, 'Play from 0:07');
      expect(
        tile(ListenState.idle, 0).semantics,
        'Listen to your answer, 0:42',
      );
      expect(
        tile(ListenState.playing, 7).semantics,
        'Pause your answer. Playing, 0:07 of 0:42',
      );
      expect(
        tile(ListenState.paused, 67).semantics,
        'Play your answer from 1:07. Paused, 1:07 of 0:42',
      );
      expect(ListenTile.clock(const Duration(seconds: 125)), '2:05');
    });
  });

  group('the self-check player', () {
    Future<SilentTakePlayback> pumpPanel(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      final playback = SilentTakePlayback();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              child: SelfCheckPanel(
                reason: SelfCheckReason.noBackend,
                voice: voiceFixture.voice!,
                answer: _take(42),
                reply: _take(20, bytes: 20),
                playback: playback,
                onScore: (_) {},
              ),
            ),
          ),
        ),
      );
      return playback;
    }

    testWidgets('the tile toggles, shows the time, and one plays at a time', (
      tester,
    ) async {
      final playback = await pumpPanel(tester);
      expect(find.text('0:42'), findsOneWidget);
      expect(find.byType(Level), findsNothing);

      await tester.tap(find.text(SelfCheckPanel.listenAnswer));
      await tester.pump();
      expect(find.text(ListenTile.pause), findsOneWidget);
      expect(find.byType(Level), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Pause your answer. Playing')),
        findsOneWidget,
      );

      playback.at = const Duration(seconds: 7);
      await tester.pump(_tick);
      expect(find.text('0:07'), findsOneWidget);

      await tester.tap(find.text(ListenTile.pause));
      await tester.pump();
      expect(find.text('Play from 0:07'), findsOneWidget);
      expect(find.byType(Level), findsNothing);

      // The reply starts; the answer goes back to the start.
      await tester.tap(find.text(SelfCheckPanel.listenReply));
      await tester.pump();
      expect(find.text(SelfCheckPanel.listenAnswer), findsOneWidget);
      expect(find.text(ListenTile.pause), findsOneWidget);
      expect(playback.played, [10, 20]);

      // Leaving the screen stops it.
      final before = playback.stops;
      await tester.pumpWidget(const SizedBox());
      expect(playback.stops, before + 1);
    });

    testWidgets('reduced motion: the level is there, and still', (
      tester,
    ) async {
      await pumpPanel(tester, reduceMotion: true);
      await tester.tap(find.text(SelfCheckPanel.listenAnswer));
      await tester.pump();
      expect(find.byType(Level), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
