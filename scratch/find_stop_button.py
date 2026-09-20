from PIL import Image

im = Image.open("scratch/studio_now.png")
# Crop top-left region: x=0..250, y=0..100
crop = im.crop((0, 0, 250, 100))
crop.save("scratch/crop_stop.png")

# Find bright red pixels of the stop button
w, h = crop.size
red_pixels = []
for y in range(40, 80):
    for x in range(120, 220):
        r, g, b = crop.getpixel((x, y))[:3]
        if r > 180 and g < 60 and b < 60:
            red_pixels.append((x, y))

if red_pixels:
    min_x = min(p[0] for p in red_pixels)
    max_x = max(p[0] for p in red_pixels)
    min_y = min(p[1] for p in red_pixels)
    max_y = max(p[1] for p in red_pixels)
    print(f"Stop button (red square) found! Bounds: ({min_x}, {min_y}) to ({max_x}, {max_y}), Center: ({(min_x+max_x)//2}, {(min_y+max_y)//2})")
else:
    print("No red square found")
