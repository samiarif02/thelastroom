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

/// Marcus, the hiring manager: dry and exact. He runs Missions 4–5 and co-leads the review.
const marcus = Interviewer(
  id: marcusId,
  name: 'Marcus',
  role: 'Hiring Manager',
  voice:
      'Dry and exact: asks for the number, then for whose number it was. Never raises his '
      'voice.',
  tests: {Dimension.specificity, Dimension.relevance},
);

/// Lena, the senior engineer: skeptical. She runs Mission 6, the follow-up trap.
const lena = Interviewer(
  id: lenaId,
  name: 'Lena',
  role: 'Senior Engineer',
  voice: 'Quiet and skeptical: repeats your own words back to you, then asks what is missing.',
  tests: {Dimension.adaptability, Dimension.specificity},
);

/// Sam, the head of product: the final round (Chapter 3). In v1 only the locked teaser
/// names them.
const sam = Interviewer(
  id: samId,
  name: 'Sam',
  role: 'Head of Product',
  voice: 'Calm, slow, a high bar: lets a silence sit, then asks the one question that matters.',
  tests: {
    Dimension.relevance,
    Dimension.specificity,
    Dimension.structure,
    Dimension.adaptability,
  },
);

/// The interviewers' ids, for the scene lines they speak (an id is needed in a const, where
/// `priya.id` can't be read). Brief 09 keys typing sounds by them, so they never change.
const String priyaId = 'priya';
const String marcusId = 'marcus';
const String lenaId = 'lena';
const String samId = 'sam';

/// Every interviewer, in the order they appear in the campaign.
const List<Interviewer> interviewers = [priya, marcus, lena, sam];
