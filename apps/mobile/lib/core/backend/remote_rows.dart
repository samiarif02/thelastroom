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
    this.beatPlays,
    this.voiceAnswer,
  });

  /// Null when [row] lacks the picks (a row from before they were synced) and isn't a voice
  /// answer: it can't be restored, because the score is recomputed from them.
  static RemoteAttempt? fromRow(Map<String, Object?> row) {
    final voice = switch (row['voice_answer']) {
      final Map<String, Object?> v => v,
      _ => null,
    };
    final picks = voice == null ? row['beat_option_ids'] : const <Object?>[];
    final followUp = voice == null ? row['follow_up_id'] : '';
    final reply = voice == null ? row['reply_option_id'] : '';
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
      beatPlays: switch (row['beat_plays']) {
        final List<Object?> plays => plays,
        _ => null,
      },
      voiceAnswer: voice,
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

  /// How each beat was played (`beat_plays`, brief 30): `{reason_id, decided_us}` per beat. Null
  /// on rows synced before it existed; a restore then scores them at full credit.
  final List<Object?>? beatPlays;

  /// A voice mission's answer (`voice_answer`, brief 35): `{made, source, seconds}`. Set, the row
  /// sends no picks (the server's pick columns stay null); null on a built answer.
  final Map<String, Object?>? voiceAnswer;

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
    if (voiceAnswer == null) ...{
      'beat_option_ids': beatOptionIds,
      'follow_up_id': followUpId,
      'reply_option_id': replyOptionId,
    },
    'beat_plays': ?beatPlays,
    'voice_answer': ?voiceAnswer,
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
    this.leaderboardVisible = true,
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
    leaderboardVisible: row['leaderboard_visible'] != false,
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

  /// "Show me on the leaderboard" (issue 72), read on a restore. Not in [toRow]: it travels on
  /// its own ([RemoteLeaderboardReport]), so a project without that migration yet still takes
  /// the profile.
  final bool leaderboardVisible;

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

/// What the device still sends to the leaderboard: "Show me on the leaderboard", on the player's
/// own `profiles` row. Sent on its own (an upsert of this column only), so the profile's sync
/// never depends on it. Never the XP (issue 74): the board's numbers are the server's, recounted
/// from the AI recruiter's verdicts (supabase/migrations/20261105120000_verified_leaderboard.sql),
/// and a client may not write them.
class RemoteLeaderboardReport {
  const RemoteLeaderboardReport({required this.visible});

  final bool visible;

  Map<String, Object?> toRow() => {'leaderboard_visible': visible};
}

/// How many rows the board asks for (the top 50, and the caller's own row wherever it is).
const int leaderboardSize = 50;

/// Which board `public.leaderboard()` ranks: this UTC week's XP, or total XP.
enum LeaderboardScope {
  week('week'),
  allTime('all');

  const LeaderboardScope(this.wireName);

  /// The function's `p_scope`.
  final String wireName;
}

/// One row of `public.leaderboard()`: never a user id or an email (the function returns none).
class RemoteLeaderboardRow {
  const RemoteLeaderboardRow({
    required this.rank,
    required this.displayName,
    required this.tag,
    required this.totalXp,
    required this.weekXp,
    required this.streakWeeks,
    required this.isMe,
  });

  /// Null when [row] isn't one the function returns.
  static RemoteLeaderboardRow? fromRow(Object? row) {
    if (row case {
      'rank': final num rank,
      'tag': final String tag,
      'total_xp': final num total,
      'week_xp': final num week,
      'streak_weeks': final num streak,
      'is_me': final bool me,
    }) {
      final name = (row as Map<String, Object?>)['display_name'];
      return RemoteLeaderboardRow(
        rank: rank.toInt(),
        displayName: name is String && name.isNotEmpty ? name : null,
        tag: tag,
        totalXp: total.toInt(),
        weekXp: week.toInt(),
        streakWeeks: streak.toInt(),
        isMe: me,
      );
    }
    return null;
  }

  final int rank;

  /// The player's first name, or null when they gave none.
  final String? displayName;

  /// Four digits from the user id, computed by the server.
  final String tag;
  final int totalXp;
  final int weekXp;
  final int streakWeeks;
  final bool isMe;
}

int _int(Object? v) => switch (v) {
  final int i => i,
  final num n => n.toInt(),
  _ => int.parse('$v'),
};
