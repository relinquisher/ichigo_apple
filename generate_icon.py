from PIL import Image, ImageDraw
import math

SIZE = 1024
SCALE = SIZE / 108.0

img = Image.new('RGBA', (SIZE, SIZE), (255, 248, 225, 255))  # cream background
draw = ImageDraw.Draw(img)


def scaled(x, y):
    return (x * SCALE, y * SCALE)


# Strawberry body - smooth egg/strawberry shape
strawberry_color = (233, 30, 99, 255)  # #E91E63
cx, cy = 54, 56  # center
points = []
for deg in range(360):
    rad = math.radians(deg)
    # Narrower at top, wider at middle, pointed at bottom
    t = rad
    # Base ellipse
    base_rx = 26
    base_ry = 28
    # Make top narrower
    if math.sin(t) < 0:  # top half
        factor = 0.7 + 0.3 * (1 + math.sin(t))
    else:
        factor = 1.0
    x = cx + base_rx * factor * math.cos(t)
    y = cy + base_ry * math.sin(t)
    points.append(scaled(x, y))

draw.polygon(points, fill=strawberry_color)

# Leaves
leaf_color = (76, 175, 80, 255)  # #4CAF50

# Left leaf - larger
left_leaf = [
    scaled(54, 29),
    scaled(46, 18),
    scaled(40, 20),
    scaled(47, 25),
    scaled(51, 29),
]
draw.polygon(left_leaf, fill=leaf_color)

# Right leaf - larger
right_leaf = [
    scaled(54, 29),
    scaled(62, 18),
    scaled(68, 20),
    scaled(61, 25),
    scaled(57, 29),
]
draw.polygon(right_leaf, fill=leaf_color)

# Small stem
draw.rectangle([scaled(53, 23)[0], scaled(53, 23)[1], scaled(55, 29)[0], scaled(55, 29)[1]], fill=leaf_color)

# Seeds (white dots)
seed_color = (255, 255, 255, 255)
seed_positions = [(44, 48), (54, 43), (64, 48), (48, 58), (60, 58), (54, 68), (42, 64), (66, 64)]
seed_rx = 2.0 * SCALE
seed_ry = 2.8 * SCALE

for sx, sy in seed_positions:
    x, y = sx * SCALE, sy * SCALE
    draw.ellipse([x - seed_rx, y - seed_ry, x + seed_rx, y + seed_ry], fill=seed_color)

# Save
output_path = r'C:\Users\Y\Documents\ichigo_apple\Ichigo\Resources\AppIcon.png'
img.save(output_path, 'PNG')
print(f'Icon saved to {output_path}')
