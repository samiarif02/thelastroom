import 'package:content/content.dart';
import 'package:engine/engine.dart' show ReasonVerdict, missionXp, reasonXp;
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/debrief/debrief_view.dart';
import 'package:the_last_room/features/debrief/red_pen_slip.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/scene/epilogue_scene.dart';
import 'package:the_last_room/features/mission/scene/room_intro.dart';
import 'package:the_last_room/features/mission/widgets/next_control.dart';
import 'package:the_last_room/features/progress/chapter_report_screen.dart';
import 'package:the_last_room/features/progression/debrief_rewards.dart';
import 'package:the_last_room/features/progression/floor_cleared_screen.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/features/voice/audio/take_playback.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/features/voice/voice_debrief.dart';
import 'package:the_last_room/features/voice/voice_player.dart';
import 'package:the_last_room/features/voice/voice_providers.dart';
import 'package:the_last_room/features/voice/voice_scoring.dart';
import 'package:the_last_room/features/voice/widgets/self_check_panel.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart' show TactileButton;
import 'package:the_last_room/ui/film_kit.dart';

import '../../core/backend/fakes.dart' show FakeBackend, keyedEnv;
import '../mission/mission_harness.dart';
import '../voice/voice_fixture.dart';

/// Brief 44: every mission in the campaign, booted by its route and played through the real UI
/// to its debrief, then on to the tower (or the report, or the epilogue). Choice missions play
/// their beats, "why" steps, built answers and the follow-up; voice missions hear their lines
/// spoken, record both takes on a fake microphone and are scored by a fake AI verdict and,
/// separately, offline by the self-check.
void main() {
  _reportRule();

  for (final m in missions) {
    if (m.answerMode == AnswerMode.choices) {
      testWidgets('Mission ${m.number}, ${m.title}: choices to the debrief', (
        tester,
      ) async {
        final rig = await _bootAt(tester, m);
        await _playChoices(rig, m);
        await _afterDebrief(rig, m, button: _debriefButton);
      });
    } else {
      for (final online in [true, false]) {
        testWidgets('Mission ${m.number}, ${m.title}: spoken, scored '
            '${online ? 'by the AI' : 'offline by the self-check'}', (
          tester,
        ) async {
          final voice = _VoiceFakes(online: online);
          final rig = await _bootAt(tester, m, voice: voice);
          await _playVoice(rig, m, voice);
          await _afterDebrief(rig, m, button: _voiceDebriefButton);
        });
      }
    }
  }

  group('one mission per chapter at 2x text and reduced motion', () {
    for (final number in _samples) {
      testWidgets('Mission $number', (tester) async {
        final m = missionByNumber(number)!;
        final voice = _VoiceFakes();
        final rig = await _bootAt(
          tester,
          m,
          voice: voice,
          textScale: 2,
          reduceMotion: true,
        );
        if (m.voice == null) {
          await _playChoices(rig, m);
          await _afterDebrief(rig, m, button: _debriefButton);
        } else {
          await _playVoice(rig, m, voice);
          await _afterDebrief(rig, m, button: _voiceDebriefButton);
        }
      });
    }
  });

  testWidgets('two missions in one sitting: each debrief shows its own XP', (
    tester,
  ) async {
    final first = missionByNumber(2)!;
    final second = missionByNumber(3)!;
    final rig = await _bootAt(tester, first);
    await _playChoices(rig, first);
    await _afterDebrief(rig, first, button: _debriefButton);
    rig.container.read(routerProvider).go(Routes.mission(second.number));
    await _playChoices(rig, second);
  });

  testWidgets(
    'Mission 7 → its epilogue → the Chapter 1 report → "Start Chapter 2" opens Mission 8',
    (tester) async {
      final review = missions.lastWhere((m) => m.chapter == 1);
      final rig = await _bootAt(tester, review, voice: _VoiceFakes());
      await _playChoices(rig, review);
      await _tapButton(rig, DebriefView.reportLabel);
      await _playEpilogue(rig, review);
      final done = find.descendant(
        of: find.byType(EpilogueScene),
        matching: find.text(DebriefView.reportLabel),
      );
      await rig.until(done);
      await tester.tap(done);
      await tester.pump();
      await rig.throughFloorCleared();
      await rig.until(find.text(ChapterReportScreen.honest));
      // The report slides in over the reward, which has its own "Take the lift" button:
      // tap the report's once the reward has gone.
      await _until(rig, find.byType(FloorClearedScreen), absent: true);
      final second = chapters.firstWhere((c) => c.number == 2);
      await _tapButton(rig, ChapterReportScreen.start(second));
      await rig.until(find.byType(VoicePlayer));
      final opened = tester.widget<VoicePlayer>(find.byType(VoicePlayer));
      expect(opened.number, missions.firstWhere((m) => m.chapter == 2).number);
      await rig.until(find.text(RoomIntro.start));
    },
  );
}

/// Only Chapter 1's review has a report; Missions 14 and 21 close their chapters on the tower.
void _reportRule() => test('only Mission 7 leads to a chapter report', () {
  expect(
    [
      for (final m in missions)
        if (m.closesChapter) m.number,
    ],
    [7, 14, 21],
  );
  expect(
    [
      for (final m in missions)
        if (m.leadsToReport) m.number,
    ],
    [7],
  );
});

/// One mission of each chapter (both kinds in Chapter 3), replayed at 2x text with reduced
/// motion: Mission 4 (a built answer), Mission 11 (voice), Mission 15 (choices with a built
/// answer) and Mission 21 (voice, the last room, its epilogue).
const List<int> _samples = [4, 11, 15, 21];

/// The voice mission's microphone, interviewer voice and scorer, as the voice rig fakes them.
class _VoiceFakes {
  _VoiceFakes({this.online = false});

  final bool online;
  final RecordingVoice voice = RecordingVoice();
  final FakeBackend backend = FakeBackend();
  final List<FakeMicrophone> mics = [];

  FakeMicrophone get mic => mics.last;
}

Future<MissionRig> _bootAt(
  WidgetTester tester,
  Mission m, {
  _VoiceFakes? voice,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  final rig = MissionRig(tester);
  await rig.unlockThrough(m.number);
  final fakes = voice ?? _VoiceFakes();
  final log = Log(sink: (_) {});
  rig.overrides.addAll([
    logProvider.overrideWithValue(log),
    microphoneFactoryProvider.overrideWithValue(() {
      final mic = FakeMicrophone();
      fakes.mics.add(mic);
      return mic;
    }),
    interviewerVoiceProvider.overrideWithValue(fakes.voice),
    takePlaybackProvider.overrideWithValue(SilentTakePlayback()),
    progressionStoreProvider.overrideWithValue(InMemoryProgressionStore()),
    if (fakes.online)
      voiceScorerProvider.overrideWithValue(
        VoiceScorer(
          env: keyedEnv,
          session: const GuestSession(userId: FakeBackend.guestId),
          backend: () => fakes.backend,
          log: log,
        ),
      ),
  ]);
  if (fakes.online) {
    fakes.backend.voiceScorer = (_) async => _verdict(m);
  }
  await rig.boot(
    Routes.mission(m.number),
    textScale: textScale,
    reduceMotion: reduceMotion,
  );
  return rig;
}

/// A choice mission from its card to the settled dossier: the lines, the draft (skipped), each
/// beat (the first line, or the strong build), its "why", the follow-up and its first reply.
Future<void> _playChoices(MissionRig rig, Mission m) async {
  await rig.until(find.byType(MissionPlayer));
  await rig.playLines(m.number);
  if (m.offersDraft) await rig.skipDraft();
  for (final b in m.beats) {
    await rig.say(
      m.optionById(b.build?.strongAnswer.id ?? b.options.first.id)!,
    );
  }
  final line = rig.state(m.number).followUpLine!;
  await rig.until(find.text(line.text));
  await rig.run(const Duration(milliseconds: 300));
  if (rig.typing) await rig.tapScene();
  await rig.say(rig.state(m.number).followUp!.replies.first);
  await rig.until(find.byType(Dossier));
  await rig.settleDossier();

  // The dossier shows the engine's score, then a lesson or a clean run.
  final score = rig.state(m.number).score!;
  expect(rig.tester.widget<Dossier>(find.byType(Dossier)).total, score.total);
  expect(
    find.byType(RedPenSlip).evaluate().length +
        find.byType(CleanRunSlip).evaluate().length +
        find.byType(GuessedSlip).evaluate().length,
    1,
  );

  // Every why step was answered after reading, so each earns its reason XP (brief 55); a
  // built beat asks none.
  expect(
    score.reasonVerdicts,
    hasLength(m.beats.where((b) => b.asksWhy).length),
  );
  expect(score.reasonVerdicts, isNot(contains(ReasonVerdict.guessed)));

  // Stored: one attempt, with the dossier's score.
  final stored = await rig.progress.attempts(missionId: m.id);
  expect(stored, hasLength(1));
  expect(stored.single.score.total, score.total);
  expect(stored.single.score.reasonVerdicts, score.reasonVerdicts);
  await _expectXp(rig, stored.single);
}

/// The debrief's "+N XP" is this attempt's, the room and its reasons (or spoken points), though
/// the tower (and its progress card) stayed mounted under the mission the whole time; the
/// breakdown beside it adds up to it.
Future<void> _expectXp(MissionRig rig, AttemptRecord attempt) async {
  await rig.run(const Duration(milliseconds: 500));
  final room = missionXp(total: attempt.score.total, firstClear: true);
  final reasons = reasonXp(attempt.score);
  expect(reasons, greaterThan(0));
  final xp = find.text(DebriefRewards.xpGained(room + reasons));
  await rig.tester.ensureVisible(xp);
  expect(xp, findsOneWidget);
  expect(
    find.text(
      DebriefRewards.xpBreakdown(
        room: room,
        reasons: reasons,
        spoken: attempt.voice != null,
      ),
    ),
    findsOneWidget,
  );
}

/// A voice mission from its card to the settled debrief: each line typed and spoken, the
/// answer and the reply recorded, then the AI's verdict or the self-check (two points ticked).
Future<void> _playVoice(MissionRig rig, Mission m, _VoiceFakes fakes) async {
  final tester = rig.tester;
  final voice = m.voice!;
  await rig.until(find.byType(VoicePlayer));
  await rig.startInterview();
  await _ready(rig);
  await _record(rig, fakes, const Duration(seconds: 3));
  await _until(rig, find.text(RecorderPanel.readyLine), absent: true);
  await _ready(rig);
  await _record(rig, fakes, const Duration(seconds: 2));

  // Every interviewer line was spoken, addressed to the player.
  expect(fakes.voice.said, [
    for (final line in [...m.scene, m.question, voice.followUp])
      line.addressedTo(testName).text,
  ]);

  final List<String> made;
  if (fakes.online) {
    await rig.until(find.text(HeardSlip.heading));
    made = _verdictPoints(m);
    expect(fakes.backend.voiceScoreRequests.single['mission_id'], m.id);
  } else {
    await rig.until(find.text(SelfCheckPanel.title));
    made = [voice.listenFor.first.id, voice.followUpListenFor.first.id];
    for (final id in made) {
      final point = [
        ...voice.listenFor,
        ...voice.followUpListenFor,
      ].firstWhere((p) => p.id == id);
      await _tap(rig, find.text(point.text));
    }
    await _tap(rig, find.text(SelfCheckPanel.score));
  }
  await rig.until(find.byType(VoiceDebrief));
  await rig.run(const Duration(seconds: 8));

  // The debrief: the score's source, a total, and the mission's lesson.
  expect(
    find.text(
      fakes.online ? ScoreSourceLabel.aiLabel : VoiceDebrief.selfCheckLabel,
    ),
    findsOneWidget,
  );
  final dossier = tester.widget<Dossier>(find.byType(Dossier));
  expect(dossier.total, fakes.online ? _aiOverall : isNonNegative);
  expect(find.byType(VoiceLessonSlip), findsOneWidget);
  expect(find.text(lessonById(voice.lessonId)!.title), findsWidgets);

  // Stored: one voice attempt with the points made.
  final stored = await rig.progress.attempts(missionId: m.id);
  expect(stored, hasLength(1));
  expect(stored.single.voice!.madePointIds, made);
  expect(
    stored.single.voice!.source,
    fakes.online ? VoiceScoreSource.ai : VoiceScoreSource.selfCheck,
  );
  await _expectXp(rig, stored.single);
}

/// Waits for the recorder, scrolls it into view (at 2x text on a small phone the lower third
/// scrolls) and checks nothing covers it.
Future<void> _ready(MissionRig rig) async {
  final ready = find.text(RecorderPanel.readyLine);
  await rig.until(ready);
  await rig.tester.ensureVisible(ready);
  await rig.tester.pump();
  await rig.until(ready.hitTestable());
}

Future<void> _record(MissionRig rig, _VoiceFakes fakes, Duration length) async {
  await _tap(rig, find.bySemanticsLabel(RecorderPanel.recordLabel));
  fakes.mic.speak(length);
  await rig.tester.pump();
  await _tap(rig, find.text(RecorderPanel.done));
}

/// After the debrief: its button, the epilogue where the mission has one, then the tower with
/// this room lit and the next one open, or the report for Mission 7.
Future<void> _afterDebrief(
  MissionRig rig,
  Mission m, {
  required String Function(Mission) button,
}) async {
  // A chapter's last mission, first time through, reports the chapter completed.
  final completed = rig.analytics.events
      .where((e) => e.event == AnalyticsEvent.chapterCompleted)
      .toList();
  expect(completed, hasLength(m.closesChapter ? 1 : 0));
  if (m.closesChapter) expect(completed.single.wire['chapter'], m.chapter);
  await _tapButton(rig, button(m));
  if (m.epilogue.isNotEmpty) {
    await _playEpilogue(rig, m);
    final done = find.descendant(
      of: find.byType(EpilogueScene),
      matching: find.byType(TactileButton),
    );
    await rig.until(done);
    await rig.tester.tap(done);
    await rig.tester.pump();
  }
  // A floor's last room, first time through: floor cleared (brief 46), then on.
  if (m.closesChapter) await rig.throughFloorCleared();
  if (m.number == _reviewNumber) {
    await rig.until(find.text(ChapterReportScreen.honest));
    return;
  }
  await rig.until(find.byType(TowerScreen));
  expect(
    rig.tester.widget<TowerScreen>(find.byType(TowerScreen)).lit,
    m.number,
  );
  await rig.run(const Duration(seconds: 3));
  expect(
    find.bySemanticsLabel(RegExp('^Room ${m.number}, .*lit, best')),
    findsOneWidget,
  );
  if (m.next case final next?) {
    expect(
      find.bySemanticsLabel('Room ${next.number}, ${next.title}. Play.'),
      findsOneWidget,
    );
  } else {
    // The last room: every room is done, none is locked, the top floor is lit.
    expect(find.bySemanticsLabel(RegExp(r', locked: ')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('^Floor 3 · .* 7 of 7 rooms lit')),
      findsOneWidget,
    );
  }
}

/// Mission 7, the review: its debrief leads to the Chapter 1 report.
final int _reviewNumber = missions.lastWhere((m) => m.chapter == 1).number;

String _debriefButton(Mission m) => m.number == _reviewNumber
    ? DebriefView.reportLabel
    : DebriefView.continueLabel;

String _voiceDebriefButton(Mission m) => _debriefButton(m);

Future<void> _playEpilogue(MissionRig rig, Mission m) async {
  await rig.until(find.byType(EpilogueScene));
  for (final line in m.epilogue) {
    await rig.until(find.text(line.addressedTo(testName).text));
    if (line == m.epilogue.last) break;
    await rig.until(find.byType(NextControl));
    await rig.tester.tap(find.byType(NextControl));
    await rig.tester.pump();
  }
}

/// A button by its label: Daylight's, or the vivid one on the screens still to restyle.
Future<void> _tapButton(MissionRig rig, String label) => _tap(
  rig,
  find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (w) => w is TactileButton || w is VividButton,
    ),
  ),
);

Future<void> _tap(MissionRig rig, Finder finder) async {
  await rig.until(finder);
  await rig.tester.ensureVisible(finder.first);
  await rig.tester.pump();
  await rig.tester.tap(finder.first);
  await rig.tester.pump();
  await rig.tester.pump();
  expect(rig.tester.takeException(), isNull);
}

/// [MissionRig.until], or until [finder] finds nothing.
Future<void> _until(
  MissionRig rig,
  Finder finder, {
  bool absent = false,
}) async {
  const step = Duration(milliseconds: 100);
  for (var e = Duration.zero; e < const Duration(seconds: 30); e += step) {
    if (finder.evaluate().isNotEmpty != absent) return;
    await rig.tester.pump(step);
    expect(rig.tester.takeException(), isNull, reason: 'at $e');
  }
  fail('timed out waiting for $finder${absent ? ' to go' : ''}');
}

/// The AI's overall score in every fake verdict.
const int _aiOverall = 64;

/// The points the fake AI says were made: the question's first and the follow-up's first.
List<String> _verdictPoints(Mission m) => [
  m.voice!.listenFor.first.id,
  m.voice!.followUpListenFor.first.id,
];

/// What `score-voice` answers for [m]: two points made, a transcript, every dimension.
Map<String, Object?> _verdict(Mission m) => {
  'model': 'gemini-3.8-flash',
  'transcript': {
    'answer': 'I said what happened, what I did, and how it ended.',
    'reply': 'I would ask sooner next time.',
  },
  'points_made': [..._verdictPoints(m), 'not_a_point'],
  'overall': {'score': _aiOverall, 'basis': 'Clear, with one point missed.'},
  'dimensions': {
    for (final name in [
      'relevance',
      'specificity',
      'structure',
      'adaptability',
    ])
      name: {'score': 60, 'basis': 'Some of it landed.'},
  },
};
