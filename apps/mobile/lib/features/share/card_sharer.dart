import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// How a share went, as the `floor_card_shared` event reports it.
enum ShareOutcome {
  /// The player picked somewhere to send it.
  shared,

  /// The share sheet was closed without sending.
  dismissed,

  /// Sharing couldn't open, or the platform can't say what happened (the web: the picture was
  /// handed to the browser's share or downloaded, with no answer back).
  unavailable,
}

/// Hands a picture and a line of text to the system's share sheet. One method, so tests use a
/// fake; the app uses [SharePlusSharer].
abstract interface class CardSharer {
  /// Opens the share sheet with [png] (named [fileName]) and [text]. [origin] is where the
  /// share started, in global coordinates (the iPad's popover points at it). Throws when the
  /// sheet can't open.
  Future<ShareOutcome> share({
    required Uint8List png,
    required String fileName,
    required String text,
    Rect? origin,
  });
}

/// `share_plus`: Android's chooser, iOS's activity sheet, and on the web the browser's
/// Web Share where it can share files, else the PNG is downloaded.
class SharePlusSharer implements CardSharer {
  const SharePlusSharer();

  static const String _png = 'image/png';

  @override
  Future<ShareOutcome> share({
    required Uint8List png,
    required String fileName,
    required String text,
    Rect? origin,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(png, mimeType: _png, name: fileName)],
        fileNameOverrides: [fileName],
        sharePositionOrigin: origin,
        // The text alone in an email isn't the card: on the web, download the picture instead.
        mailToFallbackEnabled: false,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unavailable,
    };
  }
}

/// The sharer the share link uses; tests swap in a fake.
final cardSharerProvider = Provider<CardSharer>(
  (ref) => const SharePlusSharer(),
);
