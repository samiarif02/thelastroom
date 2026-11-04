import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_last_room/core/backend/supabase_backend.dart';

/// FR-3 by link: how the Supabase user reads once its link is tapped, and which auth stream
/// errors are a refused sign-in link (status 67).
void main() {
  const email = 'player@example.com';

  User user({
    String? email,
    String? newEmail,
    String? confirmedAt,
    bool anonymous = true,
  }) => User.fromJson({
    'id': '00000000-0000-4000-8000-000000000001',
    'aud': 'authenticated',
    'app_metadata': <String, Object?>{},
    'user_metadata': <String, Object?>{},
    'created_at': '2026-11-04T00:00:00Z',
    'email': ?email,
    'new_email': ?newEmail,
    'email_confirmed_at': ?confirmedAt,
    'is_anonymous': anonymous,
  })!;

  group('linkedEmail', () {
    test('a guest is not linked', () {
      expect(SupabaseBackend.linkedEmail(user(email: '')), isNull);
    });

    test('a link mailed but not tapped: the address waits in new_email', () {
      expect(
        SupabaseBackend.linkedEmail(user(email: '', newEmail: email)),
        isNull,
      );
    });

    test(
      'tapped: the address is the email, the guest is no longer anonymous',
      () {
        expect(
          SupabaseBackend.linkedEmail(
            user(
              email: email,
              confirmedAt: '2026-11-04T00:01:00Z',
              anonymous: false,
            ),
          ),
          email,
        );
      },
    );

    test('tapped, read through a token minted before (still anonymous)', () {
      expect(
        SupabaseBackend.linkedEmail(
          user(email: email, confirmedAt: '2026-11-04T00:01:00Z'),
        ),
        email,
      );
    });
  });

  group('linkRefusal', () {
    test('the error redirect of an expired or used link', () {
      // What getSessionFromUrl throws for #error=access_denied&error_code=otp_expired.
      const error = AuthException(
        'Email link is invalid or has expired',
        statusCode: 'otp_expired',
        code: 'access_denied',
      );
      expect(SupabaseBackend.linkRefusal(error), 'otp_expired');
    });

    test('a PKCE code this device cannot exchange', () {
      expect(
        SupabaseBackend.linkRefusal(
          const AuthPKCEGrantCodeExchangeError(
            'Code verifier could not be found',
          ),
        ),
        isNotNull,
      );
    });

    test('an offline token refresh is not a link', () {
      expect(
        SupabaseBackend.linkRefusal(AuthRetryableFetchException()),
        isNull,
      );
      expect(SupabaseBackend.linkRefusal(StateError('x')), isNull);
      expect(
        SupabaseBackend.linkRefusal(
          const AuthException('Session expired.', code: 'session_expired'),
        ),
        isNull,
      );
    });
  });
}
