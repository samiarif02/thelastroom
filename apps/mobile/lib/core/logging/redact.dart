/// Scrubs credential-shaped values and personal data out of log fields before they leave the
/// process. The runtime cousin of `scripts/check-secrets.mjs` (which refuses commits) and the
/// session-log hook's REDACTIONS: same shapes, different job.
library;

const String redacted = '[REDACTED]';

/// Field names whose value is never logged, whatever it looks like.
final RegExp _sensitiveKey = RegExp(
  r'(password|passwd|secret|token|api[_-]?key|apikey|authorization|cookie|session|email|answer|draft)',
  caseSensitive: false,
);

final List<RegExp> _sensitiveValue = [
  RegExp(
    r'eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}',
  ), // JWT
  RegExp(r'sk-ant-[A-Za-z0-9_\-]{12,}'), // Anthropic
  RegExp(r'sb_secret_[A-Za-z0-9_\-]{4,}'), // Supabase secret key
  RegExp(r'\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}'), // GitHub
  RegExp(r'bearer\s+[A-Za-z0-9_\-.=]{16,}', caseSensitive: false),
  RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'), // email
];

/// Returns a copy of [fields] that is safe to log. Nested maps and lists are walked.
Map<String, Object?> redactFields(Map<String, Object?> fields) => {
  for (final entry in fields.entries)
    entry.key: _sensitiveKey.hasMatch(entry.key)
        ? redacted
        : redactValue(entry.value),
};

Object? redactValue(Object? value) => switch (value) {
  final String s => redactText(s),
  final Map<String, Object?> m => redactFields(m),
  final List<Object?> l => [for (final v in l) redactValue(v)],
  _ => value,
};

String redactText(String text) {
  var out = text;
  for (final pattern in _sensitiveValue) {
    out = out.replaceAll(pattern, redacted);
  }
  return out;
}
