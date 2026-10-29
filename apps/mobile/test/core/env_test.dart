import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/env/env.dart';

void main() {
  test('with no defines the app runs offline: every integration is off', () {
    final env = Env.fromDefines();
    expect(env.appEnv, 'dev');
    expect(env.isProd, isFalse);
    expect(env.hasSupabase, isFalse);
    expect(env.hasSentry, isFalse);
    expect(env.hasPosthog, isFalse);
  });

  test('an integration turns on only when all its keys are set', () {
    const env = Env(
      appEnv: 'prod',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: '',
      sentryDsn: '',
      posthogApiKey: '',
      posthogHost: '',
    );
    expect(env.isProd, isTrue);
    expect(env.hasSupabase, isFalse);
  });
}
