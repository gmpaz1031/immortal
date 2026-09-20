from PIL import Image

im = Image.open("scratch/top_left_ribbon.png")
w, h = im.size
# Find pixels that are bright blue (the triangle is #0078d4 or similar #1e88e5)
tri_pixels = []
for y in range(40, 80):
    for x in range(100, 150):
        r, g, b = im.getpixel((x, y))[:3]
        if b > 200 and r < 50:
            tri_pixels.append((x, y))

if tri_pixels:
    min_x = min(p[0] for p in tri_pixels)
    max_x = max(p[0] for p in tri_pixels)
    min_y = min(p[1] for p in tri_pixels)
    max_y = max(p[1] for p in tri_pixels)
    print(f"Triangle only: Bounds: ({min_x}, {min_y}) to ({max_x}, {max_y}), Center: ({(min_x+max_x)//2}, {(min_y+max_y)//2})")
