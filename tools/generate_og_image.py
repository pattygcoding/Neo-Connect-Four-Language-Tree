import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, "og-image.png")

WIDTH, HEIGHT = 1200, 630
NAVY = (5, 7, 12)
PANEL = (13, 19, 30)
MINT = (141, 235, 196)
TEXT = (233, 240, 238)
MUTED = (140, 156, 160)
RED = (239, 91, 91)
YELLOW = (244, 201, 84)
EMPTY = (22, 30, 44)

FONTS = os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")


def font(name, size):
    try:
        return ImageFont.truetype(os.path.join(FONTS, name), size)
    except OSError:
        return ImageFont.load_default(size)


# Rows top to bottom; the yellow diagonal is the winning four.
BOARD = [
    ".......",
    ".......",
    "...Y...",
    "..YR...",
    ".YRRR..",
    "YRYYRR.",
]
WINNING = {(5, 0), (4, 1), (3, 2), (2, 3)}


def main():
    image = Image.new("RGB", (WIDTH, HEIGHT), NAVY)
    draw = ImageDraw.Draw(image)

    draw.rectangle((0, 0, WIDTH, 8), fill=MINT)

    # Board on the right.
    cell, gap = 62, 10
    board_w = 7 * cell + 8 * gap
    board_h = 6 * cell + 7 * gap
    left = WIDTH - board_w - 70
    top = (HEIGHT - board_h) // 2 + 8
    draw.rounded_rectangle((left, top, left + board_w, top + board_h), radius=24, fill=PANEL, outline=(30, 44, 62), width=2)
    for r, line in enumerate(BOARD):
        for c, ch in enumerate(line):
            x = left + gap + c * (cell + gap)
            y = top + gap + r * (cell + gap)
            colour = {"R": RED, "Y": YELLOW}.get(ch, EMPTY)
            draw.ellipse((x, y, x + cell, y + cell), fill=colour)
            if (r, c) in WINNING:
                draw.ellipse((x - 4, y - 4, x + cell + 4, y + cell + 4), outline=MINT, width=4)

    # Text on the left.
    draw.text((70, 110), "ONE GAME  /  43 LANGUAGES  /  33 FRAMEWORKS", font=font("consola.ttf", 20), fill=MINT)
    heading = font("segoeuib.ttf", 62)
    draw.text((70, 165), "Connect Four", font=heading, fill=TEXT)
    draw.text((70, 245), "Multi-Language", font=heading, fill=MINT)
    draw.text((70, 325), "Showcase", font=heading, fill=TEXT)
    body = font("segoeui.ttf", 28)
    draw.text((70, 450), "The same game, byte-for-byte identical", font=body, fill=MUTED)
    draw.text((70, 488), "output, in every language.", font=body, fill=MUTED)
    draw.text((70, 560), "connectfour.pattygcoding.com", font=font("consola.ttf", 24), fill=MINT)

    image.save(OUTPUT, optimize=True)
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    sys.exit(main())
