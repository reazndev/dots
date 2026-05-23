#!/usr/bin/env python3
import os
import re
from PIL import Image, ImageDraw, ImageFont

def generate_logo():
    # Paths
    ghostty_theme_path = os.path.expanduser("~/.config/ghostty/themes/wallust")
    logo_txt_path = os.path.expanduser("~/.config/fastfetch/logo.txt")
    output_png_path = os.path.expanduser("~/.config/fastfetch/logo.png")

    # Fallback colors
    color6 = "#D29188"

    # Extract color 6 from Wallust Ghostty theme
    if os.path.exists(ghostty_theme_path):
        try:
            with open(ghostty_theme_path, "r") as f:
                content = f.read()
                # Find color6 in the palette lines: palette = 6=#D29188
                match = re.search(r"palette\s*=\s*6\s*=\s*(#[0-9a-fA-F]+)", content)
                if match:
                    color6 = match.group(1)
                else:
                    # Also try palette = 14 or foreground
                    match_fg = re.search(r"foreground\s*=\s*(#[0-9a-fA-F]+)", content)
                    if match_fg:
                        color6 = match_fg.group(1)
        except Exception as e:
            print(f"Error reading Ghostty theme colors: {e}")

    if not os.path.exists(logo_txt_path):
        print(f"Logo source text file not found at {logo_txt_path}")
        return

    with open(logo_txt_path, "r") as f:
        lines = [line.rstrip("\r\n") for line in f.readlines()]

    if not lines:
        print("Logo text file is empty")
        return

    # Use a high-quality monospaced font
    font_path = "/usr/share/fonts/TTF/DejaVuSansMono.ttf"
    if not os.path.exists(font_path):
        # Fallbacks
        font_paths = [
            "/usr/share/fonts/liberation/LiberationMono-Bold.ttf",
            "/usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf",
            "/usr/share/fonts/TTF/FantasqueSansMNerdFontMono-Bold.ttf"
        ]
        for path in font_paths:
            if os.path.exists(path):
                font_path = path
                break

    # We use a large font size to make the final logo look extremely crisp and detailed when scaled down
    font_size = 40
    try:
        font = ImageFont.truetype(font_path, font_size)
    except Exception as e:
        print(f"Error loading font {font_path}: {e}. Using default font.")
        font = ImageFont.load_default()

    # Calculate exact character dimensions using textbbox
    dummy_img = Image.new("RGBA", (100, 100))
    dummy_draw = ImageDraw.Draw(dummy_img)
    bbox = dummy_draw.textbbox((0, 0), "A", font=font)
    char_width = bbox[2] - bbox[0]
    # For line height, let's use the font spacing
    char_height = font_size + 4

    max_len = max(len(line) for line in lines)
    num_lines = len(lines)

    # Create canvas with safety margin
    margin = 50
    img_width = max_len * char_width + 2 * margin
    img_height = num_lines * char_height + 2 * margin

    img = Image.new("RGBA", (img_width, img_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    y = margin
    for line in lines:
        x = margin
        for char in line:
            if char != " ":
                draw.text((x, y), char, fill=color6, font=font)
            x += char_width
        y += char_height

    # Crop to transparent bounding box to eliminate all unnecessary empty space
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # Save to PNG
    img.save(output_png_path, "PNG")
    print(f"Successfully generated transparent logo PNG at {output_png_path} using color {color6}")

if __name__ == "__main__":
    generate_logo()
