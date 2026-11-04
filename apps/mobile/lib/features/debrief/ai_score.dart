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

  /// How long a verdict may still arrive after the offline score is showing. Gemini is often
  /// slower than 8 s under load (measured live, brief 36); a late verdict is offered over the
  /// offline score (the debrief's "The recruiter's score is ready") instead of being thrown
  /// away. Longer than the function's own model chain (~24 s).
  static const Duration lateLimit = Duration(seconds: 30);

  /// Why there's no point asking, known at once (so the debrief shows no loading state), or null.
  AiFallbackReason? get unavailable {
    if (!env.hasSupabase) return AiFallbackReason.noBackend;
    if (session is! GuestSession) return AiFallbackReason.noSession;
    return null;
  }

  Future<AiVerdict> score(ScoreRequest request) async {
    final skip = unavailable;
    if (skip != null) return AiOffline(skip);
    return _ask(request, timeout);
  }

  /// What the debrief shows, in order: the verdict if it comes within [timeout]; otherwise the
  /// offline score at [timeout], then the verdict too if it still comes within [lateLimit].
  /// The player never waits longer than [timeout] for something to read. Both timers stop as
  /// soon as there's nothing left to show or nobody listening.
  Stream<AiVerdict> verdicts(ScoreRequest request) {
    final out = StreamController<AiVerdict>();
    final skip = unavailable;
    if (skip != null) {
      out.add(AiOffline(skip));
      unawaited(out.close());
      return out.stream;
    }
    var offlineShown = false;
    Timer? soon;
    Timer? giveUp;
    void finish() {
      soon?.cancel();
      giveUp?.cancel();
      if (!out.isClosed) unawaited(out.close());
    }

    soon = Timer(timeout, () {
      offlineShown = true;
      out.add(const AiOffline(AiFallbackReason.timeout));
    });
    giveUp = Timer(lateLimit, finish);
    out.onCancel = finish;
    unawaited(
      _ask(request, null).then((verdict) {
        if (out.isClosed) return;
        // After the offline score, only a real verdict is worth replacing it with.
        if (!offlineShown || verdict is AiScored) out.add(verdict);
        finish();
      }),
    );
    return out.stream;
  }

  /// One call to the backend; [limit] null leaves the waiting to the caller's timers.
  Future<AiVerdict> _ask(ScoreRequest request, Duration? limit) async {
    try {
      final call = backend().scoreAnswer(request.toJson());
      final json = await (limit == null ? call : call.timeout(limit));
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
