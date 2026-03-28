"""Generate a professional Family Safety app icon (1024x1024).

Design: Modern shield with heart + family silhouettes.
Colors: Indigo-to-teal gradient, white shield, purple accents.
"""
from PIL import Image, ImageDraw
import math, os

SIZE = 1024
HALF = SIZE // 2

def lerp(a, b, t):
    return a + (b - a) * t

def gradient_bg(size):
    img = Image.new('RGBA', (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / size
        r = int(lerp(90, 0, t))
        g = int(lerp(70, 185, t))
        b = int(lerp(225, 155, t))
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    return img

def shield_polygon(cx, cy, w, h):
    """Symmetric shield: rounded-top rectangle tapering to a point at bottom."""
    pts = []
    top = cy - h
    bot_point = cy + h * 0.75
    waist_y = cy + h * 0.2
    corner_r = w * 0.3

    # Top-left corner arc (180° to 270°)
    for i in range(30):
        a = math.pi + i / 29 * (math.pi / 2)
        pts.append((cx - w + corner_r + corner_r * math.cos(a),
                     top + corner_r + corner_r * math.sin(a)))
    # Top-right corner arc (270° to 360°)
    for i in range(30):
        a = 3 * math.pi / 2 + i / 29 * (math.pi / 2)
        pts.append((cx + w - corner_r + corner_r * math.cos(a),
                     top + corner_r + corner_r * math.sin(a)))
    # Right side down to waist
    pts.append((cx + w, waist_y))
    # Right taper to bottom point
    pts.append((cx, bot_point))
    # Left taper from bottom point
    pts.append((cx - w, waist_y))

    return pts

def heart_polygon(cx, cy, size, steps=250):
    pts = []
    for i in range(steps):
        t = i / steps * 2 * math.pi
        x = size * 16 * math.sin(t) ** 3
        y = -size * (13 * math.cos(t) - 5 * math.cos(2 * t) -
                     2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x / 16, cy + y / 16))
    return pts

def draw_person(draw, px, py, scale=1.0, color=(108, 99, 255)):
    hr = int(20 * scale)
    draw.ellipse([px - hr, py - hr, px + hr, py + hr], fill=color)
    bw, bh = int(18 * scale), int(38 * scale)
    draw.rounded_rectangle(
        [px - bw, py + hr + 3, px + bw, py + hr + 3 + bh],
        radius=int(9 * scale), fill=color)

# ===== BUILD ICON =====
os.makedirs('assets/icon', exist_ok=True)
img = gradient_bg(SIZE)

# Rounded rect mask
mask = Image.new('L', (SIZE, SIZE), 0)
ImageDraw.Draw(mask).rounded_rectangle(
    [(0, 0), (SIZE - 1, SIZE - 1)], radius=int(SIZE * 0.22), fill=255)
img.putalpha(mask)
draw = ImageDraw.Draw(img)

# Shield
cx, cy = HALF, HALF - 15
shield = shield_polygon(cx, cy, 285, 330)

# Drop shadow
shadow = [(p[0] + 6, p[1] + 8) for p in shield]
draw.polygon(shadow, fill=(0, 0, 0, 45))
draw.polygon(shield, fill=(255, 255, 255, 245))

# Heart (upper portion of shield)
heart = heart_polygon(cx, cy - 50, 105)
draw.polygon(heart, fill=(108, 99, 255))

# Location dot in heart
dot_r = 18
draw.ellipse([cx - dot_r, cy - 96 - dot_r, cx + dot_r, cy - 96 + dot_r],
             fill=(255, 255, 255, 235))

# Family figures (lower shield)
fy = cy + 130
draw_person(draw, cx - 65, fy, scale=0.95, color=(108, 99, 255))
draw_person(draw, cx, fy + 15, scale=0.68, color=(140, 130, 255))
draw_person(draw, cx + 65, fy, scale=0.95, color=(108, 99, 255))

img.save('assets/icon/app_icon.png', 'PNG')

# ===== ADAPTIVE FOREGROUND =====
fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
fd = ImageDraw.Draw(fg)
fd.polygon(shield, fill=(255, 255, 255, 245))
fd.polygon(heart, fill=(108, 99, 255))
fd.ellipse([cx - dot_r, cy - 96 - dot_r, cx + dot_r, cy - 96 + dot_r],
           fill=(255, 255, 255, 235))
draw_person(fd, cx - 65, fy, scale=0.95, color=(108, 99, 255))
draw_person(fd, cx, fy + 15, scale=0.68, color=(140, 130, 255))
draw_person(fd, cx + 65, fy, scale=0.95, color=(108, 99, 255))
fg.save('assets/icon/app_icon_foreground.png', 'PNG')

print("Done: app_icon.png + app_icon_foreground.png (1024x1024)")
