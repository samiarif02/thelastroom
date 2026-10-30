"""Small DSP toolkit the cue recipes are built from (numpy only, mono, float64 in -1..1).

Everything takes an explicit `numpy.random.Generator`, so a build is reproducible bit for bit.
Loops are made in the frequency domain (`loop_noise`, `circular_reverb`), which makes them
exactly periodic: the last sample flows into the first with no seam.
"""

import math

import numpy as np

SR = 44100


def samples(seconds):
    return int(round(seconds * SR))


def timeline(seconds):
    return np.arange(samples(seconds)) / SR


def silence(seconds):
    return np.zeros(samples(seconds))


def place(dst, src, at_seconds, gain=1.0):
    """Mixes `src` into `dst` starting at `at_seconds`, clipping what runs past the end."""
    start = samples(at_seconds)
    end = min(len(dst), start + len(src))
    if end > start:
        dst[start:end] += gain * src[: end - start]
    return dst


# --- oscillators -------------------------------------------------------------------------------


def osc(freq, seconds, phase=0.0, shape="sine"):
    """`freq` is a number or a per-sample array (a glide)."""
    n = samples(seconds)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    ph = phase + 2 * np.pi * np.cumsum(f) / SR
    if shape == "sine":
        return np.sin(ph)
    if shape == "triangle":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    raise ValueError(shape)


def additive(f0, seconds, partials, inharmonicity=0.0, phase_seed=None):
    """Sum of partials `[(n, amp, decay_seconds)]`; decay None means sustained.

    `inharmonicity` stretches partial n to n * sqrt(1 + B n^2), as a struck string does.
    """
    t = timeline(seconds)
    out = np.zeros_like(t)
    r = np.random.default_rng(phase_seed)
    for n, amp, decay in partials:
        f = f0 * n * math.sqrt(1 + inharmonicity * n * n)
        if f >= SR / 2:
            continue
        tone = np.sin(2 * np.pi * f * t + r.uniform(0, 2 * np.pi))
        env = np.exp(-t / decay) if decay else 1.0
        out += amp * tone * env
    return out


def saw_band_limited(freq, seconds, max_harmonic=40):
    """A softened sawtooth from its harmonics (no aliasing)."""
    out = np.zeros(samples(seconds))
    for n in range(1, max_harmonic + 1):
        if freq * n >= SR / 2:
            break
        out += osc(freq * n, seconds) / n
    return out * 0.5


# --- noise ---------------------------------------------------------------------------------------


def white(r, seconds):
    return r.uniform(-1, 1, samples(seconds))


def spectral_noise(r, seconds, magnitude):
    """Noise whose spectrum follows `magnitude(freqs_hz)`. Exactly periodic over `seconds`."""
    n = samples(seconds)
    freqs = np.fft.rfftfreq(n, 1 / SR)
    mag = np.asarray(magnitude(np.maximum(freqs, 1e-3)), dtype=float)
    mag[0] = 0
    phases = r.uniform(0, 2 * np.pi, len(freqs))
    out = np.fft.irfft(mag * np.exp(1j * phases), n)
    return out / (np.max(np.abs(out)) + 1e-12)


def loop_noise(r, seconds, magnitude):
    return spectral_noise(r, seconds, magnitude)


def pink(f):
    return 1 / np.sqrt(f)


def brown(f):
    return 1 / f


def band(lo, hi, slope=4):
    """A smooth band-pass magnitude curve (for `spectral_noise` / `fft_filter`)."""

    def mag(f):
        return 1 / (1 + (lo / f) ** slope) / (1 + (f / hi) ** slope)

    return mag


def periodic_freq(freq, seconds):
    """Rounds a frequency to a whole number of cycles in `seconds`, so a loop stays seamless."""
    return round(freq * seconds) / seconds


# --- filters -------------------------------------------------------------------------------------


def biquad(x, kind, f0, q=0.707):
    """RBJ cookbook biquad: `lowpass`, `highpass` or `bandpass` (constant 0 dB peak)."""
    w = 2 * np.pi * f0 / SR
    alpha = math.sin(w) / (2 * q)
    cw = math.cos(w)
    if kind == "lowpass":
        b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
    elif kind == "highpass":
        b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
    elif kind == "bandpass":
        b = [alpha, 0, -alpha]
    else:
        raise ValueError(kind)
    a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    b0, b1, b2 = b[0] / a0, b[1] / a0, b[2] / a0
    a1, a2 = a1 / a0, a2 / a0
    out = np.empty_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, xi in enumerate(x.tolist()):
        yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        out[i] = yi
        x2, x1, y2, y1 = x1, xi, y1, yi
    return out


def lowpass(x, f0, q=0.707):
    return biquad(x, "lowpass", f0, q)


def highpass(x, f0, q=0.707):
    return biquad(x, "highpass", f0, q)


def bandpass(x, f0, q=1.0):
    return biquad(x, "bandpass", f0, q)


def fft_filter(x, magnitude, circular=False):
    """Zero-phase filtering by a magnitude curve. Circular keeps a loop seamless."""
    n = len(x) if circular else int(2 ** math.ceil(math.log2(len(x) * 2)))
    spec = np.fft.rfft(x, n)
    freqs = np.fft.rfftfreq(n, 1 / SR)
    spec *= magnitude(np.maximum(freqs, 1e-3))
    return np.fft.irfft(spec, n)[: len(x)]


def sweep_filter(x, kind, f_start, f_end, q=0.707, block=256):
    """A biquad whose cutoff glides exponentially (block-wise, state carried across blocks)."""
    out = np.empty_like(x)
    x1 = x2 = y1 = y2 = 0.0
    blocks = max(1, math.ceil(len(x) / block))
    for k in range(blocks):
        f0 = f_start * (f_end / f_start) ** (k / max(1, blocks - 1))
        w = 2 * np.pi * min(f0, SR * 0.45) / SR
        alpha = math.sin(w) / (2 * q)
        cw = math.cos(w)
        if kind == "lowpass":
            b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
        elif kind == "bandpass":
            b = [alpha, 0, -alpha]
        else:
            b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
        a0 = 1 + alpha
        b0, b1, b2 = b[0] / a0, b[1] / a0, b[2] / a0
        a1, a2 = -2 * cw / a0, (1 - alpha) / a0
        for i in range(k * block, min(len(x), (k + 1) * block)):
            xi = x[i]
            yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            out[i] = yi
            x2, x1, y2, y1 = x1, xi, y1, yi
    return out


# --- envelopes -----------------------------------------------------------------------------------


def decay(seconds, tau, attack=0.002):
    t = timeline(seconds)
    env = np.exp(-t / tau)
    if attack > 0:
        env *= np.minimum(1, t / attack)
    return env


def swell(seconds, attack, release, curve=2.0):
    """Rises over `attack` (eased), holds, falls over `release`."""
    t = timeline(seconds)
    up = np.minimum(1, t / max(attack, 1e-6)) ** curve
    down = np.minimum(1, (seconds - t) / max(release, 1e-6)).clip(0) ** curve
    return up * down


def fade(x, fade_in=0.0, fade_out=0.0):
    x = x.copy()
    if fade_in > 0:
        n = min(len(x), samples(fade_in))
        x[:n] *= np.sin(np.linspace(0, np.pi / 2, n)) ** 2
    if fade_out > 0:
        n = min(len(x), samples(fade_out))
        x[-n:] *= np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    return x


def periodic_lfo(seconds, cycles, depth, phase=0.0):
    """1 ± depth, with a whole number of cycles over `seconds` (seamless in a loop)."""
    t = timeline(seconds)
    return 1 + depth * np.sin(2 * np.pi * cycles * t / seconds + phase)


# --- space and colour ----------------------------------------------------------------------------


def _impulse_response(r, seconds, brightness):
    t = timeline(seconds)
    ir = r.standard_normal(len(t)) * np.exp(-t * 6.9 / seconds)
    # The tail darkens as it decays, as a real room's does.
    dark = fft_filter(ir, band(20, 1200 * brightness, 2))
    bright = fft_filter(ir, band(20, 6000 * brightness, 2))
    mix = np.exp(-t * 4 / seconds)
    ir = bright * mix + dark * (1 - mix)
    return ir / np.sqrt(np.sum(ir**2))


def reverb(x, r, seconds=1.2, wet=0.25, brightness=1.0, tail=True):
    """Convolution with a synthetic room. `tail` extends the sound so the reverb can ring out."""
    ir = _impulse_response(r, seconds, brightness)
    n = len(x) + len(ir) - 1
    size = int(2 ** math.ceil(math.log2(n)))
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:n]
    dry = np.concatenate([x, np.zeros(n - len(x))])
    out = (1 - wet) * dry + wet * y
    return out if tail else out[: len(x)]


def circular_reverb(x, r, seconds=1.5, wet=0.3, brightness=1.0):
    """Reverb for a loop: the tail wraps around to the loop's start."""
    ir = _impulse_response(r, seconds, brightness)
    if len(ir) > len(x):
        ir = ir[: len(x)]
    y = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, len(x)), len(x))
    return (1 - wet) * x + wet * y


def saturate(x, drive=1.5):
    return np.tanh(drive * x) / np.tanh(drive)


def normalize_peak(x, peak=0.9):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def true_peak(x, oversample=4):
    """Inter-sample peak by FFT oversampling (BS.1770 style)."""
    n = len(x)
    spec = np.fft.rfft(x)
    up = np.fft.irfft(spec, n * oversample) * oversample
    return float(np.max(np.abs(up)))
