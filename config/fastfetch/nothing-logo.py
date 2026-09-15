#!/usr/bin/env python3
"""Dot-matrix wordmark for fastfetch, sampled from the Ndot 57 font.

Writes nothing-logo.png (round dots on a transparent background, kitty graphics logo) and
nothing-logo.txt (half-block fallback for terminals without image support; $1/$2 are fastfetch
logo colours). Usage: nothing-logo.py [TEXT] [--pitch PX] [--dot RATIO] [--outdir DIR]
The last character of TEXT is drawn in the accent colour ($2) when it is punctuation.
"""
import argparse, os
from PIL import Image, ImageDraw, ImageFont

FONT = os.path.expanduser("~/.local/share/fonts/Nothing/Ndot57-Regular.otf")
ACCENT = (215, 25, 33, 255)
WHITE = (255, 255, 255, 255)


def sample(text, size=200):
    """Return (grid of 0/1/2, cols, rows): 2 marks accent dots. Ndot 57's dot pitch is size/10."""
    font = ImageFont.truetype(FONT, size)
    pitch = size / 10
    x0, y0, x1, y1 = font.getbbox(text)
    im = Image.new("L", (x1 + 2, y1 + 2), 0)
    ImageDraw.Draw(im).text((0, 0), text, font=font, fill=255)
    px = im.load()
    accent_from = font.getbbox(text[:-1])[2] if text[-1] in ".:!" else x1 + 1
    cols = round((x1 - x0) / pitch)
    rows = round((y1 - y0) / pitch)
    grid = []
    for j in range(rows):
        row = []
        for i in range(cols):
            x, y = x0 + pitch * (i + 0.5), y0 + pitch * (j + 0.5)
            lit = px[int(x), int(y)] > 128
            row.append((2 if x >= accent_from else 1) if lit else 0)
        grid.append(row)
    while grid and not any(grid[-1]):
        grid.pop()
    while grid and not any(grid[0]):
        grid.pop(0)
    return grid


def write_png(grid, path, pitch, ratio):
    rows, cols = len(grid), len(grid[0])
    m = pitch  # margin
    im = Image.new("RGBA", (round(cols * pitch + 2 * m), round(rows * pitch + 2 * m)), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = pitch * ratio / 2
    for j, row in enumerate(grid):
        for i, v in enumerate(row):
            if v:
                cx, cy = m + pitch * (i + 0.5), m + pitch * (j + 0.5)
                d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ACCENT if v == 2 else WHITE)
    im.save(path)


def write_txt(grid, path):
    """Two dot rows per text line: ▀ upper, ▄ lower, █ both. Colour switches use $1/$2."""
    if len(grid) % 2:
        grid = grid + [[0] * len(grid[0])]
    lines = []
    for j in range(0, len(grid), 2):
        line, cur = "", 0
        for i in range(len(grid[0])):
            a, b = grid[j][i], grid[j + 1][i]
            v = a or b
            if v and v != cur:
                line += f"${v}"
                cur = v
            line += {(0, 0): " ", (1, 0): "▀", (0, 1): "▄"}.get((bool(a), bool(b)), "█")
        lines.append(line.rstrip())
    open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("text", nargs="?", default="fedora.")
    ap.add_argument("--pitch", type=float, default=24, help="dot spacing in the PNG, px")
    ap.add_argument("--dot", type=float, default=0.72, help="dot diameter as a fraction of pitch")
    ap.add_argument("--outdir", default=os.path.dirname(os.path.abspath(__file__)))
    a = ap.parse_args()
    grid = sample(a.text)
    write_png(grid, os.path.join(a.outdir, "nothing-logo.png"), a.pitch, a.dot)
    write_txt(grid, os.path.join(a.outdir, "nothing-logo.txt"))
    print(f"{a.text!r}: {len(grid[0])}x{len(grid)} dots")
    for row in grid:
        print("".join(" ●○"[v] for v in row))


if __name__ == "__main__":
    main()
