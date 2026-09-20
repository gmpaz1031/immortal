from PIL import Image

im = Image.open("scratch/overlay_test.png")
# Crop top-left region: x=0..200, y=0..120
crop = im.crop((0, 0, 200, 120))
crop.save("scratch/top_left_ribbon.png")
print("Saved top_left_ribbon.png, dimensions:", crop.size)
