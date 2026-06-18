from PIL import Image, ImageDraw

def mask_rounded_rectangle(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    
    # Resize to 1024x1024 just to be safe
    img = img.resize((1024, 1024), Image.LANCZOS)
    
    # Create a mask with the same size
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    
    width, height = img.size
    r = int(width * 0.225)
    
    # Draw the rounded rectangle
    draw.rounded_rectangle((0, 0, width, height), radius=r, fill=255)
    
    # Apply the mask
    img.putalpha(mask)
    img.save(output_path, "PNG")

mask_rounded_rectangle('/Users/jovi/.gemini/antigravity/brain/8cbdfa26-eccb-46d6-bbde-dd1392528be1/codex_quota_icon_final_1781756939941.png', 'icon.png')
