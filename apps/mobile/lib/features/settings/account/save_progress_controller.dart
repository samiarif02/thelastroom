import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/analytics/analytics_event.dart';
import '../../../core/analytics/event_value.dart';
import '../../../core/backend/backend.dart';
import '../../../core/sync/account_merge.dart';
import '../../recall/recall_store.dart';

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

  /// Asking the server to mail the code.
  sending,

  /// The code is on its way; typing it.
  enterCode,

  /// Checking the code.
  verifying,
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
    this.signedInHere = false,
  });

  final AccountMode mode;
  final AccountStep step;

  /// The address being saved to (shown on the card, never logged or tracked).
  final String email;

  /// What went wrong on the last step, shown under it; null when nothing did.
  final AccountFailure? failure;

  /// A new code was sent on request ("Send a new code").
  final bool resent;

  /// This device just signed in to a saved account (the linked card says the file is coming).
  final bool signedInHere;

  bool get busy => step == AccountStep.sending || step == AccountStep.verifying;

  AccountFlow copyWith({
    AccountMode? mode,
    AccountStep? step,
    String? email,
    AccountFailure? failure,
    bool clearFailure = false,
    bool? resent,
    bool? signedInHere,
  }) => AccountFlow(
    mode: mode ?? this.mode,
    step: step ?? this.step,
    email: email ?? this.email,
    failure: clearFailure ? null : failure ?? this.failure,
    resent: resent ?? this.resent,
    signedInHere: signedInHere ?? this.signedInHere,
  );
}

/// How long one account call may take before it counts as offline.
const Duration accountCallTimeout = Duration(seconds: 20);

/// The length of the emailed code (`otp_length` in supabase/config.toml).
const int accountCodeLength = 6;

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

/// The "Save your progress" card's controller (FR-3). Every backend call goes through
/// [Backend]; each failure is a typed [AccountFailure] the card has a state for.
final saveProgressProvider =
    NotifierProvider<SaveProgressController, AccountFlow>(
      SaveProgressController.new,
    );

class SaveProgressController extends Notifier<AccountFlow> {
  @override
  AccountFlow build() => const AccountFlow();

  /// Switches between saving this device and signing in to a saved account.
  void useMode(AccountMode mode) => state = AccountFlow(mode: mode);

  /// Back to the email step, keeping what was typed.
  void editEmail() => state = AccountFlow(mode: state.mode, email: state.email);

  /// Step 1: mails a code to [raw]. A link the server makes at once (no code) goes straight to
  /// linked.
  Future<void> sendCode(String raw) async {
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
    state = AccountFlow(
      mode: state.mode,
      step: AccountStep.sending,
      email: email,
    );
    await _sendTo(email, backToEmail: true);
  }

  /// "Send a new code", from the code step.
  Future<void> resend() async {
    if (state.busy || state.step != AccountStep.enterCode) return;
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
            .sendLinkCode(email)
            .timeout(accountCallTimeout);
        if (linked != null) {
          _linked(linked);
          return;
        }
      } else {
        await backend.sendSignInCode(email).timeout(accountCallTimeout);
      }
      if (!ref.mounted) return;
      state = AccountFlow(
        mode: mode,
        step: AccountStep.enterCode,
        email: email,
        resent: resent,
      );
    } on AccountException catch (error) {
      _failed(error.failure, error.reason, backToEmail: backToEmail);
    } on TimeoutException {
      _failed(AccountFailure.offline, 'timeout', backToEmail: backToEmail);
    }
  }

  /// Step 2: checks [raw], the code from the email.
  Future<void> confirm(String raw) async {
    if (state.busy || state.step != AccountStep.enterCode) return;
    final code = raw.replaceAll(RegExp(r'\s'), '');
    if (code.length != accountCodeLength) {
      state = state.copyWith(failure: AccountFailure.wrongCode, resent: false);
      return;
    }
    state = state.copyWith(
      step: AccountStep.verifying,
      clearFailure: true,
      resent: false,
    );
    final backend = ref.read(backendProvider);
    final email = state.email;
    try {
      if (state.mode == AccountMode.link) {
        final session = await backend
            .confirmLinkCode(email: email, code: code)
            .timeout(accountCallTimeout);
        _linked(session);
      } else {
        final session = await backend
            .confirmSignInCode(email: email, code: code)
            .timeout(accountCallTimeout);
        await _signedIn(session);
      }
    } on AccountException catch (error) {
      _failed(error.failure, error.reason, backToEmail: false);
    } on TimeoutException {
      _failed(AccountFailure.offline, 'timeout', backToEmail: false);
    }
  }

  void _linked(GuestSession session) {
    if (!ref.mounted) return;
    ref.read(sessionProvider.notifier).signedIn(session);
    ref.read(analyticsProvider).track(AnalyticsEvent.accountLinked, {
      'provider': const EventValue.name(AccountProvider.email),
    });
    ref.read(logProvider).info('account linked');
    state = const AccountFlow();
  }

  Future<void> _signedIn(GuestSession session) async {
    final before = ref.read(sessionProvider);
    final sameUser = before is GuestSession && before.userId == session.userId;
    // The local half of the merge runs before the session switches, so the new session's sync
    // worker finds it ready ([prepareAccountMerge]).
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
      step: backToEmail ? AccountStep.enterEmail : AccountStep.enterCode,
      failure: failure,
    );
  }
}
