import 'dart:typed_data';

/// Whether the app may use the microphone.
enum MicAccess {
  /// Granted: the recorder can start.
  granted,

  /// Refused (or the platform has no microphone): the mission offers the self-check instead.
  denied,
}

/// The microphone as the recorder needs it: PCM in [VoicePcm]'s format (16 kHz mono 16-bit),
/// opened and closed per stretch of speech. `RecordMicrophone` in the app, a fake in tests.
abstract interface class Microphone {
  /// Whether access is already granted, without asking the player.
  Future<bool> hasAccess();

  /// Asks the platform for access (the OS dialog). Called only after the explainer.
  Future<MicAccess> ask();

  /// Starts capturing; the stream ends when [close] is called. Throws if the platform can't
  /// record (the recorder shows the refused state).
  Future<Stream<Uint8List>> open();

  /// Stops capturing. Safe to call when not open.
  Future<void> close();

  Future<void> dispose();
}
