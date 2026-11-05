// The rooms a score can be for: every mission id in packages/content, by how it's answered.
// A verdict is stored with its mission id and the leaderboard credits each mission once, so an
// invented id must never be scored (issue 74). Kept in step with the content by
// packages/content/test/function_missions_test.dart: a new mission fails that test until it's here.

/** Missions answered by picking lines: the `score` function. */
export const CHOICE_MISSION_IDS: ReadonlySet<string> = new Set([
  'm01_the_opportunity',
  'm02_tell_me_about_yourself',
  'm03_the_experience_gap',
  'm04_show_me_the_evidence',
  'm05_something_went_wrong',
  'm06_the_follow_up_trap',
  'm07_first_round_review',
  'm15_solve_the_problem',
  'm18_the_salary_question',
  'm19_your_turn_to_ask',
]);

/** Missions answered out loud: the `score-voice` function. */
export const VOICE_MISSION_IDS: ReadonlySet<string> = new Set([
  'm08_team_conflict',
  'm09_the_failure',
  'm10_no_clear_instructions',
  'm11_tight_deadline',
  'm12_the_uncomfortable_request',
  'm13_the_unexpected_follow_up',
  'm14_panel_review',
  'm16_the_interruption',
  'm17_i_dont_know',
  'm20_the_final_interview',
  'm21_the_decision',
]);
