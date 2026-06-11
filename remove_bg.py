from rembg import remove
from PIL import Image
import os

files = ['assets/images/logo_icon.png', 'assets/images/logo_horizontal.png']
for f in files:
    try:
        print(f"Processing {f}...")
        input_image = Image.open(f)
        output_image = remove(input_image)
        output_image.save(f.replace('.png', '_t.png'))
        print(f"Saved {f.replace('.png', '_t.png')}")
    except Exception as e:
        print(f"Error on {f}: {e}")
