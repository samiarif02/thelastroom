/// The app's configuration: the one place that reads compile-time defines.
///
/// Values come from `--dart-define-from-file=env/<flavor>.json`; `env/dev.example.json`
/// documents every key, and `check:env` fails if this file, that file and the code drift apart.
/// Only public values belong here (the Supabase anon key is public by design, guarded by RLS).
/// Server secrets live in Edge Function secrets, never in the app (docs/rules/secrets.md).
///
/// Every value is optional: the app plays fully offline, so a missing backend key turns that
/// integration off rather than crashing.
class Env {
  const Env({
    required this.appEnv,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.sentryDsn,
    required this.posthogApiKey,
    required this.posthogHost,
  });

  factory Env.fromDefines() => const Env(
    appEnv: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
    posthogApiKey: String.fromEnvironment('POSTHOG_API_KEY'),
    posthogHost: String.fromEnvironment('POSTHOG_HOST'),
  );

  /// `dev`, `staging` or `prod`.
  final String appEnv;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String sentryDsn;
  final String posthogApiKey;
  final String posthogHost;

  bool get isProd => appEnv == 'prod';
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasSentry => sentryDsn.isNotEmpty;
  bool get hasPosthog => posthogApiKey.isNotEmpty && posthogHost.isNotEmpty;
}
