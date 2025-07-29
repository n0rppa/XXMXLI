import os

gallery_dir = "assets/images"
gallery_html_file = "photography.html"

# Find all image files
images = [f for f in os.listdir(gallery_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp'))]

gallery_items = ""
for img in images:
    gallery_items += f'''        <div class="gallery-item">
            <img src="{gallery_dir}/{img}" alt="{img}">
        </div>\n'''

# Read photography.html and replace GALLERY_START/END section
with open(gallery_html_file, "r", encoding="utf-8") as f:
    html = f.read()

start = html.find("<!-- GALLERY_START -->")
end = html.find("<!-- GALLERY_END -->") + len("<!-- GALLERY_END -->")
new_html = html[:start] + "<!-- GALLERY_START -->\n" + gallery_items + "        <!-- GALLERY_END -->" + html[end:]

with open(gallery_html_file, "w", encoding="utf-8") as f:
    f.write(new_html)

print("Kuvagalleria päivitetty automaattisesti.")
