import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/remote_rows.dart';

/// Security audit 2026-11-05: the first name shows on everyone's leaderboard, so it travels
/// without invisible or direction-changing characters.
void main() {
  test('control, zero-width and bidi characters are stripped', () {
    expect(cleanFirstName('  Sa\u202Emi\u200B\u0007 '), 'Sami');
    expect(cleanFirstName('Zo\u00EB'), 'Zo\u00EB', reason: 'accents stay');
    expect(cleanFirstName('\u2066\u200B'), isNull);
    expect(cleanFirstName(null), isNull);
  });

  test('the profile row sends the cleaned name', () {
    expect(
      const RemoteProfile(firstName: 'Ali\u200F').toRow()['first_name'],
      'Ali',
    );
  });
}
