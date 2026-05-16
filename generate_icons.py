"""
Pro PT Asistanı — App Icon Generator
Design: Dark #141416 bg, decorative dot, bold PT, tracked Asistanı
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

# ── Sizes required by iOS ──────────────────────────────────────────────────
SIZES = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]

# ── Colors ─────────────────────────────────────────────────────────────────
BG         = (20, 20, 22)          # #141416
BG_CENTER  = (30, 30, 36)          # subtle centre glow
WHITE      = (245, 244, 240)       # #F5F4F0
WHITE_DIM  = (200, 198, 195)
RING_DIM   = (58, 58, 60)          # #3A3A3C

# ── Font paths ─────────────────────────────────────────────────────────────
FUTURA_BOLD   = "/System/Library/Fonts/Supplemental/Futura.ttc"
FUTURA_MEDIUM = "/System/Library/Fonts/Supplemental/Futura.ttc"


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def radial_gradient_bg(draw, size):
    """Paint a subtle radial gradient: slightly lighter centre → dark edges."""
    cx, cy = size / 2, size / 2
    max_r  = math.hypot(cx, cy)
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / max_r
            # 0 at centre (BG_CENTER), 1 at corner (BG)
            t = min(d * 1.4, 1.0)
            c = lerp_color(BG_CENTER, BG, t)
            draw.point((x, y), fill=c)


def draw_decorative_dot(draw, cx, top_y, size):
    """
    Three concentric circles that suggest a crosshair / PT brand mark.
    Outer ring (dim), middle filled circle (white), tiny centre dot.
    """
    r_outer  = size * 0.048
    r_mid    = size * 0.028
    r_inner  = size * 0.010
    dot_cy   = top_y

    # Outer ring
    draw.ellipse(
        [cx - r_outer, dot_cy - r_outer, cx + r_outer, dot_cy + r_outer],
        outline=RING_DIM, width=max(1, int(size * 0.005))
    )
    # Middle filled white circle
    draw.ellipse(
        [cx - r_mid, dot_cy - r_mid, cx + r_mid, dot_cy + r_mid],
        fill=WHITE_DIM
    )
    # Tiny bright centre
    draw.ellipse(
        [cx - r_inner, dot_cy - r_inner, cx + r_inner, dot_cy + r_inner],
        fill=WHITE
    )


def letter_spaced_text(draw, x, y, text, font, spacing, fill, anchor="mm"):
    """Draw text with custom letter spacing, centred on (x, y)."""
    # Measure total width
    widths = []
    for ch in text:
        bb = font.getbbox(ch)
        widths.append(bb[2] - bb[0])
    total_w = sum(widths) + spacing * (len(text) - 1)

    cur_x = x - total_w / 2
    # Vertical centre: use font metrics
    ascent, descent = font.getmetrics()
    cur_y = y - ascent / 2

    for i, ch in enumerate(text):
        draw.text((cur_x, cur_y), ch, font=font, fill=fill, anchor="lt")
        cur_x += widths[i] + spacing


def make_icon(size: int) -> Image.Image:
    img  = Image.new("RGB", (size, size), BG)
    draw = ImageDraw.Draw(img)

    # 1. Radial gradient background (skip for tiny icons — too slow & invisible)
    if size >= 80:
        radial_gradient_bg(draw, size)

    cx = size / 2

    # 2. Decorative dot  ────────────────────────────────────────────────────
    #    Positioned at ~26 % from top
    dot_y  = size * 0.255
    if size >= 40:
        draw_decorative_dot(draw, cx, dot_y, size)

    # 3. "PT" ───────────────────────────────────────────────────────────────
    #    Bold, index=1 in the .ttc (Bold variant)
    pt_size   = int(size * 0.40)
    try:
        pt_font = ImageFont.truetype(FUTURA_BOLD, pt_size, index=2)   # Futura Bold (upright)
    except Exception:
        pt_font = ImageFont.truetype(FUTURA_BOLD, pt_size)

    pt_y   = size * 0.555    # görsel ağırlık merkezi (nokta yukarıda olduğu için hafif aşağı)
    draw.text((cx, pt_y), "PT", font=pt_font, fill=WHITE, anchor="mm")

    # "ASISTANI" kaldırıldı — sadece nokta + PT

    return img


def main():
    appiconset = (
        "/Users/mustafa/Desktop/ProPTAsistani/ProPTAsistani/"
        "Assets.xcassets/AppIcon.appiconset"
    )
    os.makedirs(appiconset, exist_ok=True)

    # ── All required iOS sizes ─────────────────────────────────────────────
    # (idiom, size_pt, scale, pixel_size)
    specs = [
        # iPhone
        ("iphone", "20x20",   "2x",  40),
        ("iphone", "20x20",   "3x",  60),
        ("iphone", "29x29",   "1x",  29),
        ("iphone", "29x29",   "2x",  58),
        ("iphone", "29x29",   "3x",  87),
        ("iphone", "40x40",   "2x",  80),
        ("iphone", "40x40",   "3x", 120),
        ("iphone", "60x60",   "2x", 120),
        ("iphone", "60x60",   "3x", 180),
        # iPad
        ("ipad",   "20x20",   "1x",  20),
        ("ipad",   "20x20",   "2x",  40),
        ("ipad",   "29x29",   "1x",  29),
        ("ipad",   "29x29",   "2x",  58),
        ("ipad",   "40x40",   "1x",  40),
        ("ipad",   "40x40",   "2x",  80),
        ("ipad",   "76x76",   "1x",  76),
        ("ipad",   "76x76",   "2x", 152),
        ("ipad",   "83.5x83.5","2x", 167),
        # App Store
        ("ios-marketing", "1024x1024", "1x", 1024),
    ]

    # Cache rendered sizes to avoid duplicates
    cache = {}
    image_entries = []

    for idiom, size_str, scale, px in specs:
        fname = f"AppIcon-{idiom}-{px}.png"
        if px not in cache:
            img = make_icon(px)
            img.save(os.path.join(appiconset, fname), "PNG")
            cache[px] = fname
            print(f"  ✓  {fname}")
        else:
            # Reuse already-rendered file with a symlink-free copy
            import shutil
            src = os.path.join(appiconset, cache[px])
            dst = os.path.join(appiconset, fname)
            if src != dst:
                shutil.copy2(src, dst)
            print(f"  ✓  {fname}  (copy of {cache[px]})")

        image_entries.append({
            "idiom": idiom,
            "size": size_str,
            "scale": scale,
            "filename": fname,
        })

    # ── Contents.json ──────────────────────────────────────────────────────
    import json
    contents = {
        "images": [
            {k: v for k, v in e.items()} for e in image_entries
        ],
        "info": {"author": "xcode", "version": 1}
    }
    with open(os.path.join(appiconset, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print("\n  ✓  Contents.json yazıldı")

    # Preview
    preview = "/Users/mustafa/Desktop/ProPTAsistani/AppIcons/preview_1024.png"
    os.makedirs(os.path.dirname(preview), exist_ok=True)
    cache_img = make_icon(1024)
    cache_img.save(preview)
    print(f"  ✓  Preview  →  {preview}")
    print("\nDone.")


if __name__ == "__main__":
    main()
