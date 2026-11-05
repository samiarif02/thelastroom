import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/film/anchored_scroll.dart';
import 'explainer_art.dart';
import 'explainer_art_progress.dart';
import 'explainer_copy.dart';

/// "How it works" (issue 75): five swipeable pages, each one idea with a moment from the cast,
/// before onboarding's questions, and again from Settings. Dots, Back, Skip and swipe; under
/// reduced motion the buttons cut between pages instead of sliding. When it ends (the last
/// page's button, Skip, or Close on a replay) it fires `onboarding_explainer_viewed` once and
/// calls [onDone].
class ExplainerDeck extends ConsumerStatefulWidget {
  const ExplainerDeck({
    super.key,
    required this.onDone,
    this.replay = false,
    this.initialPage = 0,
  });

  /// The deck has ended; [skipped] when Skip or Close ended it before the last page's button.
  final void Function({required bool skipped}) onDone;

  /// Settings brought it back: no Skip (Close does that), and the last button says "Done".
  final bool replay;
  final int initialPage;

  /// Each page's floor: its tint is the ground, its colours the kit's.
  static const List<FloorColours> floors = [
    DaylightFloors.one,
    DaylightFloors.two,
    DaylightFloors.three,
    DaylightFloors.one,
    DaylightFloors.two,
  ];

  static int get length => ExplainerCopy.pages.length;

  @override
  ConsumerState<ExplainerDeck> createState() => ExplainerDeckState();
}

class ExplainerDeckState extends ConsumerState<ExplainerDeck> {
  late final PageController _pages = PageController(
    initialPage: widget.initialPage,
  );
  late int _at = widget.initialPage;
  late int _furthest = widget.initialPage;
  bool _ended = false;

  static const double _maxWidth = 520;

  GameSounds get _sounds => ref.read(gameSoundsProvider);
  bool get _last => _at == ExplainerDeck.length - 1;

  /// The page showing, from 0.
  int get page => _at;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _turned(int page) {
    _sounds.pageTurn();
    setState(() {
      _at = page;
      if (page > _furthest) _furthest = page;
    });
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: DaylightMotion.move,
        curve: DaylightMotion.ease,
      );
    }
  }

  void _next() {
    _sounds.uiTap();
    if (_last) {
      _end(skipped: false);
    } else {
      _goTo(_at + 1);
    }
  }

  void _skip() {
    _sounds.uiTap();
    _end(skipped: true);
  }

  /// Android back and the Back tile: the page before; false on the first page.
  bool back() {
    if (_at == 0) return false;
    _goTo(_at - 1);
    return true;
  }

  /// Ends the deck (a replay's Close, or back on its first page counts as a skip).
  void close() => _end(skipped: true);

  void _end({required bool skipped}) {
    if (_ended) return;
    _ended = true;
    ref.read(analyticsProvider).track(
      AnalyticsEvent.onboardingExplainerViewed,
      {
        'page': EventValue.count(_furthest + 1),
        'skipped': EventValue.flag(skipped),
        'replay': EventValue.flag(widget.replay),
      },
    );
    widget.onDone(skipped: skipped);
  }

  @override
  Widget build(BuildContext context) {
    final f = ExplainerDeck.floors[_at];
    final leading = _at > 0
        ? IconTile(
            icon: PhosphorBold.arrowLeft,
            semanticLabel: ExplainerCopy.back,
            nudge: AxisDirection.left,
            onPressed: () {
              _sounds.uiTap();
              back();
            },
          )
        : widget.replay
        ? IconTile(
            icon: PhosphorBold.x,
            semanticLabel: ExplainerCopy.close,
            onPressed: _skip,
          )
        : const SizedBox.square(dimension: DaylightSize.hit);
    final showSkip = !widget.replay && !_last;
    return DaylightGround(
      floor: f,
      child: AnimatedContainer(
        duration: DaylightMotion.colour,
        curve: DaylightMotion.ease,
        color: f.tint,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            DaylightSpace.s16,
            DaylightSpace.s8,
            DaylightSpace.s16,
            DaylightSpace.s24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      leading,
                      const SizedBox(width: DaylightSpace.s12),
                      Expanded(
                        child: _Dots(at: _at, of: ExplainerDeck.length),
                      ),
                      const SizedBox(width: DaylightSpace.s12),
                      // Holds its place on the last page, so the dots don't jump.
                      Opacity(
                        opacity: showSkip ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !showSkip,
                          child: ExcludeSemantics(
                            excluding: !showSkip,
                            child: TactileButton(
                              label: ExplainerCopy.skip,
                              tone: TactileTone.quiet,
                              compact: true,
                              expand: false,
                              onPressed: _skip,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(overscroll: false),
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: ExplainerDeck.length,
                        onPageChanged: _turned,
                        itemBuilder: (context, i) => ChapterTint(
                          floor: ExplainerDeck.floors[i],
                          child: _Page(index: i),
                        ),
                      ),
                    ),
                  ),
                  TactileButton(
                    label: _last
                        ? (widget.replay
                              ? ExplainerCopy.done
                              : ExplainerCopy.ready)
                        : ExplainerCopy.next,
                    icon: _last && widget.replay
                        ? PhosphorBold.check
                        : PhosphorBold.arrowRight,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One page: the art, then the kicker, the idea and its line, arriving one after another. It
/// scrolls only when it doesn't fit (2x text).
class _Page extends StatelessWidget {
  const _Page({required this.index});

  final int index;

  static const List<Widget> _art = [
    TowerArt(),
    RoomArt(),
    ScoreArt(),
    RecallArt(),
    RewardsArt(),
  ];

  @override
  Widget build(BuildContext context) {
    final copy = ExplainerCopy.pages[index];
    final f = ExplainerDeck.floors[index];
    return AnchoredScroll(
      alignment: MainAxisAlignment.center,
      padding: const EdgeInsets.symmetric(vertical: DaylightSpace.s16),
      children: [
        Entrance(child: _art[index]),
        const SizedBox(height: DaylightSpace.s24),
        Entrance(
          index: 1,
          child: Text(
            copy.kicker,
            style: DaylightType.caption3.copyWith(color: f.deep),
          ),
        ),
        const SizedBox(height: DaylightSpace.s8),
        Entrance(
          index: 2,
          child: Semantics(
            header: true,
            child: Text(copy.title, style: DaylightType.heading4),
          ),
        ),
        const SizedBox(height: DaylightSpace.s8),
        Entrance(
          index: 3,
          child: Text(
            copy.line,
            style: DaylightType.body4.copyWith(color: DaylightColors.ink2),
          ),
        ),
      ],
    );
  }
}

/// Where you are in the deck: a dot a page, the current one a wide bar in the floor's colour.
class _Dots extends StatelessWidget {
  const _Dots({required this.at, required this.of});

  final int at;
  final int of;

  static const double _dot = 8;
  static const double _wide = 24;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: ExplainerCopy.pageOf(at + 1, of),
      excludeSemantics: true,
      // Narrow phones at 2x text leave the dots little room: they shrink rather than overflow.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < of; i++) ...[
              if (i > 0) const SizedBox(width: DaylightSpace.s4),
              AnimatedContainer(
                duration: still ? Duration.zero : DaylightMotion.colour,
                curve: DaylightMotion.ease,
                width: i == at ? _wide : _dot,
                height: _dot,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_dot / 2),
                  color: i <= at ? f.base : DaylightColors.sand2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
