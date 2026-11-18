#!/usr/bin/env python3
"""render-screenshots.py — preview renders of Brainrot Lagoon for screenshots/.

Roblox Studio does not run on this Linux VM, so real Studio captures are impossible
here. These are faithful preview renders of the game's own world and characters,
drawn from the same map layout (GameConfig) and the same character catalog
(BrainrotCatalog): the island, the conveyor, the six bases, the shop, the portal,
the tsunami wall and the HUD. Each image is labelled PREVIEW RENDER.
Output: 1280x720 JPEGs, each under 256 KiB.
"""
import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720
OUT = "/home/hatch/workspace/makefun/roblox-brainrot/screenshots"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

def font(size, bold=True):
    return ImageFont.truetype(BOLD if bold else REG, max(8, int(size)))

def sky(draw):
    for y in range(H):
        t = y / H
        r = int(135 + (200 - 135) * t)
        g = int(206 + (225 - 206) * t)
        b = int(250 + (255 - 250) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

def water(draw):
    draw.rectangle([0, 470, W, H], fill=(38, 110, 210))
    for i in range(30):
        x = (i * 173) % W
        y = 490 + (i * 47) % 210
        draw.arc([x, y, x + 90, y + 14], 0, 180, fill=(90, 170, 255), width=3)

def make_iso(cx, cy, s):
    def iso(x, z, y=0):
        return (cx + (x - z) * 0.866 * s, cy + (x + z) * 0.5 * s - y * s)
    return iso

def poly(draw, pts, fill, outline=None):
    draw.polygon(pts, fill=fill, outline=outline)

def iso_box(draw, iso, x, z, w, d, h, top, side):
    corners = [iso(x - w/2, z - d/2), iso(x + w/2, z - d/2), iso(x + w/2, z + d/2), iso(x - w/2, z + d/2)]
    top_pts = [(px, py - h) for px, py in corners]
    poly(draw, [corners[2], corners[3], top_pts[3], top_pts[2]], fill=side)
    poly(draw, [corners[1], corners[2], top_pts[2], top_pts[1]], fill=tuple(max(0, v - 25) for v in side))
    poly(draw, top_pts, fill=top)

def shade(rgb, f):
    return tuple(max(0, min(255, int(v * f))) for v in rgb)

def label(draw, sx, y, name, rarity_text, rarity_color, rate, k=1.0):
    f1, f2, f3 = font(19 * k), font(15 * k), font(16 * k)
    for txt, f, col, dy in ((name, f1, (255, 255, 255), 0), (rarity_text, f2, rarity_color, 22 * k), (rate, f3, (120, 255, 130), 42 * k)):
        bb = draw.textbbox((0, 0), txt, font=f)
        w = bb[2] - bb[0]
        draw.text((sx - w / 2, y + dy), txt, font=f, fill=col, stroke_width=3, stroke_fill=(20, 20, 30))

def draw_character(draw, sx, sy, scale, body, shape, accessory, name, rarity, rarity_color, rate, mutation=None, lk=1.0):
    bw, bh = 3.0 * scale, 3.0 * scale
    x0, y0 = sx - bw / 2, sy - bh
    outline = (30, 30, 40)
    if shape == "Ball":
        draw.ellipse([x0, y0, x0 + bw, y0 + bh], fill=body, outline=outline, width=3)
    elif shape == "Cylinder":
        draw.ellipse([x0, y0, x0 + bw, y0 + bh * 0.45], fill=shade(body, 1.25), outline=outline, width=2)
        draw.rectangle([x0, y0 + bh * 0.2, x0 + bw, y0 + bh * 0.85], fill=body, outline=outline, width=2)
        draw.ellipse([x0, y0 + bh * 0.62, x0 + bw, y0 + bh], fill=shade(body, 0.75), outline=outline, width=2)
    else:
        draw.rounded_rectangle([x0, y0, x0 + bw, y0 + bh], radius=int(scale * 0.5), fill=body, outline=outline, width=3)
    draw.rectangle([x0 + bw*0.12, y0 + bh - 2, x0 + bw*0.38, y0 + bh + scale*0.35], fill=(40, 40, 40))
    draw.rectangle([x0 + bw*0.62, y0 + bh - 2, x0 + bw*0.88, y0 + bh + scale*0.35], fill=(40, 40, 40))
    for ex in (sx - bw*0.22, sx + bw*0.22):
        draw.ellipse([ex - scale*0.42, y0 + bh*0.22, ex + scale*0.42, y0 + bh*0.22 + scale*0.84], fill=(255, 255, 255), outline=outline, width=2)
        draw.ellipse([ex - scale*0.16, y0 + bh*0.42, ex + scale*0.16, y0 + bh*0.42 + scale*0.32], fill=(20, 20, 20))
    if accessory == "hat":
        draw.rectangle([sx - bw*0.58, y0 - scale*0.45, sx + bw*0.58, y0 - scale*0.05], fill=(40, 40, 60))
        draw.rectangle([sx - bw*0.3, y0 - scale*1.25, sx + bw*0.3, y0 - scale*0.35], fill=(40, 40, 60))
    elif accessory == "crown":
        pts = [(sx - bw*0.45, y0 - scale*0.1), (sx - bw*0.45, y0 - scale*0.8), (sx - bw*0.22, y0 - scale*0.35),
               (sx, y0 - scale*0.95), (sx + bw*0.22, y0 - scale*0.35), (sx + bw*0.45, y0 - scale*0.8), (sx + bw*0.45, y0 - scale*0.1)]
        draw.polygon(pts, fill=(255, 215, 0), outline=(150, 110, 0))
    elif accessory == "antenna":
        draw.line([sx, y0, sx, y0 - scale*1.1], fill=(60, 60, 60), width=4)
        draw.ellipse([sx - scale*0.3, y0 - scale*1.45, sx + scale*0.3, y0 - scale*0.85], fill=(255, 80, 80))
    elif accessory == "wheels":
        for wx in (x0 - scale*0.15, x0 + bw - scale*0.15):
            draw.ellipse([wx, y0 + bh - scale*0.5, wx + scale*0.7, y0 + bh + scale*0.2], fill=(30, 30, 30))
    ly = y0 - scale * (2.1 if accessory in ("hat", "crown", "antenna") else 1.5)
    label(draw, sx, ly, name, f"{rarity}" + (f"  •  {mutation}" if mutation else ""), rarity_color, rate, lk)

def draw_player(draw, sx, sy, scale, name="nyx"):
    u = scale
    draw.rectangle([sx - u*0.55, sy - u*1.1, sx - u*0.05, sy], fill=(90, 160, 60), outline=(30, 30, 40), width=2)
    draw.rectangle([sx + u*0.05, sy - u*1.1, sx + u*0.55, sy], fill=(90, 160, 60), outline=(30, 30, 40), width=2)
    draw.rectangle([sx - u*0.7, sy - u*2.3, sx + u*0.7, sy - u*1.1], fill=(60, 120, 220), outline=(30, 30, 40), width=2)
    draw.rectangle([sx - u*1.05, sy - u*2.25, sx - u*0.7, sy - u*1.2], fill=(255, 220, 130), outline=(30, 30, 40), width=2)
    draw.rectangle([sx + u*0.7, sy - u*2.25, sx + u*1.05, sy - u*1.2], fill=(255, 220, 130), outline=(30, 30, 40), width=2)
    draw.rounded_rectangle([sx - u*0.55, sy - u*3.3, sx + u*0.55, sy - u*2.3], radius=int(u*0.2), fill=(255, 220, 130), outline=(30, 30, 40), width=2)
    draw.ellipse([sx - u*0.3, sy - u*2.95, sx - u*0.05, sy - u*2.7], fill=(20, 20, 20))
    draw.ellipse([sx + u*0.05, sy - u*2.95, sx + u*0.3, sy - u*2.7], fill=(20, 20, 20))
    if name:
        f = font(15)
        bb = draw.textbbox((0, 0), name, font=f)
        draw.text((sx - (bb[2]-bb[0])/2, sy - u*3.9), name, font=f, fill=(255, 255, 255), stroke_width=3, stroke_fill=(20, 20, 30))

def hud(draw, cash="$1,240", income="+$142/s", rebirth="Rebirth 1", wave="Noodle Tsunami in 42s", wave_color=(140, 220, 255), wave_bg=(20, 20, 30)):
    def bar(x, y, w, text, size, col):
        draw.rounded_rectangle([x, y, x + w, y + 52], radius=8, fill=(20, 20, 30))
        f = font(size)
        bb = draw.textbbox((0, 0), text, font=f)
        draw.text((x + (w - (bb[2]-bb[0])) / 2, y + (52 - (bb[3]-bb[1])) / 2 - 4), text, font=f, fill=col, stroke_width=2, stroke_fill=(0, 0, 0))
    bar(370, 12, 220, cash, 28, (120, 255, 130))
    bar(600, 12, 170, income, 24, (255, 230, 120))
    bar(780, 12, 130, rebirth, 19, (200, 150, 255))
    draw.rounded_rectangle([370, 76, 910, 120], radius=8, fill=wave_bg)
    f = font(22)
    bb = draw.textbbox((0, 0), wave, font=f)
    draw.text((640 - (bb[2]-bb[0]) / 2, 76 + (44 - (bb[3]-bb[1])) / 2 - 4), wave, font=f, fill=wave_color, stroke_width=2, stroke_fill=(0, 0, 0))
    for i, (txt, col) in enumerate((("SLAP  [F]", (230, 80, 80)), ("LOCK BASE  [L]", (70, 130, 230)),
                                    ("REBIRTH", (160, 80, 220)), ("CATALOG + SHOP", (60, 180, 120)))):
        y = 140 + i * 62
        draw.rounded_rectangle([1074, y, 1264, y + 52], radius=10, fill=col)
        f = font(17)
        bb = draw.textbbox((0, 0), txt, font=f)
        draw.text((1169 - (bb[2]-bb[0]) / 2, y + 15), txt, font=f, fill=(255, 255, 255))

def toast(draw, text, y=600):
    f = font(18)
    bb = draw.textbbox((0, 0), text, font=f)
    w = bb[2] - bb[0] + 36
    x0 = 640 - w / 2
    draw.rounded_rectangle([x0, y, x0 + w, y + 40], radius=8, fill=(20, 20, 30))
    draw.text((640 - (bb[2]-bb[0]) / 2, y + 8), text, font=f, fill=(255, 255, 255))

def tag(draw):
    f = font(14)
    txt = "PREVIEW RENDER — not a Studio capture"
    bb = draw.textbbox((0, 0), txt, font=f)
    draw.rounded_rectangle([W - (bb[2]-bb[0]) - 28, H - 34, W - 8, H - 8], radius=6, fill=(0, 0, 0))
    draw.text((W - (bb[2]-bb[0]) - 18, H - 30), txt, font=f, fill=(255, 255, 255))

def island_base(draw, iso):
    def diamond(cx, cz, half, fill):
        pts = [iso(cx - half, cz), iso(cx, cz - half), iso(cx + half, cz), iso(cx, cz + half)]
        draw.polygon(pts, fill=fill)
    diamond(0, 0, 120, (235, 210, 150))
    diamond(0, 0, 110, (90, 180, 80))

def conveyor(draw, iso):
    x0, x1, z = -95, 95, -20
    pts = [iso(x0, z - 4), iso(x1, z - 4), iso(x1, z + 4), iso(x0, z + 4)]
    draw.polygon(pts, fill=(180, 180, 190))
    draw.polygon(pts, outline=(120, 120, 130))
    for x in range(-90, 96, 15):
        a, b = iso(x, z - 4), iso(x, z + 4)
        draw.line([a, b], fill=(140, 140, 150), width=2)

def base_platform(draw, iso, x, z, color, label_text, s, lk=1.0):
    # top face with side depth, in studs; h in px
    w = 26
    corners = [iso(x - w/2, z - w/2), iso(x + w/2, z - w/2), iso(x + w/2, z + w/2), iso(x - w/2, z + w/2)]
    hpx = 2 * s
    top_pts = [(px, py - hpx) for px, py in corners]
    poly(draw, [corners[2], corners[3], top_pts[3], top_pts[2]], fill=shade(color, 0.8))
    poly(draw, [corners[1], corners[2], top_pts[2], top_pts[1]], fill=shade(color, 0.65))
    poly(draw, top_pts, fill=color)
    for dx, dz in ((-9, -6), (-3, -6), (3, -6), (9, -6), (-9, 6), (-3, 6), (3, 6), (9, 6)):
        px, py = iso(x + dx, z + dz, 2)
        r = 2 * 0.866 * s
        draw.polygon([(px - r, py), (px, py - r*0.6), (px + r, py), (px, py + r*0.6)], fill=(240, 240, 245))
    f = font(16 * lk)
    px, py = iso(x, z, 6)
    bb = draw.textbbox((0, 0), label_text, font=f)
    draw.text((px - (bb[2]-bb[0])/2, py - 8), label_text, font=f, fill=(255, 255, 255), stroke_width=4, stroke_fill=(20, 20, 30))

def tree(draw, iso, x, z, s=1.0):
    bx, by = iso(x, z)
    draw.rectangle([bx - 4*s, by - 55*s, bx + 4*s, by], fill=(120, 80, 40))
    draw.ellipse([bx - 26*s, by - 105*s, bx + 26*s, by - 45*s], fill=(60, 170, 70), outline=(30, 120, 40), width=2)

# ---------------- scenes ----------------

def scene_thumbnail():
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img, "RGBA")
    sky(draw)
    draw.ellipse([1050, 60, 1130, 140], fill=(255, 240, 140))
    for cx, cy, s in ((180, 90, 70), (420, 60, 50), (900, 110, 60)):
        draw.ellipse([cx, cy, cx + s, cy + s*0.45], fill=(255, 255, 255))
    water(draw)
    iso = make_iso(640, 455, 2.5)
    island_base(draw, iso)
    conveyor(draw, iso)
    bases = [(-72, -72, (255, 120, 120), "BASE 1"), (0, -72, (120, 180, 255), "BASE 2"),
             (72, -72, (120, 230, 140), "BASE 3"), (-72, 72, (255, 210, 90), "BASE 4"),
             (0, 72, (200, 130, 255), "BASE 5"), (72, 72, (255, 150, 210), "BASE 6")]
    for x, z, col, name in bases:
        base_platform(draw, iso, x, z, col, name, 2.5, lk=0.85)
    iso_box(draw, iso, -85, 30, 20, 16, 9, (255, 150, 210), (200, 100, 160))
    iso_box(draw, iso, 85, 30, 14, 14, 11, (160, 80, 255), (120, 60, 200))
    for x, z in ((-105, -60), (105, -60), (-105, 60), (105, 60), (-40, 50), (40, 50)):
        tree(draw, iso, x, z, 0.9)
    walkers = [
        (-75, (255, 220, 40), "Box", "wheels", "Banana Bus Barry", "Rare", (90, 170, 255), "$15/s"),
        (0, (90, 160, 255), "Ball", "crown", "Sir Puddles III", "Rare", (90, 170, 255), "$25/s"),
        (72, (80, 200, 80), "Cylinder", "antenna", "Quantum Pickle", "Legendary", (255, 205, 60), "$300/s"),
    ]
    for x, col, shape, acc, name, rar, rcol, rate in walkers:
        sx, sy = iso(x, -20, 2)
        draw_character(draw, sx, sy, 12, col, shape, acc, name, rar, rcol, rate, lk=0.8)
    px, py = iso(52, 14, 2)
    draw_player(draw, px, py, 11)
    cx, cy = iso(60, 20, 2)
    draw_character(draw, cx, cy, 10, (150, 160, 190), "Box", "none", "Soggy Sock Sam", "Common", (120, 220, 120), "$2/s", lk=0.8)
    f = font(64)
    title = "BRAINROT LAGOON"
    bb = draw.textbbox((0, 0), title, font=f)
    draw.text((640 - (bb[2]-bb[0])/2, 128), title, font=f, fill=(255, 210, 60), stroke_width=6, stroke_fill=(30, 20, 10))
    f2 = font(24)
    sub = "Catch the weirdos  •  Guard your base  •  Outrun the wave"
    bb = draw.textbbox((0, 0), sub, font=f2)
    draw.text((640 - (bb[2]-bb[0])/2, 200), sub, font=f2, fill=(255, 255, 255), stroke_width=3, stroke_fill=(20, 20, 30))
    hud(draw)
    toast(draw, "You bought Banana Bus Barry! Carry it home to your base!", y=655)
    tag(draw)
    return img

def scene_conveyor():
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img, "RGBA")
    sky(draw)
    draw.ellipse([1060, 60, 1130, 130], fill=(255, 240, 140))
    water(draw)
    iso = make_iso(640, 470, 3.4)
    island_base(draw, iso)
    conveyor(draw, iso)
    iso_box(draw, iso, -102, -20, 14, 14, 2, (150, 110, 70), (110, 80, 50))
    walkers = [
        (-72, (150, 160, 190), "Box", "none", "Soggy Sock Sam", "Common", (120, 220, 120), "$2/s", None),
        (-44, (255, 220, 40), "Box", "wheels", "Banana Bus Barry", "Rare", (90, 170, 255), "$15/s", None),
        (-10, (220, 235, 255), "Box", "antenna", "DJ Fridge", "Rare", (90, 170, 255), "$40/s", None),
        (26, (230, 170, 60), "Cylinder", "hat", "Captain Crunchwrap", "Epic", (190, 110, 255), "$80/s", "Golden"),
        (62, (255, 170, 60), "Ball", "hat", "El Gato WiFi", "Legendary", (255, 205, 60), "$500/s", None),
    ]
    for x, col, shape, acc, name, rar, rcol, rate, mut in walkers:
        sx, sy = iso(x, -20, 2)
        draw_character(draw, sx, sy, 19, col, shape, acc, name, rar, rcol, rate, mut, lk=0.9)
    px, py = iso(-44, -20, 2)
    draw.rounded_rectangle([px - 130, py - 215, px + 130, py - 145], radius=10, fill=(20, 20, 30))
    f = font(22)
    bb = draw.textbbox((0, 0), "Buy — $400", font=f)
    draw.text((px - (bb[2]-bb[0])/2, py - 207), "Buy — $400", font=f, fill=(255, 230, 120))
    f = font(15)
    bb = draw.textbbox((0, 0), "hold E near the weirdo", font=f)
    draw.text((px - (bb[2]-bb[0])/2, py - 172), "hold E near the weirdo", font=f, fill=(255, 255, 255))
    px2, py2 = iso(-26, 6, 2)
    draw_player(draw, px2, py2, 15)
    hud(draw, cash="$375", income="+$12/s", rebirth="Rebirth 0", wave="Noodle Tsunami in 58s")
    toast(draw, "Golden Captain Crunchwrap on the conveyor: $240/s!")
    tag(draw)
    return img

def scene_base():
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img, "RGBA")
    sky(draw)
    draw.rectangle([0, 470, W, H], fill=(38, 110, 210))
    iso = make_iso(640, 490, 24)
    # the base fills the frame: platform, slot pads, title plate
    base_platform(draw, iso, 0, 0, (255, 120, 120), "BASE 1 — yours", 24, lk=1.0)
    placed = [
        (-9, -6, (150, 160, 190), "Box", "none", "Soggy Sock Sam", "Common", (120, 220, 120), "$2/s", None),
        (9, -6, (255, 220, 40), "Box", "wheels", "Banana Bus Barry", "Rare", (90, 170, 255), "$15/s", None),
        (-9, 6, (90, 160, 255), "Ball", "crown", "Sir Puddles III", "Rare", (90, 170, 255), "$25/s", None),
        (9, 6, (80, 200, 80), "Cylinder", "antenna", "Quantum Pickle", "Legendary", (255, 205, 60), "$300/s", None),
    ]
    for dx, dz, col, shape, acc, name, rar, rcol, rate, mut in placed:
        sx, sy = iso(dx, dz, 2)
        draw_character(draw, sx, sy, 21, col, shape, acc, name, rar, rcol, rate, mut, lk=0.75)
    px, py = iso(0, 13, 2)
    draw_player(draw, px, py, 18)
    hud(draw, cash="$1,240", income="+$342/s", rebirth="Rebirth 1", wave="Noodle Tsunami in 42s")
    toast(draw, "Quantum Pickle is on your base earning $300/s!", y=655)
    tag(draw)
    return img

def scene_tsunami():
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img, "RGBA")
    sky(draw)
    draw.ellipse([1050, 60, 1130, 140], fill=(255, 240, 140))
    water(draw)
    iso = make_iso(640, 440, 2.3)
    island_base(draw, iso)
    conveyor(draw, iso)
    bases = [(-72, -72, (255, 120, 120), "BASE 1"), (0, -72, (120, 180, 255), "BASE 2"),
             (72, -72, (120, 230, 140), "BASE 3"), (-72, 72, (255, 210, 90), "BASE 4"),
             (0, 72, (200, 130, 255), "BASE 5"), (72, 72, (255, 150, 210), "BASE 6")]
    for x, z, col, name in bases:
        base_platform(draw, iso, x, z, col, name, 2.3, lk=0.8)
    # the wave wall at z=-80, drawn with vertical sides so it reads as a wall
    z = -80
    wall_h = 26 * 2.3
    bl = iso(-110, z, 2)
    br = iso(110, z, 2)
    wall = [bl, br, (br[0], br[1] - wall_h), (bl[0], bl[1] - wall_h)]
    draw.polygon(wall, fill=(255, 90, 160))
    draw.polygon(wall, outline=(200, 40, 120))
    for t in range(0, 22):
        x = -110 + t * 10.5
        cx, cy = iso(x, z, 2)
        draw.ellipse([cx - 11, cy - wall_h - 12, cx + 11, cy - wall_h + 8], fill=(255, 255, 255))
    # a weirdo still out on the conveyor, and a player dashing home with one
    sx, sy = iso(-40, -20, 2)
    draw_character(draw, sx, sy, 12, (255, 220, 40), "Box", "wheels", "Banana Bus Barry", "Rare", (90, 170, 255), "$15/s", lk=0.8)
    px, py = iso(2, 14, 2)
    draw_player(draw, px, py, 12, name="")
    cx, cy = iso(26, 44, 2)
    draw_character(draw, cx, cy, 12, (90, 160, 255), "Ball", "crown", "Sir Puddles III", "Rare", (90, 170, 255), "$25/s", lk=0.8)
    hud(draw, cash="$2,480", income="+$96/s", rebirth="Rebirth 1",
        wave="NOODLE TSUNAMI IN 3s — RUN HOME!", wave_color=(255, 255, 255), wave_bg=(200, 40, 40))
    toast(draw, "The Noodle Tsunami got you! Dash home next time!", y=655)
    tag(draw)
    return img

scenes = [
    ("1-thumbnail.jpg", scene_thumbnail),
    ("2-conveyor.jpg", scene_conveyor),
    ("3-base.jpg", scene_base),
    ("4-tsunami.jpg", scene_tsunami),
]
for name, fn in scenes:
    img = fn()
    img.save(f"{OUT}/{name}", "JPEG", quality=82)
    print(name, os.path.getsize(f"{OUT}/{name}"), "bytes", img.size)
