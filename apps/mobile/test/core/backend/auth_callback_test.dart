import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/supabase_backend.dart';

/// Security audit 2026-11-05 (deep-link session injection): the app's link handler accepts a
/// PKCE code or the server's error redirect, never a session handed over in the URL.
void main() {
  bool accepts(String link) => SupabaseBackend.isAuthCallback(Uri.parse(link));

  test('a PKCE sign-in link is read', () {
    expect(accepts('thelastroom://auth-callback?code=4f1c2a'), isTrue);
  });

  test('an expired or used link is read, so the player sees why', () {
    expect(
      accepts(
        'thelastroom://auth-callback#error=access_denied&error_code=otp_expired'
        '&error_description=Email+link+is+invalid',
      ),
      isTrue,
    );
    expect(
      accepts('thelastroom://auth-callback?error_code=otp_expired'),
      isTrue,
    );
  });

  test(
    'a link carrying a session is ignored, in the fragment or the query',
    () {
      expect(
        accepts(
          'thelastroom://auth-callback#access_token=A&refresh_token=R'
          '&expires_in=3600&token_type=bearer',
        ),
        isFalse,
      );
      expect(
        accepts('thelastroom://auth-callback?access_token=A&expires_in=3600'),
        isFalse,
      );
      expect(accepts('thelastroom://auth-callback?refresh_token=R'), isFalse);
    },
  );

  test('a code smuggled beside a session is still ignored', () {
    expect(
      accepts(
        'thelastroom://auth-callback?code=c#access_token=A&refresh_token=R',
      ),
      isFalse,
    );
  });

  test('a link with nothing for sign-in is not an auth link', () {
    expect(accepts('thelastroom://auth-callback'), isFalse);
    expect(accepts('thelastroom://auth-callback#section'), isFalse);
  });
}
