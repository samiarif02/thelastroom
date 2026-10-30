import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/subtitle/typewriter_subtitle.dart';
import '../audio_providers.dart';
import '../typing_voice.dart';
import 'sound_board_widgets.dart';

/// The four interviewers' typing voices, each typing a sample line through the real
/// typewriter subtitle. Tap the line to complete it: the ticks stop at once.
class SoundBoardTyping extends ConsumerStatefulWidget {
  const SoundBoardTyping({super.key});

  static const Map<TypingVoice, (String, String)> samples = {
    TypingVoice.priya: (
      'PRIYA',
      'So… tell me what drew you to this role, in your own words.',
    ),
    TypingVoice.marcus: (
      'MARCUS',
      'Walk me through the numbers. What changed, and how do you know?',
    ),
    TypingVoice.lena: (
      'LENA',
      'That was the team. I asked what you did… specifically.',
    ),
    TypingVoice.sam: (
      'SAM',
      'Last question. Why should this be your room, and not theirs?',
    ),
  };

  @override
  ConsumerState<SoundBoardTyping> createState() => _SoundBoardTypingState();
}

class _SoundBoardTypingState extends ConsumerState<SoundBoardTyping> {
  TypingVoice? _voice;
  int _take = 0;
  final TypewriterController _controller = TypewriterController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _type(TypingVoice voice) => setState(() {
    _voice = voice;
    _take++;
  });

  @override
  Widget build(BuildContext context) {
    final sounds = ref.watch(audioGameSoundsProvider);
    final voice = _voice;
    final sample = voice == null ? null : SoundBoardTyping.samples[voice];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoardButtons(
          children: [
            for (final v in TypingVoice.values)
              BoardButton(
                label: 'Type: ${v.name}',
                active: v == _voice,
                onTap: () => _type(v),
              ),
          ],
        ),
        const SizedBox(height: BrandSpace.md),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BrandSpace.xxl * 1.5),
          child: voice == null || sample == null
              ? const SizedBox.shrink()
              : Listener(
                  // The typewriter completes itself on tap; this hears the same tap first.
                  onPointerDown: (_) {
                    if (!_controller.isComplete) sounds.subtitleCompleted();
                  },
                  child: TypewriterSubtitle(
                    key: ValueKey(_take),
                    speaker: sample.$1,
                    line: sample.$2,
                    controller: _controller,
                    onCharacter: (char, _) =>
                        sounds.subtitleCharacter(voice.name, char),
                  ),
                ),
        ),
      ],
    );
  }
}
