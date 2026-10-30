import 'package:engine/engine.dart';

import '../interviewer.dart';

/// Priya, the recruiter: warm, brisk, and listening for whether you answered *her* question
/// (brief §5). She runs Missions 1–3 and co-leads the Mission 7 review.
const priya = Interviewer(
  id: priyaId,
  name: 'Priya',
  role: 'Recruiter',
  voice:
      'Warm and brisk: short sentences, your first name, and she steers you back the moment '
      'you drift.',
  tests: {Dimension.relevance, Dimension.structure},
);

/// Priya's id, for the scene lines she speaks (an id is needed in a const, where
/// `priya.id` can't be read). Brief 09 keys typing sounds by them, so they never change.
const String priyaId = 'priya';

/// Every interviewer, in the order they appear in the campaign.
const List<Interviewer> interviewers = [priya];
