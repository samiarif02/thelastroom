import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';
import '../title/title_screen.dart';
import 'answer_card_demo.dart';
import 'boardroom_scene_demo.dart';
import 'catalog_backdrops.dart';
import 'catalog_entry.dart';
import 'sample_mission.dart';
import 'vivid_entries.dart';

/// Every film-kit component in every state worth seeing: the catalog's pages, and the golden
/// tests' list (`test/features/dev_catalog/catalog_golden_test.dart`), so a component added
/// here is screenshotted without another line of test.
abstract final class CatalogEntries {
  static final List<CatalogEntry> all = [
    _title,
    _scene,
    _camera,
    _people,
    _light,
    _letterbox,
    _subtitle,
    _answers,
    _paper,
    _brass,
    _states,
    _film,
    VividEntries.kit,
    VividEntries.tower,
    VividEntries.screens,
  ];

  static CatalogEntry? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  // A beat after the title card's choreography, so its golden is the settled card.
  static const Duration _afterTitle = Duration(milliseconds: 4800);
  static const Duration _afterDossier = Duration(milliseconds: 4800);
  static const Duration _afterScene = Duration(seconds: 10);
  static const Duration _midLine = Duration(milliseconds: 900);
  static const Duration _lampSettles = Duration(milliseconds: 200);

  static const double _lampWidth = 180;
  static const double _sealSize = 96;
  static const double _stampAngle = -0.08;

  static final CatalogEntry _title = CatalogEntry(
    id: 'title',
    name: 'Title card',
    note:
        'ChapterTitleCard + TrackedTitle: the mug, a double frame, a title that never breaks a word. '
        'onTitleLanded, onFinished. The chapter shots keep their own grade.',
    shots: [
      CatalogShot(
        id: 'home',
        label: 'Home',
        settle: _afterTitle,
        build: (_) => const TitleScreen(),
      ),
      for (final (id, label, eyebrow, title, grade) in _chapters)
        CatalogShot(
          id: id,
          label: label,
          settle: _afterTitle,
          build: (_) => ChapterTitleCard(
            eyebrow: eyebrow,
            title: title,
            subtitle: 'in which we meet ${SampleMission.interviewer}',
            grade: grade,
          ),
        ),
    ],
  );

  static const List<(String, String, String, String, ChapterGrade)> _chapters =
      [
        (
          'chapter-one',
          'Ch. 1',
          'CHAPTER ONE',
          'GET THROUGH THE DOOR',
          ChapterGrade.lobby,
        ),
        (
          'chapter-two',
          'Ch. 2',
          'CHAPTER TWO',
          'UNDER PRESSURE',
          ChapterGrade.pressure,
        ),
        (
          'chapter-three',
          'Ch. 3',
          'CHAPTER THREE',
          'THE FINAL ROUND',
          ChapterGrade.finalRound,
        ),
      ];

  static final CatalogEntry _scene = CatalogEntry(
    id: 'scene',
    name: 'Scene',
    note:
        'The kit composed: bars, typed line, dolly push, plaques; lock an answer for the '
        'follow-up on a hard cut. Tap the scene to skip a beat.',
    shots: [
      CatalogShot(
        id: 'mission-one',
        label: 'Mission 1',
        settle: _afterScene,
        build: (grade) => BoardroomScene(grade: grade),
      ),
    ],
  );

  static final CatalogEntry _camera = CatalogEntry(
    id: 'camera',
    name: 'Camera',
    note:
        'CameraRig, DollyCamera (onPushStart, onPushEnd), HardCut (onCut) over BoardroomSet: '
        'three parallax planes.',
    shots: [
      CatalogShot(
        id: 'wide',
        label: 'Wide',
        build: (grade) => CatalogRoom(grade: grade),
      ),
      CatalogShot(
        id: 'close',
        label: 'Close',
        build: (grade) => CatalogRoom(grade: grade, t: 1),
      ),
      CatalogShot(
        id: 'tight',
        label: 'Tight',
        build: (grade) => CatalogRoom(grade: grade, t: 1, tight: true),
      ),
    ],
  );

  static final CatalogEntry _people = CatalogEntry(
    id: 'people',
    name: 'The cast',
    note:
        'FriendlyInterviewer (brief 16): Priya, Marcus and Lena drawn in code, five '
        'expressions, idle = breath, blink, a little sway. Reduced motion stills it.',
    shots: [
      for (final expression in InterviewerExpression.values)
        CatalogShot(
          id: expression.name,
          label:
              expression.name[0].toUpperCase() + expression.name.substring(1),
          build: (grade) => CatalogDesk(
            grade: grade,
            children: [
              Row(
                children: [
                  for (final figure in FriendlyFigure.byId.values)
                    Expanded(
                      child: FriendlyInterviewer(
                        figure: figure,
                        expression: expression,
                        grade: grade,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
    ],
  );

  static final CatalogEntry _light = CatalogEntry(
    id: 'light',
    name: 'Light',
    note:
        'BankersLamp: the desk mug (hot / cold for offline), Spotlight: the pool of sun, '
        'Bokeh.',
    shots: [
      for (final lit in [true, false])
        CatalogShot(
          id: lit ? 'lamp-lit' : 'lamp-off',
          label: lit ? 'Mug' : 'Mug, cold',
          settle: _lampSettles,
          build: (grade) => CatalogDesk(
            grade: grade,
            children: [
              Center(
                child: SizedBox(
                  width: _lampWidth,
                  child: BankersLamp(grade: grade, lit: lit),
                ),
              ),
            ],
          ),
        ),
      CatalogShot(
        id: 'spotlight',
        label: 'Pool',
        build: (grade) => ColoredBox(
          color: BrandColors.surface,
          child: Spotlight(grade: grade),
        ),
      ),
      CatalogShot(
        id: 'bokeh',
        label: 'Bokeh',
        build: (grade) => ColoredBox(
          color: BrandColors.void_,
          child: Bokeh(colors: [grade.key, grade.tint]),
        ),
      ),
    ],
  );

  static final CatalogEntry _letterbox = CatalogEntry(
    id: 'letterbox',
    name: 'Letterbox',
    note: 'Letterbox (t) and AnimatedLetterbox (shown, onSettled): 13% cinema bars.',
    shots: [
      for (final (id, label, t) in [
        ('bars', 'Bars', 1.0),
        ('half', 'Halfway', 0.5),
      ])
        CatalogShot(
          id: id,
          label: label,
          build: (grade) => CatalogRoom(
            grade: grade,
            overlay: Letterbox(t: t),
          ),
        ),
    ],
  );

  static final CatalogEntry _subtitle = CatalogEntry(
    id: 'subtitle',
    name: 'Subtitle',
    note:
        'TypewriterSubtitle: speaker in small caps, 30 ms a character. onCharacter(char, i), '
        'onComplete; a tap completes the line.',
    shots: [
      for (final (id, label, play, settle) in [
        ('typing', 'Typing', true, _midLine),
        ('typed', 'Typed', false, BrandMotion.cinematic),
      ])
        CatalogShot(
          id: id,
          label: label,
          settle: settle,
          build: (grade) => CatalogRoom(
            grade: grade,
            t: 1,
            overlay: _LowerThird(
              child: TypewriterSubtitle(
                speaker: SampleMission.interviewer,
                line: SampleMission.line,
                grade: grade,
                play: play,
              ),
            ),
          ),
        ),
    ],
  );

  static final CatalogEntry _answers = CatalogEntry(
    id: 'answers',
    name: 'Answer cards',
    note: 'AnswerCard: idle, focused, selected, locked, disabled. onTap.',
    shots: [
      CatalogShot(
        id: 'states',
        label: 'States',
        build: (grade) => CatalogSky(
          children: [
            for (final state in AnswerCardState.values) ...[
              CatalogCaption(state.name),
              AnswerCard(
                numeral: AnswerCard.numeralFor(state.index),
                text: SampleMission.answers.last,
                state: state,
                grade: grade,
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
      CatalogShot(
        id: 'try',
        label: 'Try it',
        build: (grade) => CatalogSky(children: [AnswerCardDemo(grade: grade)]),
      ),
    ],
  );

  static final CatalogEntry _paper = CatalogEntry(
    id: 'paper',
    name: 'Dossier',
    note:
        'Dossier: letterhead slides in, scores stamped, total sealed, pen note. onStamp(i), '
        'onSeal, onPen, onFinished. WaxSeal, StampIn, PenNote.',
    shots: [
      CatalogShot(
        id: 'dossier',
        label: 'Dossier',
        settle: _afterDossier,
        build: (grade) => CatalogDesk(
          grade: grade,
          children: const [
            Dossier(
              title: 'Candidate assessment',
              subtitle:
                  '${SampleMission.mission} · with ${SampleMission.interviewer}',
              scores: SampleMission.scores,
              total: SampleMission.total,
              note: SampleMission.note,
              markedIndex: SampleMission.weakestIndex,
            ),
          ],
        ),
      ),
      CatalogShot(
        id: 'seal-stamp-pen',
        label: 'Seal',
        build: (grade) => CatalogDesk(
          grade: grade,
          children: [
            const Center(
              child: WaxSeal(value: SampleMission.total, size: _sealSize),
            ),
            const SizedBox(height: BrandSpace.lg),
            const Center(
              child: StampIn(
                t: 1,
                angle: _stampAngle,
                child: Text('FILED', style: BrandType.stamp),
              ),
            ),
            const SizedBox(height: BrandSpace.lg),
            const Center(child: PenNote(text: SampleMission.note, t: 1)),
          ],
        ),
      ),
    ],
  );

  static final CatalogEntry _brass = CatalogEntry(
    id: 'brass',
    name: 'Brass',
    note:
        "BrassOrnament and DoubleRule: the room's engraved pieces (the title card, the dossier), "
        "on the room's own cream. BrassButton is the vivid pill now (see Vivid kit).",
    shots: [
      CatalogShot(
        id: 'ornaments',
        label: 'Ornaments',
        build: (grade) => CatalogDesk(
          grade: grade,
          children: [
            Center(
              child: BrassOrnament(text: 'CHAPTER ONE', grade: grade),
            ),
            const SizedBox(height: BrandSpace.lg),
            DoubleRule(color: grade.key),
          ],
        ),
      ),
    ],
  );

  static final CatalogEntry _states = CatalogEntry(
    id: 'states',
    name: 'States',
    note:
        'SceneState: loading, empty, offline, error, in the film language. onAction adds a '
        'BrassButton.',
    shots: [
      CatalogShot(
        id: 'loading',
        label: 'Loading',
        build: (grade) => SceneState.loading(grade: grade),
      ),
      CatalogShot(
        id: 'empty',
        label: 'Empty',
        build: (grade) => SceneState.empty(grade: grade),
      ),
      CatalogShot(
        id: 'offline',
        label: 'Offline',
        build: (grade) => SceneState.offline(grade: grade, onAction: () {}),
      ),
      CatalogShot(
        id: 'error',
        label: 'Error',
        build: (grade) => SceneState.error(grade: grade, onAction: () {}),
      ),
    ],
  );

  static final CatalogEntry _film = CatalogEntry(
    id: 'film',
    name: 'Film stock',
    note:
        'FilmOverlay: grain at film rate + the elliptical vignette (under text, never over '
        'it). AmbientClock drives grain, flicker and breathing.',
    shots: [
      CatalogShot(
        id: 'grain-vignette',
        label: 'Grain',
        build: (grade) => FilmOverlay(
          vignetteColor: grade.shadow,
          child: CameraRig(
            t: 0,
            layers: BoardroomSet.layers(
              figure: SilhouetteFigure.priya,
              grade: grade,
            ),
          ),
        ),
      ),
    ],
  );
}

/// A subtitle low in frame over a scrim, like the scene's.
class _LowerThird extends StatelessWidget {
  const _LowerThird({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          BrandColors.void_.withValues(alpha: 0),
          BrandColors.void_.withValues(alpha: 0.94),
        ],
        stops: const [0.45, 0.8],
      ),
    ),
    child: SafeArea(
      child: AnchoredScroll(
        padding: const EdgeInsets.all(BrandSpace.lg),
        children: [child],
      ),
    ),
  );
}
