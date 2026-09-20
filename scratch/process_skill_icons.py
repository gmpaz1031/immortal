import os
import sys
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np
from collections import deque

SKILLS = [
    {
        "name": "Sword Slash",
        "display": "Xianxia_Skill_SwordSlash_V2",
        "src": r"C:\Users\PAZ GC\.gemini\antigravity\brain\d74e1133-04fa-404e-97c8-84b51aaf915b\xianxia_sword_slash_1789808825887.jpg",
        "out": "skill_sword_slash.png"
    },
    {
        "name": "Flame Ball",
        "display": "Xianxia_Skill_FlameBall_V2",
        "src": r"C:\Users\PAZ GC\.gemini\antigravity\brain\d74e1133-04fa-404e-97c8-84b51aaf915b\xianxia_flame_ball_1789808841621.jpg",
        "out": "skill_flame_ball.png"
    },
    {
        "name": "Palm Art",
        "display": "Xianxia_Skill_PalmArt_V2",
        "src": r"C:\Users\PAZ GC\.gemini\antigravity\brain\d74e1133-04fa-404e-97c8-84b51aaf915b\xianxia_palm_art_1789808862394.jpg",
        "out": "skill_palm_art.png"
    },
    {
        "name": "Thunder Strike",
        "display": "Xianxia_Skill_ThunderStrike_V2",
        "src": r"C:\Users\PAZ GC\.gemini\antigravity\brain\d74e1133-04fa-404e-97c8-84b51aaf915b\xianxia_thunder_strike_1789808915068.jpg",
        "out": "skill_thunder_strike.png"
    },
    {
        "name": "Multiple Swords",
        "display": "Xianxia_Skill_MultipleSwords_V2",
        "src": r"C:\Users\PAZ GC\.gemini\antigravity\brain\d74e1133-04fa-404e-97c8-84b51aaf915b\xianxia_multiple_swords_1789808933642.jpg",
        "out": "skill_multiple_swords.png"
    },
    {
        "name": "Flame Spear",
        "display": "Xianxia_Skill_FlameSpear_V2",
        "src": r"C:\Users\PAZ GC\.gemini\antigravity\brain\d74e1133-04fa-404e-97c8-84b51aaf915b\xianxia_flame_spear_1789808952291.jpg",
        "out": "skill_flame_spear.png"
    },
]

def remove_white_background(src_path: Path, dest_path: Path):
    im = Image.open(src_path).convert("RGBA")
    arr = np.array(im, dtype=np.float32)
    H, W, _ = arr.shape

    # Calculate distance from pure white (255, 255, 255)
    # Brightness / Whiteness
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    min_rgb = np.minimum(np.minimum(r, g), b)
    
    # Background candidate: very close to pure white
    is_bg_seed = (r > 240) & (g > 240) & (b > 240)

    # Seed flood fill from borders to identify outer background
    border_mask = np.zeros((H, W), dtype=bool)
    q = deque()

    for x in range(W):
        if is_bg_seed[0, x]:
            border_mask[0, x] = True
            q.append((0, x))
        if is_bg_seed[H-1, x]:
            border_mask[H-1, x] = True
            q.append((H-1, x))

    for y in range(H):
        if is_bg_seed[y, 0]:
            border_mask[y, 0] = True
            q.append((y, 0))
        if is_bg_seed[y, W-1]:
            border_mask[y, W-1] = True
            q.append((y, W-1))

    # Flood fill all connected near-white pixels from outer borders
    while q:
        cy, cx = q.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W and not border_mask[ny, nx] and is_bg_seed[ny, nx]:
                border_mask[ny, nx] = True
                q.append((ny, nx))

    # For border_mask pixels, alpha is 0
    # For transition pixels adjacent to border_mask where min_rgb > 210, apply smooth roll-off
    alpha = np.ones((H, W), dtype=np.float32) * 255.0
    alpha[border_mask] = 0.0

    # Smooth defringing near boundary
    # If pixel is near border_mask and is light, attenuate alpha
    for y in range(H):
        for x in range(W):
            if alpha[y, x] > 0 and min_rgb[y, x] > 215:
                # Check if neighboring a transparent pixel
                is_near_bg = False
                for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]:
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < H and 0 <= nx < W and border_mask[ny, nx]:
                        is_near_bg = True
                        break
                if is_near_bg:
                    # Transition factor: 255 is 0 alpha, 215 is full alpha
                    factor = (255.0 - min_rgb[y, x]) / (255.0 - 215.0)
                    alpha[y, x] = np.clip(factor * 255.0, 0.0, 255.0)

    # Reconstruct cleaned array
    cleaned = arr.copy()
    cleaned[:, :, 3] = alpha

    # Find bounding box of non-zero alpha
    non_zero = np.argwhere(alpha > 15)
    if len(non_zero) == 0:
        print(f"Warning: Empty image for {src_path}")
        return

    min_y, min_x = non_zero.min(axis=0)
    max_y, max_x = non_zero.max(axis=0)

    pad = 20
    min_y = max(0, min_y - pad)
    max_y = min(H - 1, max_y + pad)
    min_x = max(0, min_x - pad)
    max_x = min(W - 1, max_x + pad)

    cropped = cleaned[min_y:max_y+1, min_x:max_x+1]
    cH, cW, _ = cropped.shape
    dim = max(cH, cW)
    square = np.zeros((dim, dim, 4), dtype=np.uint8)
    off_y = (dim - cH) // 2
    off_x = (dim - cW) // 2
    square[off_y:off_y+cH, off_x:off_x+cW] = cropped.astype(np.uint8)

    final_img = Image.fromarray(square, "RGBA").resize((512, 512), Image.Resampling.LANCZOS)
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    final_img.save(dest_path, format="PNG")
    print(f"Processed: {dest_path.name} (from {src_path.name})")

def main():
    icons_dir = Path(r"c:\GMGAME\immortal\assets\icons")
    for s in SKILLS:
        src = Path(s["src"])
        dest = icons_dir / s["out"]
        remove_white_background(src, dest)

if __name__ == "__main__":
    main()
