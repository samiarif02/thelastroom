import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/backend/backend.dart';
import '../../../ui/daylight/daylight_kit.dart';
import 'save_progress_controller.dart';

/// Which face the card shows. Derived from the env, the session and the flow, so every state
/// has a name a test can ask for.
enum SaveProgressFace {
  /// No backend in this build (ADR 0005): a calm note, nothing to press.
  noBackend,

  /// A backend, but no session yet (offline since launch): try again later.
  offline,

  /// Typing the email.
  enterEmail,

  /// The code is being mailed.
  sending,

  /// Typing the code.
  enterCode,

  /// The code is being checked.
  verifying,

  /// Saved: the linked email.
  linked,
}

/// "Save your progress" (FR-3), the first card of Settings: a guest saves their progress to an
/// email with a six-digit code, or signs in to progress saved on another device. With no backend
/// it says, calmly, that saving needs one and that offline play is unaffected.
class SaveProgressCard extends ConsumerStatefulWidget {
  const SaveProgressCard({super.key});

  static const String heading = 'Save your progress';
  static const String signInHeading = 'Sign in on another device';

  static const String tagGuest = 'Guest';
  static const String tagDevice = 'On this device';
  static const String tagOffline = 'Offline';
  static const String tagSaved = 'Saved';

  static const String noBackendLine =
      'Saving to an account needs the online save desk, and this build runs without one. '
      'Everything you play stays safe on this device, and the whole game works offline.';
  static const String offlineLine =
      'The save desk can’t be reached right now. Your progress is safe on this device; you '
      'can save it to your email once you’re back online.';
  static const String linkLine =
      'You’re playing as a guest. Add your email and your progress follows you to any device. '
      'We’ll send a six-digit code to check it’s yours.';
  static const String signInLine =
      'Enter the email you saved with. We’ll send a six-digit code, and your saved progress comes '
      'to this device, joined with anything you’ve played here.';

  static const String emailLabel = 'Your email';
  static const String codeLabel = 'Six-digit code';
  static const String sendCode = 'Send me a code';
  static const String sending = 'Sending your code…';
  static const String saveButton = 'Save my progress';
  static const String signInButton = 'Sign in';
  static const String verifying = 'Checking your code…';
  static const String resend = 'Resend code';
  static const String otherEmail = 'Change email';
  static const String toSignIn = 'Saved on another device? Sign in';
  static const String toLink = 'Save this device instead';

  static String codeSentLine(String email) =>
      'We sent a six-digit code to $email. It works once and expires in an hour.';
  static const String resentLine =
      'A new code is on its way. Use the latest one.';

  static String linkedLine(String email) =>
      'Your progress is saved to $email. Every room you play is backed up whenever you’re '
      'online.';
  static const String linkedHow =
      'On a new phone or the web, open Settings and choose “Saved on another device? Sign in” '
      'with this email.';
  static const String signedInLine =
      'Signed in. Your saved progress is coming down to this device and joining what you '
      'played here.';

  static const String invalidEmail = 'That doesn’t look like an email address.';
  static const String wrongCode =
      'That code didn’t work. It may be mistyped or expired: check the latest email, or resend '
      'the code.';
  static const String rateLimited =
      'Too many codes in a short time. Wait a minute, then try again.';
  static const String emailTaken =
      'That email already has saved progress. To use it here, choose “Saved on another device? '
      'Sign in”.';
  static const String noAccount =
      'Nothing is saved to that email yet. Save this device’s progress to it instead.';
  static const String offline =
      'Can’t reach the save desk. Check your connection and try again; your progress is safe '
      'on this device.';
  static const String unavailable =
      'The save desk didn’t answer properly. Try again in a moment; your progress is safe on '
      'this device.';

  /// The copy for each failure.
  static String failureLine(AccountFailure failure) => switch (failure) {
    AccountFailure.invalidEmail => invalidEmail,
    AccountFailure.wrongCode => wrongCode,
    AccountFailure.rateLimited => rateLimited,
    AccountFailure.emailTaken => emailTaken,
    AccountFailure.noAccount => noAccount,
    AccountFailure.offline => offline,
    AccountFailure.unavailable => unavailable,
  };

  /// The face for this env, session and flow.
  static SaveProgressFace faceOf({
    required bool hasBackend,
    required BackendSession session,
    required AccountFlow flow,
  }) {
    if (!hasBackend) return SaveProgressFace.noBackend;
    if (session is GuestSession && session.isLinked) {
      return SaveProgressFace.linked;
    }
    if (session is! GuestSession) return SaveProgressFace.offline;
    return switch (flow.step) {
      AccountStep.enterEmail => SaveProgressFace.enterEmail,
      AccountStep.sending => SaveProgressFace.sending,
      AccountStep.enterCode => SaveProgressFace.enterCode,
      AccountStep.verifying => SaveProgressFace.verifying,
    };
  }

  @override
  ConsumerState<SaveProgressCard> createState() => _SaveProgressCardState();
}

class _SaveProgressCardState extends ConsumerState<SaveProgressCard> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(_changed);
    _email.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  SaveProgressController get _controller =>
      ref.read(saveProgressProvider.notifier);

  Future<void> _send() => _controller.sendCode(_email.text);

  Future<void> _confirm() => _controller.confirm(_code.text);

  @override
  Widget build(BuildContext context) {
    final env = ref.watch(envProvider);
    final session = ref.watch(sessionProvider);
    final flow = ref.watch(saveProgressProvider);
    ref.listen(saveProgressProvider, (before, now) {
      // A new step starts with an empty code; the email the controller settled on is shown.
      if (before?.step != now.step && now.step == AccountStep.enterEmail) {
        _code.clear();
        if (_email.text != now.email && now.email.isNotEmpty) {
          _email.text = now.email;
        }
      }
      if (now.resent && before?.resent != true) _code.clear();
    });
    final face = SaveProgressCard.faceOf(
      hasBackend: env.hasSupabase,
      session: session,
      flow: flow,
    );
    final signIn = flow.mode == AccountMode.signIn;
    final (heading, tag, tagTone) = switch (face) {
      SaveProgressFace.noBackend => (
        SaveProgressCard.heading,
        SaveProgressCard.tagDevice,
        TagTone.sand,
      ),
      SaveProgressFace.offline => (
        SaveProgressCard.heading,
        SaveProgressCard.tagOffline,
        TagTone.sand,
      ),
      SaveProgressFace.linked => (
        SaveProgressCard.heading,
        SaveProgressCard.tagSaved,
        TagTone.floor(ChapterTint.floorOf(context)),
      ),
      _ => (
        signIn ? SaveProgressCard.signInHeading : SaveProgressCard.heading,
        SaveProgressCard.tagGuest,
        TagTone.honey,
      ),
    };
    return Column(
      key: ValueKey(face),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s8,
          children: [
            Semantics(
              header: true,
              child: Text(heading, style: DaylightType.heading6),
            ),
            Tag(
              label: tag,
              tone: tagTone,
              icon: switch (face) {
                SaveProgressFace.linked => PhosphorBold.checkCircle,
                SaveProgressFace.offline => PhosphorBold.wifiSlash,
                SaveProgressFace.noBackend => PhosphorBold.lockSimple,
                _ => PhosphorBold.userCircle,
              },
            ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s4),
        ..._body(face, flow, session),
      ],
    );
  }

  List<Widget> _body(
    SaveProgressFace face,
    AccountFlow flow,
    BackendSession session,
  ) {
    final signIn = flow.mode == AccountMode.signIn;
    final failure = flow.failure;
    switch (face) {
      case SaveProgressFace.noBackend:
        return [_line(SaveProgressCard.noBackendLine)];
      case SaveProgressFace.offline:
        return [_line(SaveProgressCard.offlineLine)];
      case SaveProgressFace.linked:
        final email = (session as GuestSession).email ?? '';
        return [
          if (flow.signedInHere) ...[
            _note(SaveProgressCard.signedInLine, tone: _NoteTone.good),
            const SizedBox(height: DaylightSpace.s8),
          ],
          _line(SaveProgressCard.linkedLine(email), color: DaylightColors.ink),
          const SizedBox(height: DaylightSpace.s8),
          _line(SaveProgressCard.linkedHow),
        ];
      case SaveProgressFace.enterEmail:
      case SaveProgressFace.sending:
        final sending = face == SaveProgressFace.sending;
        return [
          _line(
            signIn ? SaveProgressCard.signInLine : SaveProgressCard.linkLine,
          ),
          const SizedBox(height: DaylightSpace.s16),
          EntryField(
            label: SaveProgressCard.emailLabel,
            controller: _email,
            enabled: !sending,
            error: failure != null,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
          if (failure != null) ...[
            const SizedBox(height: DaylightSpace.s8),
            _note(SaveProgressCard.failureLine(failure)),
          ],
          const SizedBox(height: DaylightSpace.s16),
          TactileButton(
            label: sending
                ? SaveProgressCard.sending
                : SaveProgressCard.sendCode,
            icon: sending ? PhosphorBold.hourglass : PhosphorBold.arrowRight,
            compact: true,
            onPressed: sending || _email.text.trim().isEmpty ? null : _send,
          ),
          const SizedBox(height: DaylightSpace.s8),
          TactileButton(
            label: signIn ? SaveProgressCard.toLink : SaveProgressCard.toSignIn,
            tone: TactileTone.quiet,
            compact: true,
            onPressed: sending
                ? null
                : () => _controller.useMode(
                    signIn ? AccountMode.link : AccountMode.signIn,
                  ),
          ),
        ];
      case SaveProgressFace.enterCode:
      case SaveProgressFace.verifying:
        final checking = face == SaveProgressFace.verifying;
        return [
          Semantics(
            liveRegion: true,
            child: _line(SaveProgressCard.codeSentLine(flow.email)),
          ),
          const SizedBox(height: DaylightSpace.s16),
          EntryField(
            label: SaveProgressCard.codeLabel,
            controller: _code,
            enabled: !checking,
            error: failure != null,
            code: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(accountCodeLength),
            ],
            onSubmitted: (_) => _confirm(),
          ),
          if (failure != null) ...[
            const SizedBox(height: DaylightSpace.s8),
            _note(SaveProgressCard.failureLine(failure)),
          ] else if (flow.resent) ...[
            const SizedBox(height: DaylightSpace.s8),
            _note(SaveProgressCard.resentLine, tone: _NoteTone.good),
          ],
          const SizedBox(height: DaylightSpace.s16),
          TactileButton(
            label: checking
                ? SaveProgressCard.verifying
                : signIn
                ? SaveProgressCard.signInButton
                : SaveProgressCard.saveButton,
            icon: checking ? PhosphorBold.hourglass : PhosphorBold.check,
            compact: true,
            onPressed: checking || _code.text.length != accountCodeLength
                ? null
                : _confirm,
          ),
          const SizedBox(height: DaylightSpace.s8),
          // Side by side at 1x, one under the other when large text needs the room.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: DaylightSpace.s8,
            runSpacing: DaylightSpace.s8,
            children: [
              TactileButton(
                label: SaveProgressCard.resend,
                tone: TactileTone.quiet,
                compact: true,
                expand: false,
                onPressed: checking ? null : _controller.resend,
              ),
              TactileButton(
                label: SaveProgressCard.otherEmail,
                tone: TactileTone.quiet,
                compact: true,
                expand: false,
                onPressed: checking ? null : _controller.editEmail,
              ),
            ],
          ),
        ];
    }
  }

  Widget _line(String text, {Color color = DaylightColors.ink2}) =>
      Text(text, style: DaylightType.body6.copyWith(color: color));

  Widget _note(String text, {_NoteTone tone = _NoteTone.trouble}) {
    final (ground, ink, icon) = switch (tone) {
      _NoteTone.trouble => (
        DaylightColors.trapTint,
        DaylightColors.trap,
        PhosphorBold.warningCircle,
      ),
      _NoteTone.good => (
        DaylightColors.honeyTint,
        DaylightColors.honeyInk,
        PhosphorBold.checkCircle,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(DaylightRadius.inner),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DaylightSpace.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: DaylightSpace.s2),
                child: Icon(icon, size: _noteIcon, color: ink),
              ),
              const SizedBox(width: DaylightSpace.s8),
              Expanded(
                child: Text(
                  text,
                  style: DaylightType.body5.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _noteIcon = 16;
}

enum _NoteTone { trouble, good }
