"""CC0 colour derivative for this one section; run after tools/fetch_materials.py."""
from pathlib import Path
from PIL import Image, ImageEnhance
ROOT=Path(__file__).resolve().parents[2]
out=ROOT/'assets/blender/section-01/textures'
out.mkdir(parents=True,exist_ok=True)
im=Image.open(ROOT/'assets/materials/pbr/roof_planks_diff.jpg').convert('RGB')
im=ImageEnhance.Color(im).enhance(.40)
im=ImageEnhance.Brightness(im).enhance(.76)
im.save(out/'wood-aged-diff.jpg',quality=95)
