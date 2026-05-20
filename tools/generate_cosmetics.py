#!/usr/bin/env python3
"""Generate test cosmetic assets for Sudoku (Phase 1).

All assets are lossless WebP with alpha transparency.
Designed for EXTERNAL frame rendering (frame wraps around the board).
"""

from PIL import Image, ImageDraw
import os

ASSETS = r"C:\Users\picos\OneDrive\Desktop\Sudoku\flutter_app\assets\cosmetics"
FRAME_BORDER = 64  # thickness of the frame border in px at native res
MARGIN = int(256 * 0.12)  # ~12% internal margin


def _draw_glow(draw, shape_fn, glow_color, iterations=3):
    """Draw multi-layer glow effect."""
    for i in range(iterations, 0, -1):
        a = int(35 / i)
        c = (*glow_color[:3], a)
        shape_fn(i, c)


def _make_corner(w, h, color, glow_color, radius=0):
    """Frame corner piece — L-shaped external border corner."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    b = FRAME_BORDER
    # Glow behind the corner
    if glow_color:
        def glow_shape(i, c):
            draw.polygon([(0, 0), (w, 0), (w, i), (b + i, i), (b + i, h), (0, h)], fill=c)
        _draw_glow(draw, glow_shape, glow_color, 2)

    # Main L-shape corner piece
    draw.polygon([(0, 0), (w, 0), (w, b), (b, b), (b, h), (0, h)], fill=color)

    # Inner edge line for definition
    inner = color[:3] + (180,)
    draw.line([(b, b), (b, h)], fill=inner, width=2)
    draw.line([(b, b), (w, b)], fill=inner, width=2)

    return img


def _make_edge(w, h, color, glow_color, orientation="horizontal"):
    """Frame edge piece — straight border segment."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    b = FRAME_BORDER
    if orientation == "horizontal":
        if glow_color:
            def glow_shape(i, c):
                draw.rectangle([0, 0, w, i], fill=c)
            _draw_glow(draw, glow_shape, glow_color, 2)
        draw.rectangle([0, 0, w, b], fill=color)
        draw.line([(0, b), (w, b)], fill=color[:3] + (180,), width=2)
    else:
        if glow_color:
            def glow_shape(i, c):
                draw.rectangle([0, 0, i, h], fill=c)
            _draw_glow(draw, glow_shape, glow_color, 2)
        draw.rectangle([0, 0, b, h], fill=color)
        draw.line([(b, 0), (b, h)], fill=color[:3] + (180,), width=2)

    return img


def _make_decoration(w, h, color, glow_color, shape="circle"):
    """Decorative element centered on frame side."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = w // 2, h // 2

    if glow_color:
        for i in range(3, 0, -1):
            a = int(25 / i)
            c = (*glow_color[:3], a)
            if shape == "diamond":
                s = 35 + i * 3
                pts = [(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)]
                draw.polygon(pts, fill=None, outline=c, width=2)
            else:
                r = 35 + i * 3
                draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=None, outline=c, width=2)

    if shape == "diamond":
        s = 35
        pts = [(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)]
        draw.polygon(pts, fill=None, outline=color, width=4)
        # inner diamond
        s2 = 15
        pts2 = [(cx, cy - s2), (cx + s2, cy), (cx, cy + s2), (cx - s2, cy)]
        draw.polygon(pts2, fill=color[:3] + (200,), outline=None)

        # small accent circle at center
        draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 255, 255, 200))
    else:
        # circle
        draw.ellipse([cx - 35, cy - 35, cx + 35, cy + 35], fill=None, outline=color, width=4)
        # inner circle
        draw.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=color[:3] + (200,), outline=None)
        # accent
        draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 255, 255, 200))

    return img


def generate_frame(name, corner_color, edge_color, decor_color, glow_color):
    base = os.path.join(ASSETS, "frames", name)
    os.makedirs(base, exist_ok=True)

    # corners 256x256
    for fname in ["tl", "tr", "bl", "br"]:
        img = _make_corner(256, 256, corner_color, glow_color)
        if fname == "tr":
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
        elif fname == "bl":
            img = img.transpose(Image.FLIP_TOP_BOTTOM)
        elif fname == "br":
            img = img.transpose(Image.FLIP_LEFT_RIGHT).transpose(Image.FLIP_TOP_BOTTOM)
        img.save(os.path.join(base, f"{fname}.webp"), lossless=True)

    # edges
    edges_data = [
        ("top", "horizontal"), ("bottom", "horizontal"),
        ("left", "vertical"), ("right", "vertical"),
    ]
    for fname, orient in edges_data:
        w, h = (512, 128) if orient == "horizontal" else (128, 512)
        img = _make_edge(w, h, edge_color, glow_color, orient)
        if fname == "bottom":
            img = img.transpose(Image.FLIP_TOP_BOTTOM)
        elif fname == "right":
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
        img.save(os.path.join(base, f"{fname}.webp"), lossless=True)

    # decorations 256x256
    decor_names = ["top_center", "bottom_center", "left_center", "right_center"]
    shapes = ["diamond", "diamond", "circle", "circle"]
    for fname, shape in zip(decor_names, shapes):
        img = _make_decoration(256, 256, decor_color, glow_color, shape)
        if "bottom" in fname:
            img = img.transpose(Image.FLIP_TOP_BOTTOM)
        elif "right" in fname:
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
        img.save(os.path.join(base, f"{fname}.webp"), lossless=True)

    print(f"  Frame '{name}' generated ({len(os.listdir(base))} assets)")


def generate_background(name, color_scheme):
    """Generate a 1024x1024 board background."""
    img = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    bg, accent1, accent2, grid = color_scheme

    draw.rectangle([0, 0, 1024, 1024], fill=bg)

    for cx, cy in [(200, 200), (824, 200), (200, 824), (824, 824)]:
        for r in range(200, 0, -20):
            a = max(0, 15 - (200 - r) // 15)
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*accent1, a))

    for i in range(1, 9):
        pos = i * 114
        draw.line([pos, 0, pos, 1024], fill=(*grid, 30), width=1)
        draw.line([0, pos, 1024, pos], fill=(*grid, 30), width=1)

    for i in range(1, 3):
        pos = i * 341
        draw.line([pos, 0, pos, 1024], fill=(*accent2, 60), width=3)
        draw.line([0, pos, 1024, pos], fill=(*accent2, 60), width=3)

    path = os.path.join(ASSETS, "backgrounds", name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(f"{path}.webp", lossless=True)
    print(f"  Background '{name}' generated (1024x1024)")


def main():
    # ── Frames ──────────────────────────────────────────────────────────────
    generate_frame(
        "default",
        corner_color=(122, 95, 255, 255),     # #7A5FFF violet
        edge_color=(60, 50, 120, 200),
        decor_color=(122, 95, 255, 230),
        glow_color=(122, 95, 255),
    )

    generate_frame(
        "gold",
        corner_color=(215, 180, 90, 255),     # #D7B45A gold
        edge_color=(180, 150, 50, 200),
        decor_color=(215, 180, 90, 230),
        glow_color=(255, 215, 0),
    )

    generate_frame(
        "crystal",
        corner_color=(100, 180, 255, 255),    # light blue
        edge_color=(60, 140, 220, 200),
        decor_color=(100, 180, 255, 230),
        glow_color=(150, 210, 255),
    )

    generate_frame(
        "shadow",
        corner_color=(80, 80, 90, 255),       # dark gray
        edge_color=(50, 50, 60, 200),
        decor_color=(100, 100, 120, 200),
        glow_color=(60, 60, 80),
    )

    # ── Backgrounds ─────────────────────────────────────────────────────────
    generate_background("default_board", (
        (18, 18, 22, 255),
        (122, 95, 255),
        (80, 60, 180),
        (40, 40, 45),
    ))

    generate_background("night_board", (
        (10, 10, 30, 255),
        (60, 60, 150),
        (30, 30, 80),
        (25, 25, 60),
    ))

    generate_background("crystal_board", (
        (15, 25, 40, 255),
        (100, 180, 255),
        (50, 100, 180),
        (30, 50, 80),
    ))

    print("\nAll cosmetic assets generated successfully!")


if __name__ == "__main__":
    main()
