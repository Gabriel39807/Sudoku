#!/usr/bin/env python3
"""Generate master_reference — frame geometry reference design.

Canvas sizes:
  Corners:  512×512
  Sides:    512×256 (horizontal), 256×512 (vertical)
  Centers:  384×384

Constants:
  SAFE_PAD     = 96  — no decoration touches border
  FRAME_THICK  = 72  — exact visual grosor, matches sides

All assets are lossless WebP with alpha transparency.
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

ASSETS = r"C:\Users\picos\OneDrive\Desktop\Sudoku\flutter_app\assets\cosmetics"
BASE = os.path.join(ASSETS, "frames", "master_reference")

SIZE = 512
SAFE_PAD = 96
FT = 72  # FRAME_THICKNESS

COLOR_FRAME = (122, 95, 255, 255)
COLOR_EDGE = (60, 50, 120, 200)
COLOR_GLOW = (122, 95, 255)
COLOR_INNER = (160, 140, 255, 180)
COLOR_BOARD = (30, 30, 40, 255)
COLOR_ORNAMENT = (200, 180, 255, 220)
COLOR_SAFE = (0, 200, 80, 40)
COLOR_DANGER = (200, 0, 0, 40)


def _draw_glow(draw, shape_fn, iterations=3, base_alpha=25):
    for i in range(iterations, 0, -1):
        a = int(base_alpha / i)
        c = (*COLOR_GLOW[:3], a)
        shape_fn(i, c)


def make_corner_tl():
    """Top-left corner: L from (SAFE_PAD, SAFE_PAD), arm=FT, spanning to SAFE_PAD on opposite edge."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    x1 = SAFE_PAD
    y1 = SAFE_PAD
    x2 = SAFE_PAD + FT
    y2 = SAFE_PAD + FT
    far = SIZE - SAFE_PAD

    def glow_shape(i, c):
        inflate = i * 6
        draw.polygon([
            (x1 - inflate, y1 - inflate),
            (far + inflate, y1 - inflate),
            (far + inflate, y2 + inflate),
            (x2 + inflate, y2 + inflate),
            (x2 + inflate, far + inflate),
            (x1 - inflate, far + inflate),
        ], fill=c)
    _draw_glow(draw, glow_shape)

    draw.polygon([
        (x1, y1), (far, y1), (far, y2),
        (x2, y2), (x2, far), (x1, far),
    ], fill=COLOR_FRAME)

    draw.line([(far, y2), (x2, y2)], fill=COLOR_INNER, width=3)
    draw.line([(x2, y2), (x2, far)], fill=COLOR_INNER, width=3)

    return img


def make_corner_tr():
    return make_corner_tl().transpose(Image.FLIP_LEFT_RIGHT)


def make_corner_bl():
    return make_corner_tl().transpose(Image.FLIP_TOP_BOTTOM)


def make_corner_br():
    return make_corner_tl().transpose(Image.FLIP_LEFT_RIGHT).transpose(Image.FLIP_TOP_BOTTOM)


def make_side_top():
    img = Image.new("RGBA", (SIZE, SIZE // 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def glow_shape(i, c):
        draw.rectangle([-i * 6, -i * 6, SIZE + i * 6, FT + i * 6], fill=c)
    _draw_glow(draw, glow_shape)

    draw.rectangle([0, 0, SIZE, FT], fill=COLOR_FRAME)
    draw.line([(0, FT), (SIZE, FT)], fill=COLOR_INNER, width=3)
    return img


def make_side_bottom():
    return make_side_top().transpose(Image.FLIP_TOP_BOTTOM)


def make_side_left():
    img = Image.new("RGBA", (SIZE // 2, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def glow_shape(i, c):
        draw.rectangle([-i * 6, -i * 6, FT + i * 6, SIZE + i * 6], fill=c)
    _draw_glow(draw, glow_shape)

    draw.rectangle([0, 0, FT, SIZE], fill=COLOR_FRAME)
    draw.line([(FT, 0), (FT, SIZE)], fill=COLOR_INNER, width=3)
    return img


def make_side_right():
    return make_side_left().transpose(Image.FLIP_LEFT_RIGHT)


def make_center_decor():
    """Decorative ornament: extends outward, NEVER inward.

    The ornament sits within the 72px frame strip. On the top edge, the frame
    is at the top of the board, so 'outward' means upward (away from board).
    For this reference, we draw a diamond/crystal that extends upward.

    Canvas: 384×384. The frame zone is the bottom-most 72px (for top_center).
    The remaining 384−72 = 312px above is the outward-safe zone.
    """
    img = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 192, 72 + 60  # center of frame zone + slight upward offset

    for i in range(3, 0, -1):
        a = int(20 / i)
        c = (*COLOR_GLOW[:3], a)
        s = 80 + i * 8
        draw.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)],
                      fill=None, outline=c, width=3)

    s = 80
    draw.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)],
                 fill=None, outline=COLOR_ORNAMENT, width=5)

    s2 = 35
    draw.polygon([(cx, cy - s2), (cx + s2, cy), (cx, cy + s2), (cx - s2, cy)],
                 fill=COLOR_ORNAMENT)

    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(255, 255, 255, 220))

    return img


def make_center_top():
    return make_center_decor()


def make_center_bottom():
    return make_center_decor().transpose(Image.FLIP_TOP_BOTTOM)


def make_center_left():
    return make_center_decor().transpose(Image.ROTATE_90)


def make_center_right():
    return make_center_decor().transpose(Image.ROTATE_270)


def make_preview():
    """Assembled master preview: perfect square 2048×2048.

    Layout:
        TL(512) | Top(1024) | TR(512)
        Left    | Board     | Right
        BL      | Bottom    | BR
    """
    board_size = 1024
    total = SIZE + board_size + SIZE  # 2048
    preview = Image.new("RGBA", (total, total), (0, 0, 0, 0))

    corners = {
        (0, 0): make_corner_tl(),
        (SIZE + board_size, 0): make_corner_tr(),
        (0, SIZE + board_size): make_corner_bl(),
        (SIZE + board_size, SIZE + board_size): make_corner_br(),
    }
    for (x, y), img in corners.items():
        preview.paste(img, (x, y), img)

    top = make_side_top().resize((board_size, SIZE), Image.LANCZOS)
    preview.paste(top, (SIZE, 0), top)

    bottom = make_side_bottom().resize((board_size, SIZE), Image.LANCZOS)
    preview.paste(bottom, (SIZE, SIZE + board_size), bottom)

    left = make_side_left().resize((SIZE, board_size), Image.LANCZOS)
    preview.paste(left, (0, SIZE), left)

    right = make_side_right().resize((SIZE, board_size), Image.LANCZOS)
    preview.paste(right, (SIZE + board_size, SIZE), right)

    board_bg = Image.new("RGBA", (board_size, board_size), COLOR_BOARD)
    draw = ImageDraw.Draw(board_bg)
    for i in range(0, board_size, board_size // 9):
        draw.line([(i, 0), (i, board_size)], fill=(50, 50, 60, 255), width=1)
        draw.line([(0, i), (board_size, i)], fill=(50, 50, 60, 255), width=1)
    preview.paste(board_bg, (SIZE, SIZE), board_bg)

    return preview


def make_ornament_safe_zone():
    """Overlay showing where ornaments can extend — outward only, never inward.

    Green = safe (outward). Red = forbidden (inward).
    For the top edge: outward = upward (y < 72 zone in side coords).
    """
    total = 2048
    board_size = 1024
    img = Image.new("RGBA", (total, total), (0, 0, 0, 200))
    draw = ImageDraw.Draw(img)

    safe_regions = [
        # Top edge: outward = upward
        (SIZE, 0, SIZE + board_size, FT),
        # Bottom edge: outward = downward
        (SIZE, SIZE + board_size, SIZE + board_size, total),
        # Left edge: outward = left
        (0, SIZE, FT, SIZE + board_size),
        # Right edge: outward = right
        (SIZE + board_size, SIZE, total, SIZE + board_size),
    ]

    danger_regions = [
        # Top edge: inward = downward
        (SIZE, total - FT, SIZE + board_size, total),
        # Bottom edge: inward = upward
        (SIZE, 0, SIZE + board_size, FT),
        # Left edge: inward = right
        (total - FT, SIZE, total, SIZE + board_size),
        # Right edge: inward = left
        (0, SIZE, FT, SIZE + board_size),
    ]

    for rx, ry, rw, rh in safe_regions:
        draw.rectangle([rx, ry, rw, rh], fill=COLOR_SAFE)

    for rx, ry, rw, rh in danger_regions:
        draw.rectangle([rx, ry, rw, rh], fill=COLOR_DANGER)

    for x in range(SIZE, total - SIZE, board_size // 4):
        draw.line([(x, 0), (x, total)], fill=(255, 255, 255, 30), width=1)
        draw.line([(0, x), (total, x)], fill=(255, 255, 255, 30), width=1)

    return img


def main():
    os.makedirs(BASE, exist_ok=True)

    assets = {
        "top_left.webp": make_corner_tl(),
        "top_right.webp": make_corner_tr(),
        "bottom_left.webp": make_corner_bl(),
        "bottom_right.webp": make_corner_br(),
        "top.webp": make_side_top(),
        "bottom.webp": make_side_bottom(),
        "left.webp": make_side_left(),
        "right.webp": make_side_right(),
        "top_center.webp": make_center_top(),
        "bottom_center.webp": make_center_bottom(),
        "left_center.webp": make_center_left(),
        "right_center.webp": make_center_right(),
    }

    for name, img in assets.items():
        img.save(os.path.join(BASE, name), lossless=True)

    preview = make_preview()
    preview.save(os.path.join(BASE, "master_preview.png"))

    safe_zone = make_ornament_safe_zone()
    safe_zone.save(os.path.join(BASE, "ornament_safe_zone.png"))

    print(f"  master_reference generated ({len(os.listdir(BASE))} assets in {BASE})")


if __name__ == "__main__":
    main()
