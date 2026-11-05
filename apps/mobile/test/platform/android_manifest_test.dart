import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Security audit 2026-11-05: Android's auto backup would copy the session tokens (and the
/// device database) to another device, so the app opts out.
void main() {
  test('the Android app opts out of OS backup', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(manifest, contains('@xml/data_extraction_rules'));
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    for (final domain in ['database', 'sharedpref']) {
      expect(rules, contains('<exclude domain="$domain" />'));
    }
  });
}
