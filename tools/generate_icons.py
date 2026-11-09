#!/usr/bin/env python3
"""Generates the app icon, adaptive-icon layers and the ORBIT SHIFT logo (PNG)."""
import os, math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "icons")
FONT = os.path.join(ROOT, "assets", "fonts", "Orbitron.ttf")
os.makedirs(OUT, exist_ok=True)
BG = (5, 10, 24); CYAN = (25, 240, 255); VIOLET = (155, 92, 255); CORAL = (255, 77, 94); GOLD = (255, 194, 51)

def glow(layer, radius, strength=1.0):
    blur = layer.filter(ImageFilter.GaussianBlur(radius))
    out = Image.alpha_composite(Image.new("RGBA", layer.size, (0, 0, 0, 0)), blur)
    for _ in range(int(strength)): out = Image.alpha_composite(out, blur)
    return Image.alpha_composite(out, layer)

def orbit_art(size, with_bg=True, scale=1.0):
    S = size * 2  # supersample
    img = Image.new("RGBA", (S, S), BG + (255,) if with_bg else (0, 0, 0, 0))
    if with_bg:
        d = ImageDraw.Draw(img)
        for i in range(60):
            r = S * 0.75 * (1 - i / 60); a = int(40 * (i / 60))
            d.ellipse([S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r], fill=(20, 30, 80, a))
    c = S / 2; radii = [0.17 * scale, 0.28 * scale, 0.39 * scale]
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    for i, r in enumerate(radii):
        rr = r * S; w = max(2, int(S * 0.012))
        d.ellipse([c - rr, c - rr, c + rr, c + rr], outline=VIOLET + (200,), width=w)
    # obstacle arcs (coral)
    for r, a0, a1 in ((radii[2], 20, 70), (radii[0], 200, 250), (radii[1], 290, 330)):
        rr = r * S; d.arc([c - rr, c - rr, c + rr, c + rr], a0, a1, fill=CORAL + (255,), width=int(S * 0.03))
    # crystals
    for r, a in ((radii[1], 120), (radii[2], 215), (radii[0], 330)):
        x = c + math.cos(math.radians(a)) * r * S; y = c + math.sin(math.radians(a)) * r * S; k = S * 0.022
        d.polygon([(x, y - k * 1.6), (x + k, y), (x, y + k * 1.6), (x - k, y)], fill=GOLD + (255,))
    layer = glow(layer, S * 0.012, 1)
    img = Image.alpha_composite(img, layer)
    # core
    core = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(core); kr = 0.085 * scale * S
    d.ellipse([c - kr, c - kr, c + kr, c + kr], fill=(13, 31, 92, 255), outline=(43, 92, 255, 255), width=int(S * 0.01))
    core = glow(core, S * 0.02, 1); img = Image.alpha_composite(img, core)
    # player sphere
    ang = math.radians(-35); px = c + math.cos(ang) * radii[1] * S; py = c + math.sin(ang) * radii[1] * S
    pl = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(pl); pr = 0.05 * scale * S
    d.ellipse([px - pr * 1.25, py - pr * 1.25, px + pr * 1.25, py + pr * 1.25], fill=CYAN + (170,))
    pl = glow(pl, S * 0.022, 2); img = Image.alpha_composite(img, pl)
    sp = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(sp)
    d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=CYAN + (255,))
    d.ellipse([px - pr * 0.55, py - pr * 0.65, px + pr * 0.05, py - pr * 0.1], fill=(235, 255, 255, 255))
    img = Image.alpha_composite(img, sp)
    return img.resize((size, size), Image.LANCZOS)

def font(size, weight="Black"):
    f = ImageFont.truetype(FONT, size)
    try: f.set_variation_by_name(weight)
    except Exception: pass
    return f

def logo(w=1400, h=520):
    S = 2
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    f1 = font(250 * S); f2 = font(250 * S)
    def centered(text, y, fnt, fill):
        bb = d.textbbox((0, 0), text, font=fnt); x = (w * S - (bb[2] - bb[0])) / 2 - bb[0]; d.text((x, y), text, font=fnt, fill=fill)
    # orbit arcs
    cx, cy = w * S / 2, h * S / 2
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0)); dl = ImageDraw.Draw(lay)
    dl.ellipse([cx - 640 * S, cy - 120 * S, cx + 640 * S, cy + 120 * S], outline=VIOLET + (180,), width=5 * S)
    lay = glow(lay, 8 * S, 1); img = Image.alpha_composite(img, lay); d = ImageDraw.Draw(img)
    txt = Image.new("RGBA", img.size, (0, 0, 0, 0)); dt = ImageDraw.Draw(txt)
    d2 = dt
    bb = d2.textbbox((0, 0), "ORBIT", font=f1); x = (w * S - (bb[2] - bb[0])) / 2 - bb[0]; d2.text((x, 40 * S), "ORBIT", font=f1, fill=CYAN + (255,))
    bb = d2.textbbox((0, 0), "SHIFT", font=f2); x = (w * S - (bb[2] - bb[0])) / 2 - bb[0]; d2.text((x, 250 * S), "SHIFT", font=f2, fill=(244, 248, 255, 255))
    txt = glow(txt, 10 * S, 1); img = Image.alpha_composite(img, txt)
    return img.resize((w, h), Image.LANCZOS)

icon = orbit_art(512); icon.convert("RGB").save(os.path.join(OUT, "icon.png"))
orbit_art(192).convert("RGB").save(os.path.join(OUT, "icon_192.png"))
orbit_art(432, with_bg=False, scale=0.62).save(os.path.join(OUT, "icon_adaptive_foreground.png"))
Image.new("RGBA", (432, 432), BG + (255,)).save(os.path.join(OUT, "icon_adaptive_background.png"))
orbit_art(512, with_bg=False, scale=0.62).save(os.path.join(OUT, "icon_monochrome.png"))
orbit_art(1024).convert("RGB").save(os.path.join(OUT, "icon_ios_1024.png"))
logo().save(os.path.join(OUT, "logo.png"))
print("icons written")
