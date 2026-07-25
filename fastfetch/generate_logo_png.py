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
                match = re.search(r"palette\s*=\s*6\s*=\s*(#[0-9a-fA-F]+)", content)
                if match:
                    color6 = match.group(1)
                else:
                    match_fg = re.search(r"foreground\s*=\s*(#[0-9a-fA-F]+)", content)
                    if match_fg:
                        color6 = match_fg.group(1)
        except Exception as e:
            print(f"Error reading Ghostty theme colors: {e}")

    if not os.path.exists(logo_txt_path):
        print(f"Logo source text file not found at {logo_txt_path}")
        return

    with open(logo_txt_path, "r") as f:
        logo_text = f.read()

    if not logo_text.strip():
        print("Logo text file is empty")
        return

    # Use a high-quality monospaced font
    font_path = "/usr/share/fonts/TTF/DejaVuSansMono.ttf"
    if not os.path.exists(font_path):
        font_paths = [
            "/usr/share/fonts/liberation/LiberationMono-Bold.ttf",
            "/usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf"
        ]
        for path in font_paths:
            if os.path.exists(path):
                font_path = path
                break

    font_size = 40
    try:
        font = ImageFont.truetype(font_path, font_size)
    except Exception as e:
        print(f"Error loading font {font_path}: {e}. Using default font.")
        font = ImageFont.load_default()

    # Draw the entire multiline text at once.
    # This guarantees perfect monospace character alignment and side bearings native to the font!
    # Create an initial large canvas
    img = Image.new("RGBA", (3000, 3000), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw multiline text with a standard spacing
    draw.text((100, 100), logo_text, fill=color6, font=font, spacing=4)

    # Crop to transparent bounding box to eliminate all unnecessary empty space
    bbox = img.getbbox()
    if bbox:
        # Add a tiny 2px padding on all sides to prevent edge clipping during scaling
        padded_bbox = (
            max(0, bbox[0] - 4),
            max(0, bbox[1] - 4),
            min(img.width, bbox[2] + 4),
            min(img.height, bbox[3] + 4)
        )
        img = img.crop(padded_bbox)

    # Save to PNG
    img.save(output_png_path, "PNG")
    print(f"Successfully generated transparent logo PNG at {output_png_path} using color {color6}")

if __name__ == "__main__":
    generate_logo()
