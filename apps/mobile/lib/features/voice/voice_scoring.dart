import 'dart:async';
import 'dart:convert';

import 'package:content/content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/backend/backend.dart';
import '../../core/env/env.dart';
import '../../core/logging/log.dart';
import '../debrief/ai_score.dart';
import '../mission/mission_lookup.dart';
import 'recorder/take_recorder.dart';

/// What `score-voice` is sent (brief 35): the questions, the points to listen for, and the two
/// recordings as base64 WAV. Never the player's name: the questions are content, unaddressed.
class VoiceScoreRequest {
  const VoiceScoreRequest({
    required this.mission,
    required this.answer,
    required this.reply,
  });

  final Mission mission;
  final Take answer;
  final Take reply;

  static const String mimeType = 'audio/wav';

  Map<String, Object?> toJson() {
    final voice = mission.voice!;
    List<Map<String, Object?>> points(List<ListenFor> list) => [
      for (final p in list)
        {'id': p.id, 'text': p.text, 'dimension': p.dimension.name},
    ];
    return {
      'mission_id': mission.id,
      'hiring_for': ScoreRequest.hiringFor,
      'interviewer_role': interviewerById(mission.question.speakerId).role,
      'question': mission.question.text,
      'listen_for': points(voice.listenFor),
      'follow_up_question': voice.followUp.text,
      'follow_up_listen_for': points(voice.followUpListenFor),
      'answer_audio': base64Encode(answer.wav),
      'reply_audio': base64Encode(reply.wav),
      'mime_type': mimeType,
      'max_seconds': voice.maxSeconds,
      'attempt_id': null,
    };
  }
}

/// The recruiter's verdict on a spoken answer: the scores and their basis (an [AiScore], as on
/// the Chapter 1 dossier), what was heard, and which points were made.
class VoiceVerdict {
  const VoiceVerdict({
    required this.score,
    required this.answerTranscript,
    required this.replyTranscript,
    required this.pointsMade,
  });

  final AiScore score;
  final String answerTranscript;
  final String replyTranscript;

  /// Ids of the mission's listen-for points the answer made, in content order.
  final List<String> pointsMade;

  /// Parses the function's JSON; null for anything that isn't a complete verdict. Point ids
  /// that aren't [mission]'s are dropped.
  static VoiceVerdict? fromJson(Object? json, Mission mission) {
    if (json is! Map<String, Object?>) return null;
    final score = AiScore.fromJson(json);
    final transcript = json['transcript'];
    final made = json['points_made'];
    if (score == null || transcript is! Map<String, Object?> || made is! List) {
      return null;
    }
    final answer = transcript['answer'];
    final reply = transcript['reply'];
    if (answer is! String || reply is! String) return null;
    final voice = mission.voice;
    if (voice == null) return null;
    final said = {for (final id in made) '$id'};
    return VoiceVerdict(
      score: score,
      answerTranscript: answer.trim(),
      replyTranscript: reply.trim(),
      pointsMade: [
        for (final p in [...voice.listenFor, ...voice.followUpListenFor])
          if (said.contains(p.id)) p.id,
      ],
    );
  }
}

/// What scoring a spoken answer came to: the AI's verdict, or a reason to self-check.
sealed class VoiceOutcome {
  const VoiceOutcome();
}

class VoiceScored extends VoiceOutcome {
  const VoiceScored(this.verdict);

  final VoiceVerdict verdict;
}

class VoiceSelfCheck extends VoiceOutcome {
  const VoiceSelfCheck(this.reason);

  final SelfCheckReason reason;
}

/// Why the player ticks their own points instead of the AI listening. Each is a designed line
/// on the self-check, never an error.
enum SelfCheckReason {
  /// No backend configured: the zero-setup run.
  noBackend,

  /// Not signed in (offline since launch).
  noSession,

  /// No answer within [VoiceScorer.timeout].
  timeout,

  /// The day's AI scores are spent.
  limited,

  /// Anything else the function or the network did.
  error,

  /// The microphone was refused, so there's no recording to send.
  noMicrophone;

  static SelfCheckReason of(AiFallbackReason reason) => switch (reason) {
    AiFallbackReason.noBackend => noBackend,
    AiFallbackReason.noSession => noSession,
    AiFallbackReason.timeout => timeout,
    AiFallbackReason.limited => limited,
    AiFallbackReason.error => error,
  };
}

/// Asks `score-voice` for a verdict, and never fails: every problem is a [VoiceSelfCheck].
class VoiceScorer {
  const VoiceScorer({
    required this.env,
    required this.session,
    required this.backend,
    required this.log,
  });

  final Env env;
  final BackendSession session;
  final Backend Function() backend;
  final Log log;

  /// The longest the player waits for the recruiter to listen. Longer than the text score's 8 s:
  /// up to three minutes of audio is uploaded and transcribed (the function gives Gemini 25 s).
  static const Duration timeout = Duration(seconds: 30);

  static const int _tooManyRequests = 429;

  /// Why there's no point asking, known at once (no waiting), or null.
  SelfCheckReason? get unavailable {
    if (!env.hasSupabase) return SelfCheckReason.noBackend;
    if (session is! GuestSession) return SelfCheckReason.noSession;
    return null;
  }

  Future<VoiceOutcome> score(VoiceScoreRequest request) async {
    final skip = unavailable;
    if (skip != null) return VoiceSelfCheck(skip);
    try {
      final json = await backend()
          .scoreVoiceAnswer(request.toJson())
          .timeout(timeout);
      final verdict = VoiceVerdict.fromJson(json, request.mission);
      if (verdict == null) {
        log.warn('voice score malformed');
        return const VoiceSelfCheck(SelfCheckReason.error);
      }
      return VoiceScored(verdict);
    } on TimeoutException {
      return const VoiceSelfCheck(SelfCheckReason.timeout);
    } on ScoreRefused catch (refused) {
      log.warn('voice score refused', {
        'status': refused.status,
        'code': refused.code,
      });
      return VoiceSelfCheck(
        refused.status == _tooManyRequests
            ? SelfCheckReason.limited
            : SelfCheckReason.error,
      );
    } on Object catch (error) {
      log.warn('voice score failed', {'error': '${error.runtimeType}'});
      return const VoiceSelfCheck(SelfCheckReason.error);
    }
  }
}

final voiceScorerProvider = Provider<VoiceScorer>(
  (ref) => VoiceScorer(
    env: ref.watch(envProvider),
    session: ref.watch(sessionProvider),
    backend: () => ref.read(backendProvider),
    log: ref.watch(logProvider),
  ),
);
