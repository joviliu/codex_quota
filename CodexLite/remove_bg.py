from PIL import Image

def remove_white_bg(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    new_data = []
    
    for item in data:
        if item[0] > 230 and item[1] > 230 and item[2] > 230:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

remove_white_bg('/Users/jovi/.gemini/antigravity/brain/8cbdfa26-eccb-46d6-bbde-dd1392528be1/terminal_quota_icon_1781756405510.png', 'icon.png')
