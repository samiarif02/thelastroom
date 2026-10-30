"""The cue sheet (docs/sound-design.md) as synthesis recipes.

Each recipe is registered with `@cue(name, bus, lufs, describe)`. `name` is the asset's base name
(`apps/mobile/assets/audio/{ogg,m4a}/<name>.*`) and must match `Cue.asset` in
`apps/mobile/lib/core/audio/cue.dart`. Loudness targets follow the spec (effects about -16 LUFS,
ambience about -24 LUFS); the quiet repeating ticks sit lower on purpose ("soft, muted").
"""

import math

import numpy as np

from dsp import (
    additive,
    band,
    bandpass,
    brown,
    circular_reverb,
    decay,
    fade,
    fft_filter,
    highpass,
    loop_noise,
    lowpass,
    osc,
    periodic_freq,
    periodic_lfo,
    pink,
    place,
    reverb,
    samples,
    saturate,
    saw_band_limited,
    silence,
    spectral_noise,
    sweep_filter,
    swell,
    timeline,
    white,
)

CUES = []

EFFECTS = "effects"
AMBIENCE = "ambience"

EFFECT_LUFS = -16.0
AMBIENCE_LUFS = -24.0
STING_LUFS = -20.0
TICK_LUFS = -27.0

LOOP_SECONDS = 16.0


def cue(name, bus, lufs, describe, loop=False):
    def register(fn):
        CUES.append(
            {
                "name": name,
                "bus": bus,
                "lufs": lufs,
                "describe": describe,
                "loop": loop,
                "fn": fn,
            }
        )
        return fn

    return register


def note(name):
    """'A4' -> Hz. Sharps only."""
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    pitch, octave = name[:-1], int(name[-1])
    semitone = names.index(pitch) + 12 * (octave + 1)
    return 440.0 * 2 ** ((semitone - 69) / 12)


# --- shared voices -------------------------------------------------------------------------------


def piano_note(r, freq, seconds, velocity=0.6):
    """A soft felt-piano note: stretched partials, faster decay up high, a hammer thump."""
    partials = [
        (n, (1 / n**1.3) * (velocity ** (n * 0.25)), 2.8 / (1 + 0.55 * (n - 1)))
        for n in range(1, 14)
    ]
    body = additive(freq, seconds, partials, inharmonicity=0.0004, phase_seed=1)
    hammer = lowpass(white(r, seconds) * decay(seconds, 0.012), 900) * 0.25
    return (body + hammer) * decay(seconds, 3.2, attack=0.004)


def bell(freq, seconds, tau=1.2):
    """An inharmonic glass bell (ratios of a small struck bar)."""
    ratios = [(1.0, 1.0, tau), (2.76, 0.45, tau * 0.5), (5.40, 0.22, tau * 0.3), (8.93, 0.1, tau * 0.18)]
    out = np.zeros(samples(seconds))
    for ratio, amp, d in ratios:
        out += amp * osc(freq * ratio, seconds) * decay(seconds, d, attack=0.001)
    return out


def thump(r, seconds, freq_start, freq_end, tau, noise_cut=600, noise_amount=0.4):
    """A low body hit: a pitch-dropping sine plus a short burst of filtered noise."""
    t = timeline(seconds)
    glide = freq_end + (freq_start - freq_end) * np.exp(-t / 0.03)
    body = osc(glide, seconds) * decay(seconds, tau, attack=0.001)
    burst = lowpass(white(r, seconds) * decay(seconds, 0.01), noise_cut) * noise_amount
    return body + burst


def wood_tap(r, seconds, modes, tau_scale=1.0, click_cut=4000):
    """A struck piece of wood: a few damped resonant modes and a click."""
    out = np.zeros(samples(seconds))
    for freq, amp, tau in modes:
        out += amp * osc(freq * (1 + r.uniform(-0.01, 0.01)), seconds) * decay(seconds, tau * tau_scale, 0.0005)
    click = lowpass(white(r, seconds) * decay(seconds, 0.0015, 0), click_cut) * 0.6
    return out + click


def heartbeat(r, strength=1.0):
    seconds = 0.6
    lub = thump(r, 0.3, 75, 46, 0.07, noise_cut=200, noise_amount=0.15)
    dub = thump(r, 0.3, 70, 50, 0.055, noise_cut=200, noise_amount=0.1) * 0.65
    out = silence(seconds)
    place(out, lub, 0.0)
    place(out, dub, 0.19)
    return lowpass(out * strength, 400)


def pad_chord(r, freqs, seconds, brightness=900, detune=0.004, attack=1.2, release=1.0):
    """A soft analogue-ish pad: detuned band-limited saws through a low-pass."""
    out = np.zeros(samples(seconds))
    for f in freqs:
        for d in (-detune, 0, detune):
            out += saw_band_limited(f * (1 + d), seconds, max_harmonic=24) * (1 / len(freqs))
    out = lowpass(out, brightness)
    return out * swell(seconds, attack, release)


# --- typing voices (one muted key tick per interviewer) ------------------------------------------


@cue("type_priya", EFFECTS, TICK_LUFS, "Typing tick, Priya: a light, bright, muted key")
def type_priya(r):
    s = 0.05
    tick = bandpass(white(r, s) * decay(s, 0.004, 0), 3400, 1.6)
    ring = osc(2600, s) * decay(s, 0.008, 0.0005) * 0.25
    return highpass(tick + ring, 600)


@cue("type_marcus", EFFECTS, TICK_LUFS, "Typing tick, Marcus: a woodier key with a hollow body")
def type_marcus(r):
    s = 0.07
    return wood_tap(r, s, [(620, 0.8, 0.018), (1150, 0.45, 0.012), (2300, 0.15, 0.006)], click_cut=2500)


@cue("type_lena", EFFECTS, TICK_LUFS, "Typing tick, Lena: dry and tight, almost no ring")
def type_lena(r):
    s = 0.03
    tick = highpass(white(r, s) * decay(s, 0.0018, 0), 2200)
    return bandpass(tick, 4200, 0.9) + tick * 0.3


@cue("type_sam", EFFECTS, TICK_LUFS, "Typing tick, Sam: a deeper, heavier key")
def type_sam(r):
    s = 0.08
    body = wood_tap(r, s, [(260, 0.9, 0.022), (470, 0.5, 0.014), (900, 0.2, 0.008)], click_cut=1400)
    return lowpass(body, 2200)


# --- title, chapter card, cliffhanger ------------------------------------------------------------


def city_hum(r, seconds):
    rumble = spectral_noise(r, seconds, lambda f: brown(f) * band(30, 260, 3)(f))
    traffic = spectral_noise(r, seconds, lambda f: pink(f) * band(150, 900, 2)(f)) * 0.25
    mains = (osc(55, seconds) + 0.4 * osc(110, seconds)) * 0.06
    return rumble + traffic + mains


@cue("title_open", AMBIENCE, STING_LUFS, "Title: a distant city hum and one soft piano note that doesn't resolve")
def title_open(r):
    s = 7.5
    hum = city_hum(r, s) * swell(s, 1.8, 2.5, curve=1.5)
    out = hum * 0.7
    # B over an A hum: a suspended second, left hanging.
    note_b = piano_note(r, note("B3"), 5.5, velocity=0.5) * 0.9
    place(out, note_b, 1.4)
    return reverb(out, r, seconds=2.6, wet=0.35, brightness=0.8, tail=False)


@cue("chapter_card", AMBIENCE, STING_LUFS, "Chapter title card: a slow swelling pad, then one deep boom as the title settles")
def chapter_card(r):
    s = 5.5
    boom_at = 2.8
    out = silence(s)
    pad = pad_chord(r, [note("D3"), note("G3"), note("A3"), note("E4")], boom_at + 0.05, brightness=700, attack=2.6, release=0.05)
    place(out, pad * 0.8, 0)
    boom = thump(r, 2.6, 62, 34, 0.9, noise_cut=300, noise_amount=0.5)
    boom = saturate(boom * 1.2, 1.4)
    place(out, boom, boom_at)
    tail = pad_chord(r, [note("D2"), note("A2")], 2.6, brightness=400, attack=0.01, release=2.2) * 0.35
    place(out, tail, boom_at)
    return reverb(out, r, seconds=3.0, wet=0.3, brightness=0.6, tail=False)


@cue("cliffhanger", AMBIENCE, STING_LUFS, "Chapter end: music stops mid-phrase, a heartbeat, silence, then a phone buzz")
def cliffhanger(r):
    s = 6.5
    out = silence(s)
    # An unresolved chord (A-flat major 7 #11 over B-flat), cut off mid-phrase.
    phrase = pad_chord(r, [note("A#2"), note("G#3"), note("C4"), note("D4"), note("G4")], 1.3, brightness=1500, attack=0.5, release=0.0)
    phrase *= swell(1.3, 0.5, 0.012, curve=1.0)
    place(out, phrase * 0.9, 0)
    place(out, heartbeat(r) * 1.4, 1.75)
    buzz = phone_buzz(r)
    place(out, buzz, 4.0)
    return reverb(out, r, seconds=1.8, wet=0.22, brightness=0.6, tail=False)


def phone_buzz(r):
    """A phone vibrating on a wooden table in the next room: two short buzzes."""
    one = 0.38
    t = timeline(one)
    motor = np.sign(np.sin(2 * np.pi * 165 * t)) * 0.6 + osc(330, one) * 0.3
    rattle = bandpass(white(r, one), 1800, 2) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 165 * t)))
    buzz = lowpass(motor + rattle * 0.4, 1400) * swell(one, 0.02, 0.03, curve=1)
    out = silence(1.0)
    place(out, buzz, 0)
    place(out, buzz, 0.55)
    return lowpass(out, 900) * 0.8


# --- elevator ------------------------------------------------------------------------------------


@cue("elevator_doors_close", EFFECTS, EFFECT_LUFS, "Elevator: doors slide shut with a soft thud")
def elevator_doors_close(r):
    s = 0.95
    slide = sweep_filter(white(r, 0.6), "bandpass", 500, 1400, q=1.2) * swell(0.6, 0.35, 0.1)
    out = silence(s)
    place(out, slide * 0.35, 0)
    place(out, thump(r, 0.35, 95, 55, 0.07, noise_cut=500, noise_amount=0.6), 0.56)
    return reverb(out, r, seconds=0.5, wet=0.15, brightness=0.6, tail=False)


@cue("elevator_ride", EFFECTS, EFFECT_LUFS - 4, "Elevator: the car's hum while it climbs")
def elevator_ride(r):
    s = 3.6
    t = timeline(s)
    rise = 1 + 0.03 * t / s
    motor = osc(60 * rise, s) * 0.5 + osc(120 * rise, s) * 0.25 + osc(180 * rise, s) * 0.08
    air = spectral_noise(r, s, lambda f: pink(f) * band(80, 700, 2)(f)) * 0.5
    return (motor + air) * swell(s, 0.6, 0.8, curve=1.5)


@cue("elevator_floor_tick", EFFECTS, -22.0, "Elevator: the floor counter ticks over")
def elevator_floor_tick(r):
    s = 0.09
    return wood_tap(r, s, [(1250, 0.6, 0.01), (2900, 0.3, 0.005)], click_cut=6000) * 0.8


@cue("elevator_chime", EFFECTS, EFFECT_LUFS, "Elevator: arrival chime")
def elevator_chime(r):
    s = 2.0
    out = silence(s)
    place(out, bell(note("E5"), 1.8, tau=0.9) * 0.8, 0)
    place(out, bell(note("C5"), 1.6, tau=1.0) * 0.7, 0.28)
    return reverb(out, r, seconds=1.4, wet=0.25, tail=False)


@cue("elevator_doors_open", EFFECTS, EFFECT_LUFS, "Elevator: a clunk, then the doors open on a breath of air")
def elevator_doors_open(r):
    s = 1.0
    out = silence(s)
    place(out, thump(r, 0.2, 140, 90, 0.03, noise_cut=1200, noise_amount=0.5) * 0.6, 0)
    whoosh = sweep_filter(white(r, 0.85), "bandpass", 1400, 450, q=0.9) * swell(0.85, 0.15, 0.5)
    place(out, whoosh * 0.5, 0.1)
    return reverb(out, r, seconds=0.8, wet=0.2, brightness=0.7, tail=False)


# --- room ambience (seamless loops) --------------------------------------------------------------


def murmur(r, seconds):
    """Far-off voices: formant-shaped noise with a syllable-rate flutter, all periodic."""
    voices = np.zeros(samples(seconds))
    for k in range(5):
        formants = band(250 + 60 * k, 1100 + 120 * k, 3)
        n = loop_noise(r, seconds, formants)
        flutter = np.ones(samples(seconds))
        for cycles in r.integers(30, 90, 3):
            flutter *= periodic_lfo(seconds, int(cycles), 0.6, r.uniform(0, 2 * np.pi))
        talk = periodic_lfo(seconds, int(r.integers(2, 6)), 0.9, r.uniform(0, 2 * np.pi))
        voices += n * flutter * np.clip(talk, 0, None)
    return voices / 5


@cue("ambience_lobby", AMBIENCE, AMBIENCE_LUFS, "Chapter 1 room tone: warm lobby air and a faint office murmur", loop=True)
def ambience_lobby(r):
    s = LOOP_SECONDS
    air = loop_noise(r, s, lambda f: pink(f) * band(40, 700, 2)(f))
    hvac = (osc(periodic_freq(58, s), s) + 0.3 * osc(periodic_freq(116, s), s)) * 0.05
    out = air * 0.8 + hvac + murmur(r, s) * 0.22
    return circular_reverb(out, r, seconds=1.6, wet=0.3, brightness=0.7)


@cue("ambience_corridor", AMBIENCE, AMBIENCE_LUFS, "Chapter 2 room tone: a colder, tighter drone", loop=True)
def ambience_corridor(r):
    s = LOOP_SECONDS
    drone = np.zeros(samples(s))
    for freq, amp in [(73.4, 0.5), (110.0, 0.3), (146.8, 0.15), (155.6, 0.08)]:
        drone += amp * osc(periodic_freq(freq, s), s)
    drone *= periodic_lfo(s, 3, 0.25)
    hiss = loop_noise(r, s, band(2500, 7000, 3)) * 0.08
    cold_air = loop_noise(r, s, lambda f: pink(f) * band(60, 400, 2)(f)) * 0.5
    out = drone * 0.5 + hiss + cold_air
    return circular_reverb(out, r, seconds=1.0, wet=0.25, brightness=1.2)


@cue("ambience_boardroom", AMBIENCE, AMBIENCE_LUFS, "Chapter 3 boardroom: a deep low drone and a slow clock", loop=True)
def ambience_boardroom(r):
    s = LOOP_SECONDS
    drone = np.zeros(samples(s))
    for freq, amp in [(41.2, 0.6), (82.4, 0.35), (61.7, 0.25), (123.5, 0.1)]:
        drone += amp * osc(periodic_freq(freq, s), s)
    drone *= periodic_lfo(s, 2, 0.2)
    room = loop_noise(r, s, lambda f: brown(f) * band(30, 300, 2)(f)) * 0.5
    clock = silence(s)
    for k in range(int(s)):
        tick = wood_tap(r, 0.08, [(1900 if k % 2 == 0 else 1600, 0.6, 0.012), (4200, 0.2, 0.004)], click_cut=5000)
        place(clock, tick, k + 0.25)
    out = drone * 0.55 + room + clock * 0.18
    return circular_reverb(out, r, seconds=2.2, wet=0.3, brightness=0.6)


@cue("recall_pad", AMBIENCE, AMBIENCE_LUFS, "Recall Room: a soft low pad, a little brighter than the missions", loop=True)
def recall_pad(r):
    s = LOOP_SECONDS
    out = np.zeros(samples(s))
    for name, amp in [("C3", 0.5), ("G3", 0.35), ("E4", 0.25), ("B4", 0.12), ("D5", 0.08)]:
        f = periodic_freq(note(name), s)
        voice = osc(f, s, shape="triangle") * 0.6 + osc(periodic_freq(f * 1.003, s), s) * 0.4
        out += amp * voice * periodic_lfo(s, int(r.integers(1, 4)), 0.3, r.uniform(0, 2 * np.pi))
    air = loop_noise(r, s, lambda f: pink(f) * band(200, 3000, 2)(f)) * 0.08
    out = fft_filter(out, band(40, 2400, 2), circular=True) + air
    return circular_reverb(out, r, seconds=2.5, wet=0.4, brightness=1.0)


@cue("locked_floor", AMBIENCE, AMBIENCE_LUFS - 2, "Locked floor: the next chapter's room, muffled, heard through the door")
def locked_floor(r):
    s = 3.5
    room = ambience_corridor(np.random.default_rng(7))[: samples(s)]
    muffled = lowpass(lowpass(room, 320), 320)
    knock_room = reverb(muffled, r, seconds=0.6, wet=0.2, tail=False)
    return knock_room * swell(s, 0.7, 1.4, curve=1.5)


# --- the interview -------------------------------------------------------------------------------


@cue("question_lands", EFFECTS, EFFECT_LUFS, "The question lands: a short reverse whoosh into a held low tone")
def question_lands(r):
    s = 2.4
    rise = 0.55
    out = silence(s)
    whoosh = sweep_filter(white(r, rise), "bandpass", 300, 2600, q=0.8)
    whoosh *= np.exp((timeline(rise) - rise) / 0.14)
    place(out, reverb(whoosh, r, seconds=0.4, wet=0.3, tail=False) * 0.7, 0)
    held = s - rise
    tone = (osc(55, held) * 0.7 + osc(110, held) * 0.25 + osc(82.4, held) * 0.12)
    tone = saturate(tone, 1.3) * swell(held, 0.015, 1.2, curve=1.2)
    place(out, tone * 0.8, rise)
    return out


@cue("timer_pulse", EFFECTS, -24.0, "Soft timer: one quiet heartbeat-like pulse (timed missions only)")
def timer_pulse(r):
    return heartbeat(r)[: samples(0.45)]


@cue("timer_tick", EFFECTS, -24.0, "Soft timer, last 10 seconds: a clock tick (timed missions only)")
def timer_tick(r):
    s = 0.07
    return wood_tap(r, s, [(2100, 0.5, 0.009), (4700, 0.3, 0.004)], click_cut=7000)


@cue("choice_tap", EFFECTS, -20.0, "Choice focus or select: a soft wooden tap")
def choice_tap(r):
    s = 0.09
    return wood_tap(r, s, [(820, 0.7, 0.016), (1950, 0.35, 0.008), (3100, 0.12, 0.004)], click_cut=3000)


@cue("answer_locked", EFFECTS, EFFECT_LUFS, "Answer locked in: a card laid on the table")
def answer_locked(r):
    s = 0.55
    slap = lowpass(white(r, s) * decay(s, 0.006, 0.0005), 2200) * 0.9
    body = thump(r, s, 120, 80, 0.06, noise_cut=500, noise_amount=0.3) * 0.8
    out = slap + body
    return reverb(out, r, seconds=0.5, wet=0.12, brightness=0.6, tail=False)


def string_pulse(r, freqs, seconds, attack, cutoff, vibrato=4.8):
    t = timeline(seconds)
    out = np.zeros_like(t)
    for f in freqs:
        wobble = f * (1 + 0.004 * np.sin(2 * np.pi * vibrato * t))
        voice = np.zeros_like(t)
        for n in range(1, 30):
            if f * n > 6000:
                break
            voice += osc(wobble * n, seconds) / n
        out += voice / len(freqs)
    bow = lowpass(white(r, seconds), 3000) * 0.04
    env = swell(seconds, attack, seconds - attack, curve=1.0) * decay(seconds, seconds * 0.45, 0)
    return lowpass(out + bow, cutoff) * env


@cue("follow_up", EFFECTS, EFFECT_LUFS, "Follow-up challenge: a single dissonant low string pulse")
def follow_up(r):
    s = 1.8
    out = string_pulse(r, [note("A1"), note("A#1"), note("E2")], s, attack=0.09, cutoff=900)
    return reverb(out, r, seconds=1.4, wet=0.25, brightness=0.6, tail=False)


@cue("follow_up_sharp", EFFECTS, EFFECT_LUFS, "Follow-up challenge, Lena: the same pulse, sharper and brighter")
def follow_up_sharp(r):
    s = 1.6
    out = string_pulse(r, [note("A1"), note("A#1"), note("D#3")], s, attack=0.018, cutoff=2600)
    out = saturate(out * 1.5, 1.6)
    return reverb(out, r, seconds=1.2, wet=0.2, brightness=0.9, tail=False)


@cue("trust_up", EFFECTS, -18.0, "Trust rises: a warm, rising two-note shimmer")
def trust_up(r):
    s = 1.3
    out = silence(s)
    for at, name in [(0.0, "G4"), (0.13, "D5")]:
        f = note(name)
        tone = (osc(f, 1.1) + 0.35 * osc(2 * f, 1.1) + 0.3 * osc(f * 1.004, 1.1)) * decay(1.1, 0.35, 0.01)
        place(out, tone * periodic_lfo(1.1, 7, 0.15), at)
    return reverb(out, r, seconds=1.0, wet=0.3, tail=False)


@cue("trust_down", EFFECTS, -18.0, "Trust falls: a low, soft descending note (gentle, not a buzzer)")
def trust_down(r):
    s = 1.0
    t = timeline(s)
    glide = note("D4") * (1 - 0.11 * (1 - np.exp(-t / 0.18)))
    tone = (osc(glide, s) + 0.2 * osc(glide * 2, s)) * decay(s, 0.3, 0.015)
    return reverb(lowpass(tone, 1200), r, seconds=0.9, wet=0.25, brightness=0.6, tail=False)


# --- debrief -------------------------------------------------------------------------------------


@cue("dossier_slide", EFFECTS, EFFECT_LUFS, "Debrief file slides in: paper sliding on wood")
def dossier_slide(r):
    s = 0.75
    slide_s = 0.55
    friction = sweep_filter(white(r, slide_s), "bandpass", 2400, 4800, q=0.7)
    grain = 1 + 0.5 * bandpass(white(r, slide_s), 40, 0.7) * 6
    friction *= swell(slide_s, 0.12, 0.25, curve=1.2) * grain
    out = silence(s)
    place(out, friction * 0.6, 0)
    place(out, thump(r, 0.2, 180, 120, 0.025, noise_cut=1500, noise_amount=0.4) * 0.35, slide_s - 0.03)
    return reverb(out, r, seconds=0.4, wet=0.1, tail=False)


@cue("stamp", EFFECTS, EFFECT_LUFS, "A score is stamped: a rubber stamp thud")
def stamp(r):
    s = 0.4
    body = thump(r, s, 110, 70, 0.05, noise_cut=800, noise_amount=0.7)
    clack = bandpass(white(r, s) * decay(s, 0.008, 0.0003), 1300, 1.2) * 0.8
    return reverb(saturate(body + clack, 1.3), r, seconds=0.4, wet=0.12, tail=False)


@cue("count_tick", EFFECTS, -26.0, "Score count-up: a small tick per step")
def count_tick(r):
    s = 0.04
    return wood_tap(r, s, [(2600, 0.5, 0.005), (5200, 0.15, 0.002)], click_cut=8000)


@cue("result_strong", EFFECTS, EFFECT_LUFS, "Strong result: a warm chord that resolves")
def result_strong(r):
    s = 3.0
    out = silence(s)
    sus = [note("F3"), note("A#3"), note("C4")]
    home = [note("F3"), note("A3"), note("C4"), note("F4")]
    for f in sus:
        place(out, piano_note(r, f, 0.5, velocity=0.45) * swell(0.5, 0.005, 0.12, 1) * 0.5, 0)
    for k, f in enumerate(home):
        place(out, piano_note(r, f, 2.5, velocity=0.5) * 0.5, 0.42 + 0.025 * k)
    return reverb(out, r, seconds=2.2, wet=0.3, brightness=0.8, tail=False)


@cue("result_weak", EFFECTS, -18.0, "Weak result: a neutral, soft, unresolved tone (try again, not failure)")
def result_weak(r):
    s = 2.4
    out = silence(s)
    for k, f in enumerate([note("D4"), note("E4"), note("A4")]):
        place(out, piano_note(r, f, 2.2, velocity=0.35) * 0.5, 0.03 * k)
    return reverb(lowpass(out, 2400), r, seconds=1.8, wet=0.3, brightness=0.7, tail=False)


@cue("unlock_shimmer", EFFECTS, EFFECT_LUFS, "Skill unlocked: a glassy rising shimmer and a soft bell")
def unlock_shimmer(r):
    s = 2.4
    out = silence(s)
    for k, name in enumerate(["C6", "E6", "G6", "B6", "D7"]):
        f = note(name)
        sparkle = (osc(f, 0.6) + 0.3 * osc(f * 2.01, 0.6)) * decay(0.6, 0.18, 0.004)
        place(out, sparkle * 0.25, 0.05 * k)
    place(out, bell(note("E5"), 2.0, tau=1.1) * 0.7, 0.3)
    return reverb(out, r, seconds=1.8, wet=0.35, brightness=1.1, tail=False)
