import 'identified.dart';

/// The one concrete lesson a debrief teaches (FR-15), and the Recall Room card that checks it
/// later (FR-40).
class Lesson implements Identified {
  const Lesson({
    required this.id,
    required this.title,
    required this.takeaway,
    required this.recall,
  });

  @override
  final String id;
  final String title;

  /// One or two sentences: what to do differently next time.
  final String takeaway;
  final RecallCheck recall;
}

/// A quick question that shows whether a lesson stuck, without hints.
class RecallCheck {
  const RecallCheck({
    required this.prompt,
    required this.options,
    required this.correctOptionId,
  });

  final String prompt;
  final List<RecallOption> options;
  final String correctOptionId;
}

class RecallOption implements Identified {
  const RecallOption({required this.id, required this.text});

  @override
  final String id;
  final String text;
}
