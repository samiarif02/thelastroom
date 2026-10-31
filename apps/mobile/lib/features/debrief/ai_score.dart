import 'dart:async';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/backend/backend.dart';
import '../../core/env/env.dart';
import '../../core/logging/log.dart';
import '../mission/mission_controller.dart';

/// The answer as the AI recruiter reads it (brief 22, ADR 0006): the question, each beat's line
/// with the reason given and whether it was guessed, the follow-up and the reply. Never the
/// player's name: the lines are the practice candidate's, taken from content, not addressed.
class ScoreRequest {
  const ScoreRequest({
    required this.mission,
    required this.plays,
    required this.followUp,
    required this.reply,
    this.attemptId,
  });

  final Mission mission;
  final List<BeatPlay> plays;
  final FollowUp followUp;
  final AnswerOption reply;
  final String? attemptId;

  /// The job the panel is hiring for in Chapter 1 (the content's Northstar Labs role).
  static const String hiringFor =
      'Product Associate at Northstar Labs (entry level)';

  /// The `score` function's JSON body.
  Map<String, Object?> toJson() => {
    'mission_id': mission.id,
    'hiring_for': hiringFor,
    'interviewer_role': interviewers
        .firstWhere((i) => i.id == mission.question.speakerId)
        .role,
    'question': mission.question.text,
    'beats': [
      for (var i = 0; i < plays.length; i++)
        {
          'kind': mission.beats[i].kind.name,
          'line': plays[i].option.text,
          'reason': plays[i].reason?.text,
          'guessed': isGuess(plays[i].decidedIn),
        },
    ],
    'follow_up_question': followUp.line.text,
    'reply': reply.text,
    'attempt_id': attemptId,
  };
}

/// One number the recruiter gave, and why.
class AiGraded {
  const AiGraded({required this.score, required this.basis});

  /// 0–100.
  final int score;

  /// One sentence: why this score.
  final String basis;
}

/// The recruiter's verdict, parsed and checked at the boundary (docs/rules/code-quality.md).
class AiScore {
  const AiScore({
    required this.model,
    required this.overall,
    required this.dimensions,
  });

  final String model;
  final AiGraded overall;
  final Map<Dimension, AiGraded> dimensions;

  /// Parses the function's JSON; null for anything that isn't a complete verdict, so a
  /// malformed answer falls back like any other failure.
  static AiScore? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final model = json['model'];
    final overall = _graded(json['overall']);
    final dims = json['dimensions'];
    if (model is! String || overall == null || dims is! Map<String, Object?>) {
      return null;
    }
    final dimensions = <Dimension, AiGraded>{};
    for (final d in Dimension.values) {
      final graded = _graded(dims[d.name]);
      if (graded == null) return null;
      dimensions[d] = graded;
    }
    return AiScore(model: model, overall: overall, dimensions: dimensions);
  }

  static AiGraded? _graded(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final score = json['score'];
    final basis = json['basis'];
    if (score is! int || score < 0 || score > maxMissionScore) return null;
    if (basis is! String || basis.trim().isEmpty) return null;
    return AiGraded(score: score, basis: basis.trim());
  }
}

/// Why the dossier shows the engine's score instead of the AI's.
enum AiFallbackReason {
  /// No backend configured (the zero-setup run).
  noBackend,

  /// The guest sign-in hasn't happened (offline since launch).
  noSession,

  /// No answer within [AiScorer.timeout] (offline, a slow network, the function down).
  timeout,

  /// The day's AI scores are spent (the function's rate limit).
  limited,

  /// Anything else: a refused call, a malformed verdict.
  error,
}

/// What the debrief shows: the AI's verdict, or the engine's score labelled "Offline score".
sealed class AiVerdict {
  const AiVerdict();
}

class AiScored extends AiVerdict {
  const AiScored(this.score);

  final AiScore score;
}

class AiOffline extends AiVerdict {
  const AiOffline(this.reason);

  final AiFallbackReason reason;
}

/// Asks the AI recruiter for a verdict, and never fails: every problem is an [AiOffline].
class AiScorer {
  const AiScorer({
    required this.env,
    required this.session,
    required this.backend,
    required this.log,
  });

  final Env env;
  final BackendSession session;
  final Backend Function() backend;
  final Log log;

  /// The longest the player waits for the panel (brief 22: at most 8 s), then the offline score.
  static const Duration timeout = Duration(seconds: 8);

  /// Why there's no point asking, known at once (so the debrief shows no loading state), or null.
  AiFallbackReason? get unavailable {
    if (!env.hasSupabase) return AiFallbackReason.noBackend;
    if (session is! GuestSession) return AiFallbackReason.noSession;
    return null;
  }

  Future<AiVerdict> score(ScoreRequest request) async {
    final skip = unavailable;
    if (skip != null) return AiOffline(skip);
    try {
      final json = await backend()
          .scoreAnswer(request.toJson())
          .timeout(timeout);
      final score = AiScore.fromJson(json);
      if (score == null) {
        log.warn('ai score malformed');
        return const AiOffline(AiFallbackReason.error);
      }
      return AiScored(score);
    } on TimeoutException {
      return const AiOffline(AiFallbackReason.timeout);
    } on ScoreRefused catch (refused) {
      log.warn('ai score refused', {
        'status': refused.status,
        'code': refused.code,
      });
      return AiOffline(
        refused.status == _tooManyRequests
            ? AiFallbackReason.limited
            : AiFallbackReason.error,
      );
    } on Object catch (error) {
      // Offline, the backend down, anything the client throws: the engine's score stands.
      log.warn('ai score failed', {'error': '${error.runtimeType}'});
      return const AiOffline(AiFallbackReason.error);
    }
  }

  static const int _tooManyRequests = 429;
}

/// The debrief's scorer. Tests override it with a fake.
final aiScorerProvider = Provider<AiScorer>(
  (ref) => AiScorer(
    env: ref.watch(envProvider),
    session: ref.watch(sessionProvider),
    backend: () => ref.read(backendProvider),
    log: ref.watch(logProvider),
  ),
);
