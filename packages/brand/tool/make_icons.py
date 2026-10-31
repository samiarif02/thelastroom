#!/usr/bin/env python3
"""Draws The Last Room's platform icons and launch marks: a sunflower "LR" monogram in Manrope
ExtraBold on the evening sky, with the sun just below the horizon (the vivid layer, brief 17;
brief 20 put the icon and splash on it; the layout is brief 06's, DESIGN.md "Platform edges").

Run from the repo root after changing the mark:  python3 packages/brand/tool/make_icons.py
Needs Pillow (`pip3 install pillow`). The outputs are committed; nothing runs this at build time.

The colours mirror `lib/src/vivid.dart` (BrandVivid); this script can't import Dart tokens, so
keep them in step by hand.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[3]
FONT = ROOT / 'packages/brand/fonts/manrope/Manrope-ExtraBold.ttf'
APP = ROOT / 'apps/mobile'

VOID = (0x0B, 0x1E, 0x33)  # BrandVivid.skyTop: the splash ground and the icon's edges
SKY_MID = (0x15, 0x40, 0x5A)  # BrandVivid.skyMid
SKY_LOW = (0x1A, 0x52, 0x58)  # BrandVivid.skyLow
TINT = (0xF2, 0x99, 0x4A)  # BrandVivid.horizon: the sun below the horizon
BRASS = (0xFF, 0xC2, 0x3D)  # BrandVivid.accent: the mark (the name dates from the Boardroom)

MASTER = 1024  # every image is drawn at this size (x SUPER) and scaled down
SUPER = 2


def _walnut(size):
    """The evening sky, top to bottom, with the sun's warm glow low in frame and the edges
    falling to the top of the sky. (The name dates from the Boardroom.)"""
    img = Image.new('RGB', (size, size), VOID)
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        a, b, u = (VOID, SKY_MID, t * 2) if t < 0.5 else (SKY_MID, SKY_LOW, t * 2 - 1)
        d.line((0, y, size, y), fill=tuple(round(a[i] + (b[i] - a[i]) * u) for i in range(3)))
    glow = Image.new('L', (size, size), 0)
    g = ImageDraw.Draw(glow)
    r = size * 0.42
    cx, cy = size * 0.62, size * 1.12
    g.ellipse((cx - r, cy - r, cx + r, cy + r), fill=170)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.1))
    return Image.composite(Image.new('RGB', (size, size), TINT), img, glow)


def _monogram(size, scale):
    """The brass "LR" over a rule ending in diamonds, on transparency. [scale] is the
    mark's height as a share of [size]."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FONT), int(size * scale))
    text = 'LR'
    tracking = size * scale * 0.02
    widths = [d.textlength(c, font=font) for c in text]
    total = sum(widths) + tracking * (len(text) - 1)
    bbox = d.textbbox((0, 0), 'L', font=font)
    cap = bbox[3] - bbox[1]
    x = (size - total) / 2
    y = (size - cap) / 2 - bbox[1]
    for c, w in zip(text, widths):
        d.text((x, y), c, font=font, fill=BRASS)
        x += w + tracking
    # A rule beneath with a diamond at each end: the title card's ornament, in miniature.
    top = (size - cap) / 2
    dia = size * scale * 0.06
    cx = size / 2
    rule_y = top + cap + dia * 4
    half = total * 0.42
    d.line((cx - half, rule_y, cx + half, rule_y), fill=BRASS, width=max(1, int(size * scale * 0.025)))
    for x in (cx - half - dia * 2.2, cx + half + dia * 2.2):
        d.polygon([(x, rule_y - dia), (x + dia, rule_y), (x, rule_y + dia), (x - dia, rule_y)], fill=BRASS)
    return img


def _frame(img, inset, gap, weight):
    """The title card's double brass rule, inset into [img]."""
    d = ImageDraw.Draw(img)
    s = img.size[0]
    for i, a in ((inset, 200), (inset + gap, 140)):
        d.rectangle((i, i, s - i, s - i), outline=BRASS + (a,), width=weight)
    return img


def full_icon(size, frame=True, mark=0.34):
    """Walnut, frame, monogram: the legacy Android icon, iOS, the web."""
    big = size * SUPER
    img = _walnut(big).convert('RGBA')
    if frame:
        layer = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        _frame(layer, int(big * 0.085), int(big * 0.03), max(1, int(big * 0.008)))
        img = Image.alpha_composite(img, layer)
    if mark > 0:
        img = Image.alpha_composite(img, _monogram(big, mark))
    return img.resize((size, size), Image.LANCZOS)


def mark_only(size, mark):
    """The monogram on transparency: the adaptive icon's foreground, the splash mark."""
    big = size * SUPER
    return _monogram(big, mark).resize((size, size), Image.LANCZOS)


def save(img, path, rgb=False):
    path = APP / path
    path.parent.mkdir(parents=True, exist_ok=True)
    (img.convert('RGB') if rgb else img).save(path, optimize=True)


def main():
    res = 'android/app/src/main/res'
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, k in densities.items():
        # Legacy launcher icon: 48 dp, full bleed.
        save(full_icon(round(48 * k)), f'{res}/mipmap-{name}/ic_launcher.png', rgb=True)
        # Adaptive icon (API 26+): 108 dp layers; the mark stays inside the 66 dp safe zone.
        save(full_icon(round(108 * k), frame=False, mark=0), f'{res}/mipmap-{name}/ic_launcher_background.png', rgb=True)
        save(mark_only(round(108 * k), 0.28), f'{res}/mipmap-{name}/ic_launcher_foreground.png')
        # Launch mark: 288 dp canvas, the mark well inside Android 12's 192 dp circle.
        save(mark_only(round(288 * k), 0.16), f'{res}/drawable-{name}/launch_mark.png')

    ios = 'ios/Runner/Assets.xcassets'
    for pt, scales in {20: (1, 2, 3), 29: (1, 2, 3), 40: (1, 2, 3), 60: (2, 3), 76: (1, 2), 83.5: (2,)}.items():
        for s in scales:
            label = f'{pt:g}x{pt:g}'
            save(full_icon(round(pt * s)), f'{ios}/AppIcon.appiconset/Icon-App-{label}@{s}x.png', rgb=True)
    # The App Store icon has no alpha and no frame inset problem at this size.
    save(full_icon(1024), f'{ios}/AppIcon.appiconset/Icon-App-1024x1024@1x.png', rgb=True)
    # iOS launch: 168 x 168 pt mark centred on void (LaunchScreen.storyboard).
    for s, suffix in ((1, ''), (2, '@2x'), (3, '@3x')):
        save(mark_only(round(168 * s), 0.3), f'{ios}/LaunchImage.imageset/LaunchImage{suffix}.png')

    save(full_icon(32), 'web/favicon.png', rgb=True)
    for n in (192, 512):
        save(full_icon(n), f'web/icons/Icon-{n}.png', rgb=True)
        # Maskable: the browser may crop to a circle of 80%, so no frame and a smaller mark.
        save(full_icon(n, frame=False, mark=0.26), f'web/icons/Icon-maskable-{n}.png', rgb=True)

    # A contact sheet for the PR, not shipped.
    sheet = Image.new('RGB', (1024 + 432 + 40, 1024), VOID)
    sheet.paste(full_icon(1024), (0, 0))
    adaptive = full_icon(432, frame=False, mark=0)
    fg = mark_only(432, 0.28)
    adaptive.paste(fg, (0, 0), fg)
    circle = Image.new('L', (432, 432), 0)
    ImageDraw.Draw(circle).ellipse((36, 36, 396, 396), fill=255)
    sheet.paste(adaptive, (1064, 40), circle)
    out = ROOT / '.pr-screenshots/20/icons.jpg'
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=85)


if __name__ == '__main__':
    main()
