import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/analytics/analytics_event.dart';
import '../../../core/analytics/event_value.dart';
import '../../../core/backend/backend.dart';
import '../../../core/notifications/reminders.dart';
import '../../../core/profile/profile_repository.dart';
import '../../../core/sync/account_merge.dart';
import '../../../core/sync/outbox.dart';
import '../../recall/recall_store.dart';
import '../../tips/tips.dart';
import '../../tower/welcome_back.dart';
import 'player_data.dart';

/// Which of the card's two paths the player is on (FR-3).
enum AccountMode {
  /// "Save your progress": link an email to this device's guest. The id stays the same.
  link,

  /// "Sign in on another device": sign in to an account saved elsewhere; its rows come down.
  signIn,
}

/// How the player saved (`account_linked` / `account_signed_in`'s `provider`). Google is v2.
enum AccountProvider { email }

/// Where the card's flow is.
enum AccountStep {
  /// Typing the email.
  enterEmail,

  /// Asking the server to mail the link.
  sending,

  /// The link is on its way: the player taps it in their email, then comes back.
  linkSent,
}

/// The card's flow state. Whether there's a backend, a session or a linked email is read from
/// [envProvider] and [sessionProvider]; this is only the steps in between.
class AccountFlow {
  const AccountFlow({
    this.mode = AccountMode.link,
    this.step = AccountStep.enterEmail,
    this.email = '',
    this.failure,
    this.resent = false,
    this.canResend = true,
    this.signedInHere = false,
    this.signingOut = false,
    this.unsynced,
    this.signedOutHere = false,
  });

  final AccountMode mode;
  final AccountStep step;

  /// The address being saved to (shown on the card, never logged or tracked).
  final String email;

  /// What went wrong on the last step, shown under it; null when nothing did.
  final AccountFailure? failure;

  /// A new link was sent on request ("Resend link").
  final bool resent;

  /// "Resend link" is open: false for [resendCooldown] after each email, so a tap can't run
  /// into the server's one-email-a-minute limit.
  final bool canResend;

  /// This device just signed in to a saved account (the linked card says the file is coming).
  final bool signedInHere;

  /// "Sign out" is backing everything up, then signing out.
  final bool signingOut;

  /// "Sign out" was refused: this is what hadn't reached the server (the card says how many
  /// rooms, and to get online first). Null when nothing was refused.
  final PendingUploads? unsynced;

  /// This device just signed out: its player data is gone and a new guest is on the way. The
  /// card takes the player to the front door.
  final bool signedOutHere;

  bool get busy => step == AccountStep.sending;

  AccountFlow copyWith({
    AccountMode? mode,
    AccountStep? step,
    String? email,
    AccountFailure? failure,
    bool clearFailure = false,
    bool? resent,
    bool? canResend,
    bool? signedInHere,
  }) => AccountFlow(
    mode: mode ?? this.mode,
    step: step ?? this.step,
    email: email ?? this.email,
    failure: clearFailure ? null : failure ?? this.failure,
    resent: resent ?? this.resent,
    canResend: canResend ?? this.canResend,
    signedInHere: signedInHere ?? this.signedInHere,
  );
}

/// How long one account call may take before it counts as offline.
const Duration accountCallTimeout = Duration(seconds: 20);

/// While "Save your progress" waits for its link, the server is asked this often whether the
/// player has tapped it…
const Duration linkPollInterval = Duration(seconds: 5);

/// …for this long after the email went out (or the app came back to the foreground), then the
/// app waits for the next return to the foreground.
const Duration linkPollWindow = Duration(minutes: 3);

/// The wait before "Resend link" opens: the server sends one email a minute (ADR 0008).
const Duration resendCooldown = Duration(minutes: 1);

/// A plain shape check: something@something.tld. The server has the last word.
final RegExp _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// Readies this device for an account sign-in (FR-3): the local half of the merge. Returns
/// whether the device held progress of its own. Tests override it; nothing else touches the
/// database from here.
final accountDevicePrepProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final db = ref.read(databaseProvider);
    final hadProgress = await deviceHasProgress(db);
    final renamed = await prepareAccountMerge(db);
    if (renamed.isNotEmpty) {
      // The Recall Room remembers which attempts it has turned into cards by id: carry the new
      // ids over, so a re-keyed attempt doesn't send its cards back to box one.
      final store = ref.read(recallStoreProvider);
      final schedule = await store.load();
      await store.save(
        RecallSchedule(
          cards: schedule.cards,
          ingested: {for (final key in schedule.ingested) renamed[key] ?? key},
        ),
      );
    }
    return hadProgress;
  },
);

/// "Sign out"'s backup (FR-3): sends everything waiting now and returns what's still left.
/// Nothing left is the only way out; a slow answer counts what's left at that moment. Tests
/// override it.
final signOutBackupProvider = Provider<Future<PendingUploads> Function()>(
  (ref) => () async {
    final db = ref.read(databaseProvider);
    final worker = ref.read(syncWorkerProvider);
    if (worker != null) {
      try {
        return await worker.flushEverything().timeout(accountCallTimeout);
      } on TimeoutException {
        // Still sending: whatever hasn't gone yet blocks the sign-out.
      }
    }
    return Outbox(db).pending();
  },
);

/// Forgets the signed-out player on this device ([PlayerData.clear]). Tests override it.
final playerDataWipeProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => PlayerData.clear(ref.read(databaseProvider)),
);

/// The "Save your progress" card's controller (FR-3). Every backend call goes through
/// [Backend]; each failure is a typed [AccountFailure] the card has a state for.
final saveProgressProvider =
    NotifierProvider<SaveProgressController, AccountFlow>(
      SaveProgressController.new,
    );

class SaveProgressController extends Notifier<AccountFlow> {
  Timer? _poll;
  Timer? _cooldown;
  AppLifecycleListener? _lifecycle;
  bool _checking = false;

  @override
  AccountFlow build() {
    // Sign-in links arrive whenever they're opened, even on a cold start through the link, so
    // this listens for the app's lifetime (main.dart reads it at launch).
    final links = ref.read(backendProvider).accountLinks.listen(_onLink);
    ref.onDispose(() {
      unawaited(links.cancel());
      _stopWaiting();
      _cooldown?.cancel();
    });
    return const AccountFlow();
  }

  /// Switches between saving this device and signing in to a saved account.
  void useMode(AccountMode mode) {
    _stopWaiting();
    state = AccountFlow(mode: mode);
  }

  /// "Use a different email": back to the email step, keeping what was typed.
  void editEmail() {
    _stopWaiting();
    state = AccountFlow(mode: state.mode, email: state.email);
  }

  /// Mails a link to [raw]. A link the server makes at once (no email) goes straight to linked.
  Future<void> sendLink(String raw) async {
    if (state.busy) return;
    final email = raw.trim().toLowerCase();
    if (!_emailShape.hasMatch(email)) {
      state = AccountFlow(
        mode: state.mode,
        email: raw.trim(),
        failure: AccountFailure.invalidEmail,
      );
      return;
    }
    _stopWaiting();
    state = AccountFlow(
      mode: state.mode,
      step: AccountStep.sending,
      email: email,
    );
    await _sendTo(email, backToEmail: true);
  }

  /// "Resend link", from the link-sent step.
  Future<void> resend() async {
    if (state.step != AccountStep.linkSent || !state.canResend) return;
    _stopWaiting();
    state = state.copyWith(step: AccountStep.sending, clearFailure: true);
    await _sendTo(state.email, backToEmail: false, resent: true);
  }

  Future<void> _sendTo(
    String email, {
    required bool backToEmail,
    bool resent = false,
  }) async {
    final backend = ref.read(backendProvider);
    final mode = state.mode;
    try {
      if (mode == AccountMode.link) {
        final linked = await backend
            .sendLinkEmail(email)
            .timeout(accountCallTimeout);
        if (linked != null) {
          _linked(linked);
          return;
        }
      } else {
        await backend.sendSignInLink(email).timeout(accountCallTimeout);
      }
      if (!ref.mounted) return;
      state = AccountFlow(
        mode: mode,
        step: AccountStep.linkSent,
        email: email,
        resent: resent,
        canResend: false,
      );
      _startCooldown();
      if (mode == AccountMode.link) _startWaiting();
    } on AccountException catch (error) {
      _failed(error.failure, error.reason, backToEmail: backToEmail);
    } on TimeoutException {
      _failed(AccountFailure.offline, 'timeout', backToEmail: backToEmail);
    }
  }

  /// Asks the server whether the link has been tapped; linked when it has. A failure here
  /// (offline, a slow answer) is quiet: the next poll or return to the app asks again.
  Future<void> checkLink() async {
    if (_checking ||
        state.mode != AccountMode.link ||
        state.step != AccountStep.linkSent) {
      return;
    }
    _checking = true;
    try {
      final session = await ref
          .read(backendProvider)
          .refreshAccount()
          .timeout(accountCallTimeout);
      if (!ref.mounted || state.step != AccountStep.linkSent) return;
      if (session.isLinked) {
        _stopWaiting();
        _linked(session);
      }
    } on AccountException catch (error) {
      if (ref.mounted) {
        ref.read(logProvider).debug('link check failed', {
          'failure': error.failure.name,
          'reason': error.reason,
        });
      }
    } on TimeoutException {
      if (ref.mounted) {
        ref.read(logProvider).debug('link check failed', {'reason': 'timeout'});
      }
    } finally {
      _checking = false;
    }
  }

  /// Whether the app is asking the server every [linkPollInterval] (tests read it).
  bool get polling => _poll != null;

  /// Polls for [linkPollWindow], and again each time the app comes back to the foreground
  /// (the player tapped the link in their mail app or browser and switched back).
  void _startWaiting() {
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        _restartPoll();
        unawaited(checkLink());
      },
    );
    _restartPoll();
  }

  void _restartPoll() {
    _poll?.cancel();
    final polls =
        linkPollWindow.inMilliseconds ~/ linkPollInterval.inMilliseconds;
    _poll = Timer.periodic(linkPollInterval, (timer) {
      unawaited(checkLink());
      if (timer.tick >= polls) {
        timer.cancel();
        _poll = null;
      }
    });
  }

  void _stopWaiting() {
    _poll?.cancel();
    _poll = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  void _startCooldown() {
    _cooldown?.cancel();
    _cooldown = Timer(resendCooldown, () {
      if (ref.mounted && state.step == AccountStep.linkSent) {
        state = state.copyWith(canResend: true);
      }
    });
  }

  /// A sign-in link opened in the app: the account takes over (the merge readied first), or the
  /// link was refused and the card says so, wherever the flow was (a cold start through the link
  /// starts with a fresh flow).
  Future<void> _onLink(AccountLinkEvent event) async {
    if (!ref.mounted) return;
    switch (event) {
      case AccountLinkSignedIn(:final session, :final previousUserId):
        _stopWaiting();
        await _signedIn(session, previousUserId: previousUserId);
      case AccountLinkRefused(:final reason):
        _stopWaiting();
        ref.read(logProvider).warn('account step failed', {
          'mode': AccountMode.signIn.name,
          'failure': AccountFailure.linkExpired.name,
          'reason': reason,
        });
        final waiting =
            state.mode == AccountMode.signIn &&
            state.step == AccountStep.linkSent;
        state = waiting
            ? state.copyWith(failure: AccountFailure.linkExpired, resent: false)
            : AccountFlow(
                mode: AccountMode.signIn,
                email: state.email,
                failure: AccountFailure.linkExpired,
              );
    }
  }

  /// "Sign out" (FR-3), after the player confirmed it. Backs everything up first: anything that
  /// can't reach the server (offline, an error) blocks it, so no progress is ever lost. Then the
  /// session ends, this device's player data is cleared ([PlayerData]), and a new guest signs
  /// in: the next person on this phone starts fresh. The account stays saved to its email.
  Future<void> signOut() async {
    final session = ref.read(sessionProvider);
    if (state.signingOut || session is! GuestSession || !session.isLinked) {
      return;
    }
    _stopWaiting();
    _cooldown?.cancel();
    state = const AccountFlow(signingOut: true);
    final log = ref.read(logProvider);
    PendingUploads left;
    try {
      left = await ref.read(signOutBackupProvider)();
    } on Object catch (error) {
      log.warn('sign out backup failed', {'error': '${error.runtimeType}'});
      left = (rooms: 0, other: 1);
    }
    if (!ref.mounted) return;
    if (left.rooms + left.other > 0) {
      log.warn('sign out blocked', {'rooms': left.rooms, 'other': left.other});
      state = AccountFlow(unsynced: left);
      return;
    }
    try {
      await ref.read(backendProvider).signOut().timeout(accountCallTimeout);
    } on Object catch (error) {
      log.warn('sign out failed', {'error': '${error.runtimeType}'});
      if (ref.mounted) {
        state = const AccountFlow(failure: AccountFailure.unavailable);
      }
      return;
    }
    if (!ref.mounted) return;
    // The old session (and its sync worker) go first, so nothing writes while the data clears.
    final sessions = ref.read(sessionProvider.notifier)..signedOut();
    try {
      await ref.read(playerDataWipeProvider)();
    } on Object catch (error, stack) {
      // Signed out either way; a store that wouldn't clear is a bug to see, not a dead end.
      log.error('player data not cleared', error: error, stackTrace: stack);
    }
    if (!ref.mounted) return;
    // Everything read from the old player's data is read again, as a new player's.
    ref
      ..invalidate(profileProvider)
      ..invalidate(tipsProvider)
      ..invalidate(welcomeBackProvider);
    // The old player's reminders ("Room 5 is waiting") make way for a new player's.
    unawaited(ref.read(remindersProvider).reschedule());
    ref.read(analyticsProvider).track(AnalyticsEvent.accountSignedOut, {
      'had_unsynced': const EventValue.flag(false),
    });
    log.info('account signed out');
    state = const AccountFlow(signedOutHere: true);
    unawaited(sessions.start());
  }

  /// The card has taken the player on after a sign-out: back to a plain flow.
  void signOutSeen() {
    if (state.signedOutHere) state = const AccountFlow();
  }

  void _linked(GuestSession session) {
    if (!ref.mounted) return;
    ref.read(sessionProvider.notifier).signedIn(session);
    ref.read(analyticsProvider).track(AnalyticsEvent.accountLinked, {
      'provider': const EventValue.name(AccountProvider.email),
    });
    ref.read(logProvider).info('account linked');
    _cooldown?.cancel();
    state = const AccountFlow();
  }

  Future<void> _signedIn(
    GuestSession session, {
    required String? previousUserId,
  }) async {
    // A link that signs in to the user this device already is moves nothing.
    final sameUser = previousUserId == session.userId;
    // The local half of the merge runs before the app's session switches, so the new session's
    // sync worker finds it ready ([prepareAccountMerge]).
    final hadProgress = sameUser
        ? false
        : await ref.read(accountDevicePrepProvider)();
    if (!ref.mounted) return;
    ref.read(sessionProvider.notifier).signedIn(session);
    ref.read(analyticsProvider).track(AnalyticsEvent.accountSignedIn, {
      'provider': const EventValue.name(AccountProvider.email),
      'had_progress': EventValue.flag(hadProgress),
    });
    ref.read(logProvider).info('account signed in', {
      'had_progress': hadProgress,
    });
    _cooldown?.cancel();
    state = const AccountFlow(signedInHere: true);
  }

  void _failed(
    AccountFailure failure,
    String? reason, {
    required bool backToEmail,
  }) {
    if (!ref.mounted) return;
    // The failure and the server's code only: never the email (the logger redacts it too).
    ref.read(logProvider).warn('account step failed', {
      'mode': state.mode.name,
      'failure': failure.name,
      'reason': reason,
    });
    state = state.copyWith(
      step: backToEmail ? AccountStep.enterEmail : AccountStep.linkSent,
      failure: failure,
      canResend: backToEmail,
    );
    if (!backToEmail) {
      // A failed resend keeps waiting for the link already sent.
      _startCooldown();
      if (state.mode == AccountMode.link) _startWaiting();
    }
  }
}
