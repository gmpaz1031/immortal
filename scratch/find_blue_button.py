from PIL import Image

im = Image.open("scratch/top_left_ribbon.png")
w, h = im.size
blue_pixels = []
for y in range(h):
    for x in range(w):
        r, g, b = im.getpixel((x, y))[:3]
        # The play button is vivid blue (b >> r and b >> g)
        if b > 180 and r < 100 and g < 150:
            blue_pixels.append((x, y))

if blue_pixels:
    min_x = min(p[0] for p in blue_pixels)
    max_x = max(p[0] for p in blue_pixels)
    min_y = min(p[1] for p in blue_pixels)
    max_y = max(p[1] for p in blue_pixels)
    cx = (min_x + max_x) // 2
    cy = (min_y + max_y) // 2
    print(f"Blue triangle found! Bounds: ({min_x}, {min_y}) to ({max_x}, {max_y}), Center: ({cx}, {cy})")
else:
    print("No blue pixels found")
