"""Generate a professional Family Safety app icon (1024x1024).
Design v5: Vibrant gradient bg, white location-pin with heart + family.
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
        for x in range(size):
            t = (x / size * 0.35 + y / size * 0.65)
            r = int(lerp(76, 0, t))
            g = int(lerp(40, 195, t))
            b_val = int(lerp(220, 145, t))
            draw.point((x, y), fill=(r, g, b_val, 255))
    return img

def pin_shape(cx, cy, w, h):
    """Location pin: circle-ish top + pointed bottom."""
    pts = []
    # Top dome (semicircle)
    dome_cy = cy - h * 0.15
    dome_r = w * 0.50
    for i in range(60):
        a = math.pi + i / 59 * math.pi
        pts.append((cx + dome_r * math.cos(a), dome_cy + dome_r * math.sin(a)))
    # Right side curves down to point
    for i in range(30):
        t = i / 29
        rx = cx + dome_r * (1 - t) * math.cos(-0.1)
        ry = dome_cy + dome_r * t * 1.1
        pts.append((cx + dome_r * (1 - t * 1.05), dome_cy + t * h * 0.62))
    # Bottom point
    pts.append((cx, cy + h * 0.50))
    # Left side curves back up
    for i in range(30):
        t = (29 - i) / 29
        pts.append((cx - dome_r * (1 - t * 1.05), dome_cy + t * h * 0.62))
    return pts

def draw_heart(draw, cx, cy, sz, color):
    pts = []
    for i in range(300):
        t = i / 300 * 2 * math.pi
        x = sz * 16 * math.sin(t) ** 3
        y = -sz * (13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))
        pts.append((cx + x / 16, cy + y / 16))
    draw.polygon(pts, fill=color)

def draw_person(draw, cx, cy, hr, bw, bh, color):
    draw.ellipse([cx-hr, cy-hr, cx+hr, cy+hr], fill=color)
    draw.rounded_rectangle([cx-bw, cy+hr+3, cx+bw, cy+hr+3+bh], radius=bw//2, fill=color)

os.makedirs('assets/icon', exist_ok=True)
img = gradient_bg(SIZE)
mask = Image.new('L', (SIZE, SIZE), 0)
ImageDraw.Draw(mask).rounded_rectangle([(0,0),(SIZE-1,SIZE-1)], radius=int(SIZE*0.22), fill=255)
img.putalpha(mask)
draw = ImageDraw.Draw(img)

# Central pin
pcx, pcy = HALF, HALF + 20
pw, ph = 500, 660
pin = pin_shape(pcx, pcy, pw, ph)
# Shadow
shadow = [(p[0]+6, p[1]+10) for p in pin]
draw.polygon(shadow, fill=(0, 0, 0, 40))
draw.polygon(pin, fill=(255, 255, 255, 245))

# Inner circle highlight (subtle)
inner_cy = pcy - ph * 0.15
inner_r = pw * 0.35
draw.ellipse([pcx - inner_r, inner_cy - inner_r, pcx + inner_r, inner_cy + inner_r],
             fill=(245, 245, 255, 60))

# Heart in upper area
hcy = pcy - ph * 0.18
draw_heart(draw, pcx, hcy, 80, (108, 95, 230))

# White dot in heart
dr = 13
draw.ellipse([pcx-dr, hcy-32-dr, pcx+dr, hcy-32+dr], fill=(255,255,255,230))

# Family figures in lower area
fy = pcy + ph * 0.06
fc = (108, 95, 230)
fc2 = (145, 135, 240)
draw_person(draw, pcx - 68, fy, 20, 17, 36, fc)
draw_person(draw, pcx, fy + 12, 15, 13, 28, fc2)
draw_person(draw, pcx + 68, fy, 20, 17, 36, fc)

img.save('assets/icon/app_icon.png')
print('OK app_icon.png')

# Foreground for adaptive icon
fg = Image.new('RGBA', (SIZE, SIZE), (0,0,0,0))
fd = ImageDraw.Draw(fg)
pin2 = pin_shape(HALF, HALF+20, pw, ph)
fd.polygon(pin2, fill=(255,255,255,245))
fd.ellipse([HALF-inner_r, inner_cy-inner_r, HALF+inner_r, inner_cy+inner_r], fill=(245,245,255,60))
draw_heart(fd, HALF, hcy, 80, (108,95,230))
fd.ellipse([HALF-dr, hcy-32-dr, HALF+dr, hcy-32+dr], fill=(255,255,255,230))
draw_person(fd, HALF-68, fy, 20, 17, 36, fc)
draw_person(fd, HALF, fy+12, 15, 13, 28, fc2)
draw_person(fd, HALF+68, fy, 20, 17, 36, fc)
fg.save('assets/icon/app_icon_foreground.png')
print('OK foreground.png')
