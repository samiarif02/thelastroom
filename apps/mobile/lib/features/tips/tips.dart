import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';

/// The first-time tips (the owner: contextual tips, not a full tour): one short line from the
/// cast, shown once, the first time the player reaches that moment. Sent as its name in
/// `tip_shown` and `tip_done` (`towerDoor`, `answerCards`, …).
enum Tip {
  /// The first tower visit: the door to play.
  towerDoor,

  /// The first answer cards in a choice room.
  answerCards,

  /// The first "Why that…?" step.
  whyStep,

  /// The first debrief, below the Candidate assessment, once its timeline has finished.
  firstResult,

  /// The first voice room's recorder.
  voiceMic,

  /// The first time a Recall note is due: the Recall tab.
  recallDue,

  /// Back on the tower after the first finished room: the Skills tab.
  yourFile;

  /// What the cast says, in one short sentence.
  String get line => switch (this) {
    Tip.towerDoor =>
      'This is your first room. Tap the door to start your interview.',
    Tip.answerCards => "Pick the line you'd really say, then lock it in.",
    Tip.whyStep => 'Now tell me why. This is where the points are.',
    Tip.firstResult =>
      'Your weakest skill is underlined in red. '
          'Tap “How we scored this” to see why.',
    Tip.voiceMic => "Tap to talk. I'll pause if you go quiet for 5 seconds.",
    Tip.recallDue => 'I left you a note in Recall.',
    Tip.yourFile => 'Every room you play is kept here.',
  };

  /// The first result's tip when the red pen marks nothing (a clean run): it can't point at an
  /// underline that isn't there (QA 51, BUG-3).
  static const String firstResultUnmarked =
      'Tap “How we scored this” to see how each score was reached.';

  /// The Recall tip for [due] notes taking about [minutes] ([recallMinutes]): the same count
  /// and time as the Recall card beside it.
  static String recallDueLine(int due, int minutes) {
    final notes = due == 1 ? 'a note' : '$due notes';
    final time = minutes <= 1 ? 'About a minute.' : 'About $minutes minutes.';
    return 'I left you $notes in Recall. $time';
  }

  /// The door tip once rooms are played (after "Show tips again"): it isn't the first room.
  static const String nextDoorLine =
      'This is your next room. Tap the door to start your interview.';
}

/// How a tip went away (`tip_done`'s `action`): its target was tapped (an action target does
/// its normal action; a choice target only puts the tip away, nothing picked), or it was
/// dismissed ("Got it", or a tap anywhere else).
enum TipAction { followed, dismissed }

/// Which tips have been seen, on the device (offline, like the last visit).
abstract interface class TipStore {
  Future<Set<Tip>> seen();
  Future<void> markSeen(Tip tip);
  Future<void> reset();
}

class SharedPreferencesTipStore implements TipStore {
  const SharedPreferencesTipStore();

  static const String prefix = 'tips.seen.';

  /// The tower tour's flag before the tips (brief 46): seen there is [Tip.towerDoor] seen.
  static const String legacyTour = 'tower.tourSeen';

  static String keyOf(Tip tip) => '$prefix${tip.name}';

  @override
  Future<Set<Tip>> seen() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final tip in Tip.values)
        if (prefs.getBool(keyOf(tip)) ?? false) tip,
      if (prefs.getBool(legacyTour) ?? false) Tip.towerDoor,
    };
  }

  @override
  Future<void> markSeen(Tip tip) async =>
      (await SharedPreferences.getInstance()).setBool(keyOf(tip), true);

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyTour);
    for (final tip in Tip.values) {
      await prefs.remove(keyOf(tip));
    }
  }
}

final tipStoreProvider = Provider<TipStore>(
  (ref) => const SharedPreferencesTipStore(),
);

/// The tips the player has seen, once they've been read from the device.
@immutable
class TipsState {
  const TipsState({this.loaded = false, this.seen = const {}});

  /// The flags have been read (or couldn't be, which counts as all seen).
  final bool loaded;
  final Set<Tip> seen;

  /// [tip] hasn't been seen: it may go up the next time its moment comes.
  bool due(Tip tip) => loaded && !seen.contains(tip);
}

/// The tips' flags, and the one tip on screen: only one overlay at a time, wherever it is.
final tipsProvider = NotifierProvider<TipsController, TipsState>(
  TipsController.new,
);

class TipsController extends Notifier<TipsState> {
  /// "Show tips again" was used this session: the tips shown after it are replays.
  bool _replay = false;

  /// `tip_shown` once per tip until the next reset, however often it's put back.
  final Set<Tip> _reported = {};

  /// The tip on screen now. A plain field, not state: claiming it never rebuilds a screen.
  Tip? _showing;

  /// Bumped by a reset, so a slow first read can't bring old flags back.
  int _reads = 0;

  @override
  TipsState build() {
    unawaited(_load());
    return const TipsState();
  }

  Future<void> _load() async {
    final read = ++_reads;
    Set<Tip> seen;
    try {
      seen = await ref.read(tipStoreProvider).seen();
    } on Object catch (e) {
      // A store that can't be read counts as all seen: never a tip that can't be put away.
      seen = Tip.values.toSet();
      if (ref.mounted) {
        ref.read(logProvider).warn('tip flags unreadable', {
          'error': e.runtimeType.toString(),
        });
      }
    }
    if (ref.mounted && read == _reads) {
      state = TipsState(loaded: true, seen: seen);
    }
  }

  /// The tip on screen, if any.
  Tip? get showing => _showing;

  /// Whether [tip] may go up now: not seen yet, and no other tip is on screen.
  bool canShow(Tip tip) =>
      state.due(tip) && (_showing == null || _showing == tip);

  /// [tip] goes up: true when it may (and `tip_shown` fires, once); false when it's been seen
  /// or another tip is on screen, and then the caller doesn't show it.
  bool shown(Tip tip) {
    if (!canShow(tip)) return false;
    _showing = tip;
    if (_reported.add(tip)) {
      ref.read(analyticsProvider).track(AnalyticsEvent.tipShown, {
        'tip': EventValue.name(tip),
        'replay': EventValue.flag(_replay),
      });
    }
    return true;
  }

  /// [tip] leaves the screen unseen (its screen closed, or its target went): it comes back the
  /// next time its moment does.
  void release(Tip tip) {
    if (_showing == tip) _showing = null;
  }

  /// [tip] is put away for good: seen, saved on the device, and `tip_done`.
  Future<void> done(Tip tip, TipAction action) async {
    release(tip);
    if (state.seen.contains(tip)) return;
    state = TipsState(loaded: true, seen: {...state.seen, tip});
    ref.read(analyticsProvider).track(AnalyticsEvent.tipDone, {
      'tip': EventValue.name(tip),
      'action': EventValue.name(action),
    });
    try {
      await ref.read(tipStoreProvider).markSeen(tip);
    } on Object catch (e) {
      if (ref.mounted) {
        ref.read(logProvider).warn('tip flag not saved', {
          'error': e.runtimeType.toString(),
        });
      }
    }
  }

  /// "Show tips again" in Settings: every tip is unseen again.
  Future<void> replayAll() async {
    _replay = true;
    _reported.clear();
    _showing = null;
    _reads++;
    try {
      await ref.read(tipStoreProvider).reset();
    } on Object catch (e) {
      ref.read(logProvider).warn('tip flags not reset', {
        'error': e.runtimeType.toString(),
      });
    }
    if (ref.mounted) state = const TipsState(loaded: true);
  }
}
