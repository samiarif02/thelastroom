/// The rows the app sends to and reads from the backend, as plain Dart: no `supabase_flutter`,
/// so the mapping is tested without a server. Column names are the migrations' (supabase/).
library;

/// One `mission_attempts` row. Never carries the draft: the player's own words stay on the
/// device. `user_id` and `created_at` aren't sent: the server sets them (column grants).
class RemoteAttempt {
  const RemoteAttempt({
    required this.attemptId,
    required this.missionId,
    required this.contentSchemaVersion,
    required this.relevance,
    required this.specificity,
    required this.structure,
    required this.adaptability,
    required this.total,
    required this.hinted,
    required this.flags,
    required this.completedAt,
    required this.attemptNumber,
    required this.seed,
    required this.beatOptionIds,
    required this.followUpId,
    required this.replyOptionId,
  });

  /// Null when [row] lacks the picks (a row from before they were synced): it can't be
  /// restored, because the score is recomputed from them.
  static RemoteAttempt? fromRow(Map<String, Object?> row) {
    final picks = row['beat_option_ids'];
    final followUp = row['follow_up_id'];
    final reply = row['reply_option_id'];
    final seed = row['seed'];
    final number = row['attempt_number'];
    if (picks is! List || followUp is! String || reply is! String) return null;
    if (seed is! int || number is! int) return null;
    return RemoteAttempt(
      attemptId: '${row['attempt_id']}',
      missionId: '${row['mission_id']}',
      contentSchemaVersion: _int(row['content_schema_version']),
      relevance: _int(row['relevance_score']),
      specificity: _int(row['specificity_score']),
      structure: _int(row['structure_score']),
      adaptability: _int(row['adaptability_score']),
      total: _int(row['total_score']),
      hinted: row['hinted'] == true,
      flags: [for (final f in row['flags'] as List<Object?>? ?? const []) '$f'],
      completedAt: DateTime.parse('${row['completed_at']}').toUtc(),
      attemptNumber: number,
      seed: seed,
      beatOptionIds: [for (final id in picks) '$id'],
      followUpId: followUp,
      replyOptionId: reply,
    );
  }

  final String attemptId;
  final String missionId;
  final int contentSchemaVersion;
  final int relevance;
  final int specificity;
  final int structure;
  final int adaptability;
  final int total;
  final bool hinted;

  /// The engine's flag wire names.
  final List<String> flags;
  final DateTime completedAt;
  final int attemptNumber;
  final int seed;
  final List<String> beatOptionIds;
  final String followUpId;
  final String replyOptionId;

  Map<String, Object?> toRow() => {
    'attempt_id': attemptId,
    'mission_id': missionId,
    'content_schema_version': contentSchemaVersion,
    'relevance_score': relevance,
    'specificity_score': specificity,
    'structure_score': structure,
    'adaptability_score': adaptability,
    'total_score': total,
    'hinted': hinted,
    'flags': flags,
    'completed_at': completedAt.toUtc().toIso8601String(),
    'attempt_number': attemptNumber,
    'seed': seed,
    'beat_option_ids': beatOptionIds,
    'follow_up_id': followUpId,
    'reply_option_id': replyOptionId,
  };
}

/// The player's `profiles` row: what onboarding asked, the two play settings and the waitlist
/// flag. Enum values travel as their Dart names.
class RemoteProfile {
  const RemoteProfile({
    this.firstName,
    this.experience,
    this.targetRole,
    this.nervesLevel,
    this.calmMode = false,
    this.weeklyGoal,
    this.autoAdvance = true,
    this.onboarded = false,
    this.chapter2WaitlistAt,
  });

  factory RemoteProfile.fromRow(Map<String, Object?> row) => RemoteProfile(
    firstName: row['first_name'] as String?,
    experience: row['experience'] as String?,
    targetRole: row['target_role'] as String?,
    nervesLevel: row['nerves_level'] as int?,
    calmMode: row['calm_mode'] == true,
    weeklyGoal: row['weekly_goal'] as int?,
    autoAdvance: row['auto_advance'] != false,
    onboarded: row['onboarded'] == true,
    chapter2WaitlistAt: switch (row['chapter_2_waitlist_at']) {
      final String at => DateTime.parse(at).toUtc(),
      _ => null,
    },
  );

  final String? firstName;
  final String? experience;
  final String? targetRole;
  final int? nervesLevel;
  final bool calmMode;
  final int? weeklyGoal;
  final bool autoAdvance;
  final bool onboarded;
  final DateTime? chapter2WaitlistAt;

  Map<String, Object?> toRow() => {
    'first_name': firstName,
    'experience': experience,
    'target_role': targetRole,
    'nerves_level': nervesLevel,
    'calm_mode': calmMode,
    'weekly_goal': weeklyGoal,
    'auto_advance': autoAdvance,
    'onboarded': onboarded,
    'chapter_2_waitlist_at': chapter2WaitlistAt?.toUtc().toIso8601String(),
  };
}

int _int(Object? v) => switch (v) {
  final int i => i,
  final num n => n.toInt(),
  _ => int.parse('$v'),
};
