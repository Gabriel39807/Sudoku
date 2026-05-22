#!/usr/bin/env python3
"""Generate crystal_reference_v2 frame corners (512x512, 30% margin, centered L).

All assets are lossless WebP with alpha transparency.
Sides and ornaments are reused from 'crystal' frame.
"""

from PIL import Image, ImageDraw
import os

ASSETS = r"C:\Users\picos\OneDrive\Desktop\Sudoku\flutter_app\assets\cosmetics"
SIZE = 512
MARGIN = int(SIZE * 0.3)  # 154 — safe area, L no toca bordes
# BAR_WIDTH calibrado para que el grosor visual en render (~20px) iguale al side
# side: FRAME_BORDER=64 en 128px alto → render 40px → 64/128*40 = 20px
# corner: BAR_WIDTH/512*52 = 20 → BAR_WIDTH = 20*512/52 ≈ 197
BAR_WIDTH = int(20 * SIZE / 52)  # 197
BAR_LENGTH = 235  # extensión del L desde MARGIN (deja ~0.5px de gap al grid)

CORNER_COLOR = (180, 220, 255, 255)
GLOW_COLOR = (150, 210, 255)
INNER_LINE = (180, 220, 255, 180)


def _make_corner():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    x1 = MARGIN
    y1 = MARGIN
    x2 = MARGIN + BAR_WIDTH
    y2 = MARGIN + BAR_WIDTH
    x3 = MARGIN + BAR_LENGTH
    y3 = MARGIN + BAR_LENGTH

    for i in range(3, 0, -1):
        a = int(25 / i)
        c = (*GLOW_COLOR[:3], a)
        inflate = i * 6
        draw.polygon([
            (x1 - inflate, y1 - inflate),
            (x3 + inflate, y1 - inflate),
            (x3 + inflate, y2 + inflate),
            (x2 + inflate, y2 + inflate),
            (x2 + inflate, y3 + inflate),
            (x1 - inflate, y3 + inflate),
        ], fill=c)

    draw.polygon([
        (x1, y1),
        (x3, y1),
        (x3, y2),
        (x2, y2),
        (x2, y3),
        (x1, y3),
    ], fill=CORNER_COLOR)

    draw.line([(x3, y2), (x2, y2)], fill=INNER_LINE, width=2)
    draw.line([(x2, y2), (x2, y3)], fill=INNER_LINE, width=2)

    return img


def main():
    base = os.path.join(ASSETS, "frames", "crystal_reference_v2")
    os.makedirs(base, exist_ok=True)

    for fname in ["tl", "tr", "bl", "br"]:
        img = _make_corner()
        if fname == "tr":
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
        elif fname == "bl":
            img = img.transpose(Image.FLIP_TOP_BOTTOM)
        elif fname == "br":
            img = img.transpose(Image.FLIP_LEFT_RIGHT).transpose(Image.FLIP_TOP_BOTTOM)
        img.save(os.path.join(base, f"{fname}.webp"), lossless=True)

    print(f"  Frame 'crystal_reference_v2' generated ({len(os.listdir(base))} assets)")


if __name__ == "__main__":
    main()
