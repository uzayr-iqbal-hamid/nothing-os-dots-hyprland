#!/usr/bin/env python3
"""Nothing OS style wallpapers, v2: five compositions, dark and light, fine film grain.

Everything is laid out on a 1600x900 reference canvas and scaled to each requested size, so the
same design fits every monitor. Grain is baked in (no live shader).

  NothingWallpaper.py [--variant all|shapes|glyph|dots|stripes|arc] [--mode dark|light|both]
                      [--size WxH ...] [--outdir DIR]
  -> nothing-<NN>-<variant>-<mode>-<WxH>.png
"""
import argparse
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

REF_W, REF_H = 1600, 900
SS = 3  # supersampling for anti-aliased curves
FONT = os.path.expanduser("~/.local/share/fonts/Nothing/Ndot57-Regular.otf")

PALETTES = {
    "dark": dict(bg=(14, 14, 14), fog=(46, 46, 46), grey_top=(122, 122, 122), grey_bot=(66, 66, 66),
                 dark_top=(60, 60, 60), dark_bot=(34, 34, 34), red=(190, 20, 26), red_dim=(120, 14, 18),
                 hair=(66, 66, 66), cross=(32, 32, 32), dot=(150, 150, 150), caption=(84, 84, 84)),
    "light": dict(bg=(214, 214, 214), fog=(192, 192, 192), grey_top=(126, 126, 126), grey_bot=(76, 76, 76),
                  dark_top=(168, 168, 168), dark_bot=(128, 128, 128), red=(200, 22, 28), red_dim=(150, 16, 22),
                  hair=(150, 150, 150), cross=(126, 126, 126), dot=(84, 84, 84), caption=(130, 130, 130)),
}


class Canvas:
    def __init__(self, mode, W, H):
        self.p = PALETTES[mode]
        self.W, self.H = W, H
        self.s = min(W / REF_W, H / REF_H)
        self.ox, self.oy = (W - REF_W * self.s) / 2, (H - REF_H * self.s) / 2
        self.lw = max(1, round(1.5 * self.s))
        self.img = Image.new("RGB", (W, H), self.p["bg"])

    # reference -> pixel coordinates
    def px(self, x, y):
        return self.ox + x * self.s, self.oy + y * self.s

    def mask(self):
        return Image.new("L", (self.W * SS, self.H * SS), 0)

    def box(self, x0, y0, x1, y1):
        (a, b), (c, d) = self.px(x0, y0), self.px(x1, y1)
        return [a * SS, b * SS, c * SS, d * SS]

    def r(self, v):
        return max(1, round(v * self.s * SS))

    def finish(self, m, blur=0):
        m = m.reduce(SS)
        return m.filter(ImageFilter.GaussianBlur(blur * self.s)) if blur else m

    def plane(self, top, bot=None, y0=0, y1=REF_H, grain=0.22):
        """A colour plane, optionally a vertical gradient between reference rows y0..y1, with fine grain."""
        W, H = self.W, self.H
        base = Image.new("RGB", (W, H), top)
        if bot and bot != top:
            a, b = round(self.px(0, y0)[1]), round(self.px(0, y1)[1])
            ramp = Image.linear_gradient("L").resize((W, max(1, b - a)))
            g = Image.new("L", (W, H), 0)
            g.paste(255, (0, b, W, H))
            g.paste(ramp, (0, a))
            base = Image.composite(Image.new("RGB", (W, H), bot), base, g)
        if grain:
            n = Image.effect_noise((W, H), 48).point(lambda v: max(0, min(255, round(128 + (v - 128) * grain))))
            base = ImageChops.add(base, Image.merge("RGB", (n, n, n)), 1.0, -128)
        return base

    def paint(self, m, plane, blur=0):
        self.img = Image.composite(plane, self.img, self.finish(m, blur))

    def line(self, x0, y0, x1, y1, color):
        (a, b), (c, d) = self.px(x0, y0), self.px(x1, y1)
        box = [a - self.lw / 2, b, a + self.lw / 2 - 1, d] if a == c else [a, b - self.lw / 2, c, b + self.lw / 2 - 1]
        ImageDraw.Draw(self.img).rectangle(box, fill=color)

    def cross(self, x, y, arm, color):
        self.line(x - arm, y, x + arm, y, color)
        self.line(x, y - arm, x, y + arm, color)

    def caption(self, text):
        font = ImageFont.truetype(FONT, max(8, round(26 * self.s)))
        ImageDraw.Draw(self.img).text(self.px(1540, 846), text, font=font, fill=self.p["caption"], anchor="rb")

    def grain_all(self, amount=0.07):
        n = Image.effect_noise((self.W, self.H), 64).point(lambda v: round(128 + (v - 128) * amount))
        self.img = ImageChops.add(self.img, Image.merge("RGB", (n, n, n)), 1.0, -128)


# 01 shapes: fog, block, red half-disc, pill band (v1's composition, finer grain)
def shapes(c):
    p = c.p
    m = c.mask()
    ImageDraw.Draw(m).rectangle(c.box(110, 215, 470, 700), fill=255)
    c.paint(m, c.plane(p["fog"], grain=0.3), blur=34)
    c.line(190, 460, 190, 540, p["hair"])

    m = c.mask()
    ImageDraw.Draw(m).rounded_rectangle(c.box(440, 268, 705, 633), radius=c.r(28), fill=255, corners=(False, True, True, False))
    c.paint(m, c.plane(p["dark_top"], p["dark_bot"], 268, 633, 0.24))

    m = c.mask()
    ImageDraw.Draw(m).rounded_rectangle(c.box(900, 385, 1494, 650), radius=c.r(120), fill=255, corners=(False, False, True, True))
    fade = c.plane(p["grey_bot"], p["bg"], 395, 650, 0.1)
    c.paint(m, fade, blur=14)

    m = c.mask()
    d = ImageDraw.Draw(m)
    d.rounded_rectangle(c.box(900, 253, 1494, 253 + 2 * 140 + 20), radius=c.r(140), fill=255, corners=(True, True, False, False))
    d.rectangle(c.box(0, 395, REF_W, REF_H), fill=0)
    c.paint(m, c.plane(p["grey_top"], p["grey_bot"], 253, 395, 0.26))

    cx, cy, r = 895, 450, 185
    m = c.mask()
    ImageDraw.Draw(m).pieslice(c.box(cx - r, cy - r, cx + r, cy + r), 90, 270, fill=255)
    c.paint(m, c.plane(p["red"], p["red_dim"], cy - r, cy + r, 0.2))
    c.line(815, 450, 895, 450, p["bg"])

    c.line(1018, 360, 1018, 540, p["cross"])
    c.line(928, 450, 1108, 450, p["cross"])
    c.line(1530, 450, 1600, 450, p["hair"])
    c.line(1578, 360, 1578, 492, p["hair"])
    c.caption("01")


# 02 glyph: the broken ring of the (1) glyph with its red dot, a darker inner ring, a fog pill
def glyph(c):
    p = c.p
    m = c.mask()
    ImageDraw.Draw(m).rounded_rectangle(c.box(250, 170, 430, 730), radius=c.r(90), fill=255)
    c.paint(m, c.plane(p["fog"], p["bg"], 170, 730, 0.28), blur=22)

    cx, cy, R, t = 1060, 450, 270, 74
    m = c.mask()
    ImageDraw.Draw(m).arc(c.box(cx - R, cy - R, cx + R, cy + R), 300, 240, fill=255, width=c.r(t))
    c.paint(m, c.plane(p["grey_top"], p["grey_bot"], cy - R, cy + R, 0.22))

    r2, t2 = 150, 44
    m = c.mask()
    ImageDraw.Draw(m).ellipse(c.box(cx - r2, cy - r2, cx + r2, cy + r2), outline=255, width=c.r(t2))
    c.paint(m, c.plane(p["dark_top"], p["dark_bot"], cy - r2, cy + r2, 0.22))

    dr = 34
    m = c.mask()
    ImageDraw.Draw(m).ellipse(c.box(cx - dr, cy - R - dr, cx + dr, cy - R + dr), fill=255)
    c.paint(m, c.plane(p["red"], p["red_dim"], cy - R - dr, cy - R + dr, 0.18))

    c.line(cx + R + 40, cy, REF_W, cy, p["cross"])
    c.cross(600, 450, 40, p["hair"])
    c.cross(1480, 190, 22, p["hair"])
    c.caption("02")


# 03 dots: a halftone sphere drawn on a dot grid, one dot red, a dotted marker
def dots(c):
    p = c.p
    pitch, cx, cy, R = 20, 1000, 450, 330
    lx, ly = 760, 230
    m = c.mask()
    d = ImageDraw.Draw(m)
    for gy in range(cy - R, cy + R + 1, pitch):
        for gx in range(cx - R, cx + R + 1, pitch):
            if (gx - cx) ** 2 + (gy - cy) ** 2 > R * R:
                continue
            f = min(1.0, math.hypot(gx - lx, gy - ly) / (2 * R))
            r = pitch * 0.46 * (1 - 0.74 * f) + 0.6
            d.ellipse(c.box(gx - r, gy - r, gx + r, gy + r), fill=255)
    c.paint(m, c.plane(p["dot"], grain=0.25))

    gx, gy, r = cx - 6 * pitch, cy - 9 * pitch, pitch * 0.62
    m = c.mask()
    ImageDraw.Draw(m).ellipse(c.box(gx - r, gy - r, gx + r, gy + r), fill=255)
    c.paint(m, c.plane(p["red"], grain=0.18))

    m = c.mask()
    d = ImageDraw.Draw(m)
    for i in range(-2, 3):
        for (x, y) in ((380 + i * pitch, 450), (380, 450 + i * pitch)):
            d.ellipse(c.box(x - 3.5, y - 3.5, x + 3.5, y + 3.5), fill=255)
    c.paint(m, c.plane(p["hair"], grain=0))
    c.line(1480, 700, 1560, 700, p["hair"])
    c.caption("03")


# 04 stripes: a hatched rounded panel, a red quarter disc on its edge, a dark pill
def stripes(c):
    p = c.p
    x0, y0, x1, y1 = 300, 260, 900, 640
    shape = c.mask()
    ImageDraw.Draw(shape).rounded_rectangle(c.box(x0, y0, x1, y1), radius=c.r(48), fill=255)
    lines = c.mask()
    d = ImageDraw.Draw(lines)
    for k in range(-(y1 - y0), (x1 - x0) + (y1 - y0), 16):
        (a, b), (e, f) = c.px(x0 + k, y1), c.px(x0 + k + (y1 - y0), y0)
        d.line([a * SS, b * SS, e * SS, f * SS], fill=255, width=c.r(2))
    c.paint(ImageChops.multiply(shape, lines), c.plane(p["grey_top"], p["grey_bot"], y0, y1, 0.2))
    m = c.mask()
    ImageDraw.Draw(m).rounded_rectangle(c.box(x0, y0, x1, y1), radius=c.r(48), outline=255, width=c.r(1.5))
    c.paint(m, c.plane(p["hair"], grain=0))

    r = 190
    m = c.mask()
    ImageDraw.Draw(m).pieslice(c.box(x1 - r, 450 - r, x1 + r, 450 + r), 270, 360, fill=255)
    c.paint(m, c.plane(p["red"], p["red_dim"], 450 - r, 450, 0.2))

    m = c.mask()
    ImageDraw.Draw(m).rounded_rectangle(c.box(1000, 520, 1420, 640), radius=c.r(60), fill=255)
    c.paint(m, c.plane(p["dark_top"], p["dark_bot"], 520, 640, 0.24))

    c.cross(1250, 300, 30, p["hair"])
    c.cross(150, 760, 22, p["hair"])
    c.line(1420, 580, REF_W, 580, p["cross"])
    c.caption("04")


# 05 arc: a thick quarter ring rising from the bottom-left corner, a thin red arc, a dark disc
def arc(c):
    p = c.p
    cx, cy, R, t = 0, 900, 720, 170
    m = c.mask()
    ImageDraw.Draw(m).arc(c.box(cx - R, cy - R, cx + R, cy + R), 270, 360, fill=255, width=c.r(t))
    c.paint(m, c.plane(p["grey_top"], p["grey_bot"], cy - R, cy, 0.22))

    R2 = 830
    m = c.mask()
    ImageDraw.Draw(m).arc(c.box(cx - R2, cy - R2, cx + R2, cy + R2), 270, 360, fill=255, width=c.r(8))
    c.paint(m, c.plane(p["red"], grain=0.15))

    m = c.mask()
    ImageDraw.Draw(m).ellipse(c.box(1240, 170, 1400, 330), fill=255)
    c.paint(m, c.plane(p["dark_top"], p["dark_bot"], 170, 330, 0.22))
    c.line(1320, 330, 1320, 600, p["hair"])
    c.cross(1320, 680, 30, p["hair"])
    c.line(1100, 250, 1240, 250, p["cross"])
    c.caption("05")


VARIANTS = {"shapes": (1, shapes), "glyph": (2, glyph), "dots": (3, dots), "stripes": (4, stripes), "arc": (5, arc)}


def main():
    ap = argparse.ArgumentParser(description="Generate Nothing OS style wallpapers.")
    ap.add_argument("--variant", nargs="+", default=["all"], choices=["all", *VARIANTS])
    ap.add_argument("--mode", choices=["dark", "light", "both"], default="both")
    ap.add_argument("--size", nargs="+", default=["1920x1080", "1366x768"], help="one or more WxH")
    ap.add_argument("--outdir", default=os.path.expanduser("~/Pictures/wallpapers/nothing"))
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    variants = list(VARIANTS) if "all" in args.variant else args.variant
    modes = ["dark", "light"] if args.mode == "both" else [args.mode]
    for name in variants:
        number, draw = VARIANTS[name]
        for mode in modes:
            for size in args.size:
                w, h = (int(v) for v in size.lower().split("x"))
                c = Canvas(mode, w, h)
                draw(c)
                c.grain_all()
                path = os.path.join(args.outdir, f"nothing-{number:02d}-{name}-{mode}-{w}x{h}.png")
                c.img.save(path)
                print(path, flush=True)


if __name__ == "__main__":
    main()
