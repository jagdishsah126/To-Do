import os
from PIL import Image, ImageDraw

ICONS_DIR = "/home/jagdish/Desktop/Sandbox/Zara/To_Do/zara-todo/public/icons"
os.makedirs(ICONS_DIR, exist_ok=True)

def create_app_icon(size, maskable=False):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background
    if maskable:
        # Full bleed square for maskable
        draw.rectangle([0, 0, size, size], fill=(15, 15, 20, 255))
        padding = size * 0.2
    else:
        # Rounded squircle
        radius = size * 0.22
        draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=(15, 15, 22, 255))
        # subtle border
        draw.rounded_rectangle([0, 0, size, size], radius=radius, outline=(99, 102, 241, 160), width=max(2, int(size * 0.015)))
        padding = size * 0.15

    # Inner checkmark / Z symbol in vibrant Indigo/Violet gradient
    cx, cy = size / 2, size / 2
    # Draw stylised checkmark badge
    badge_radius = (size - 2 * padding) / 2
    draw.ellipse([cx - badge_radius, cy - badge_radius, cx + badge_radius, cy + badge_radius], fill=(99, 102, 241, 240))
    
    # Draw checkmark inside
    w = max(3, int(size * 0.065))
    p1 = (cx - badge_radius * 0.45, cy + badge_radius * 0.05)
    p2 = (cx - badge_radius * 0.05, cy + badge_radius * 0.45)
    p3 = (cx + badge_radius * 0.5, cy - badge_radius * 0.35)
    
    draw.line([p1, p2, p3], fill=(255, 255, 255, 255), width=w, joint="curve")
    return img

def create_badge(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([2, 2, size - 2, size - 2], fill=(99, 102, 241, 255))
    w = max(2, int(size * 0.08))
    cx, cy = size / 2, size / 2
    draw.line([(cx - size * 0.2, cy + size * 0.05), (cx - size * 0.02, cy + size * 0.22), (cx + size * 0.25, cy - size * 0.18)], fill=(255, 255, 255, 255), width=w)
    return img

def create_shortcut_icon(size, icon_type="add"):
    img = Image.new("RGBA", (size, size), (15, 15, 22, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    draw.ellipse([6, 6, size - 6, size - 6], fill=(30, 32, 48, 255))
    
    if icon_type == "add":
        # Plus sign
        w = max(3, int(size * 0.08))
        arm = size * 0.22
        draw.line([(cx - arm, cy), (cx + arm, cy)], fill=(99, 102, 241, 255), width=w)
        draw.line([(cx, cy - arm), (cx, cy + arm)], fill=(99, 102, 241, 255), width=w)
    else:
        # Calendar/Today icon
        box_w = size * 0.26
        draw.rectangle([cx - box_w, cy - box_w, cx + box_w, cy + box_w], outline=(99, 102, 241, 255), width=3)
        draw.line([cx - box_w, cy - box_w * 0.3, cx + box_w, cy - box_w * 0.3], fill=(99, 102, 241, 255), width=2)
        # Dot for today
        draw.ellipse([cx - 4, cy + 2, cx + 4, cy + 10], fill=(255, 255, 255, 255))
    return img

# Generate all icons
create_app_icon(192).save(os.path.join(ICONS_DIR, "icon-192.png"))
create_app_icon(512).save(os.path.join(ICONS_DIR, "icon-512.png"))
create_app_icon(512, maskable=True).save(os.path.join(ICONS_DIR, "icon-512-maskable.png"))
create_badge(72).save(os.path.join(ICONS_DIR, "badge-72.png"))
create_shortcut_icon(96, "add").save(os.path.join(ICONS_DIR, "shortcut-add.png"))
create_shortcut_icon(96, "today").save(os.path.join(ICONS_DIR, "shortcut-today.png"))

print("All icons successfully generated in public/icons!")
