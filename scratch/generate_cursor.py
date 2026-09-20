"""
scratch/generate_cursor.py
Generates a crisp, stylized game cursor with golden/cyan Xianxia accents,
black comic outline, and transparent background.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

# Supersample 4x for extreme anti-aliasing
SCALE = 4
SIZE = 512 * SCALE

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Cursor polygon coordinates (classic angled game pointer)
# Tip is at (80, 80)
pts = [
    (100 * SCALE, 100 * SCALE),   # Tip
    (100 * SCALE, 420 * SCALE),   # Left edge down
    (180 * SCALE, 340 * SCALE),   # Inner corner
    (260 * SCALE, 480 * SCALE),   # Tail tip right
    (315 * SCALE, 450 * SCALE),   # Tail outer
    (235 * SCALE, 310 * SCALE),   # Tail inner
    (360 * SCALE, 310 * SCALE),   # Right wing
]

# 1. Glow layer
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
glow_draw.polygon(pts, fill=(255, 215, 0, 160)) # Golden glow
glow = glow.filter(ImageFilter.GaussianBlur(16 * SCALE))
img.paste(glow, (0, 0), glow)

# 2. Outer Black Outline
for dx in range(-8 * SCALE, 9 * SCALE, 2 * SCALE):
    for dy in range(-8 * SCALE, 9 * SCALE, 2 * SCALE):
        if dx*dx + dy*dy <= (8 * SCALE)**2:
            offset_pts = [(x + dx, y + dy) for x, y in pts]
            draw.polygon(offset_pts, fill=(18, 22, 28, 255))

# 3. Gold Accent Border
for dx in range(-3 * SCALE, 4 * SCALE, SCALE):
    for dy in range(-3 * SCALE, 4 * SCALE, SCALE):
        if dx*dx + dy*dy <= (3 * SCALE)**2:
            offset_pts = [(x + dx, y + dy) for x, y in pts]
            draw.polygon(offset_pts, fill=(245, 195, 65, 255))

# 4. Pure Pearl White Body
draw.polygon(pts, fill=(255, 255, 255, 255))

# 5. Inner subtle gradient / cyan core line
inner_pts = [
    (115 * SCALE, 125 * SCALE),
    (115 * SCALE, 390 * SCALE),
    (180 * SCALE, 325 * SCALE),
    (260 * SCALE, 460 * SCALE),
    (290 * SCALE, 440 * SCALE),
    (220 * SCALE, 300 * SCALE),
    (335 * SCALE, 300 * SCALE),
]
draw.polygon(inner_pts, fill=(235, 248, 255, 255))

# Downsample with Lanczos for smooth subpixel edges
final_img = img.resize((512, 512), Image.Resampling.LANCZOS)

out_dir = Path("assets/icons")
out_dir.mkdir(parents=True, exist_ok=True)
out_path = out_dir / "ai_cursor.png"
final_img.save(out_path, "PNG")
print(f"[OK] Saved cursor to {out_path}")
