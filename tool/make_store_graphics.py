"""Google Play icon (512x512) and feature graphic (1024x500), from the app's logo, colors and font.

Run from version_mobile/:  python3 tool/make_store_graphics.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "version_mobile/assets/fonts"
OUT = ROOT / "version_mobile/google_play/images"
OUT.mkdir(parents=True, exist_ok=True)

BG = (15, 23, 42)
CARD = (30, 41, 59)
BORDER = (51, 65, 85)
TEXT = (248, 250, 252)
MUTED = (148, 163, 184)
ACTION = (245, 158, 11)
LEVELS = [
    ("Bronze", (217, 119, 6)),
    ("Silver", (203, 213, 225)),
    ("Gold", (250, 204, 21)),
    ("Platinum", (34, 211, 238)),
    ("Master", (168, 85, 247)),
    ("Titanium", (16, 185, 129)),
    ("Diamond", (56, 189, 248)),
    ("Master Diamond", (244, 63, 94)),
]

logo = Image.open(ROOT / "Global_logo.png").convert("RGBA")
bbox = logo.getbbox()
logo = logo.crop(bbox)


def font(weight, size):
    return ImageFont.truetype(str(FONTS / f"PlusJakartaSans-{weight}.ttf"), size)


def fit(img, box):
    img = img.copy()
    img.thumbnail(box, Image.LANCZOS)
    return img


def vertical_gradient(size, top, bottom):
    w, h = size
    grad = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(grad)
    for y in range(h):
        t = y / max(1, h - 1)
        draw.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return grad


# --- Icon: 512x512, full opaque background (Google rounds the corners itself) ---
icon = vertical_gradient((512, 512), CARD, BG).convert("RGBA")
mark = fit(logo, (420, 420))
icon.alpha_composite(mark, ((512 - mark.width) // 2, (512 - mark.height) // 2))
icon = icon.convert("RGB")
icon.save(OUT / "icone_512x512.png", optimize=True)

# --- Feature graphic: 1024x500, no transparency ---
W, H = 1024, 500
fg = vertical_gradient((W, H), CARD, BG).convert("RGBA")
draw = ImageDraw.Draw(fg)

# Soft glow behind the logo
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for r in range(200, 0, -8):
    alpha = int(26 * (1 - r / 200))
    gd.ellipse([215 - r, 215 - r, 215 + r, 215 + r], fill=(*ACTION, alpha))
fg.alpha_composite(glow)

mark = fit(logo, (300, 300))
fg.alpha_composite(mark, (215 - mark.width // 2, 215 - mark.height // 2))

x = 400
draw.text((x, 108), "THE GIFT EXCHANGE", font=font(800, 46), fill=TEXT)
draw.text((x, 162), "Global", font=font(800, 46), fill=ACTION)
draw.text((x, 236), "Community gifting, level by level.", font=font(600, 26), fill=(226, 232, 240))
draw.text((x, 274), "8 levels, from Bronze to Master Diamond", font=font(500, 22), fill=MUTED)

# The 8 level colors along the bottom
pill_font = font(700, 17)
pad, gap, y = 14, 10, 410
widths = [draw.textlength(name, font=pill_font) + 2 * pad for name, _ in LEVELS]
total = sum(widths) + gap * (len(LEVELS) - 1)
cx = (W - total) / 2
# Translucent pills: drawn on their own layer, then blended (ImageDraw replaces pixels instead of blending)
pills = Image.new("RGBA", (W, H), (0, 0, 0, 0))
pd = ImageDraw.Draw(pills)
positions = []
for (name, color), w in zip(LEVELS, widths):
    pd.rounded_rectangle([cx, y, cx + w, y + 38], radius=19, fill=(*color, 40), outline=(*color, 170), width=2)
    positions.append((cx, name, color))
    cx += w + gap
fg.alpha_composite(pills)
draw = ImageDraw.Draw(fg)
for px, name, color in positions:
    draw.text((px + pad, y + 8), name, font=pill_font, fill=color)

fg.convert("RGB").save(OUT / "image_presentation_1024x500.png", optimize=True)

for f in sorted(OUT.glob("*.png")):
    im = Image.open(f)
    print(f.name, im.size, im.mode)
