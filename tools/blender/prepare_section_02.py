"""Prepare deterministic authored earth maps and CC0-derived damp rock/aged wood."""
from pathlib import Path
# Four mobile-size material maps for compacted earth, deterministic authored noise.
import numpy as np
from PIL import Image,ImageFilter
rng=np.random.default_rng(43);n=512;field=np.zeros((n,n),dtype=float)
for small,amp in [(8,.5),(32,.24),(128,.13),(512,.08)]:
 im=Image.fromarray((rng.random((small,small))*255).astype('uint8')).resize((n,n),Image.Resampling.BICUBIC);field+=np.asarray(im)/255*amp
field=np.clip(field,0,1);color=np.stack([.21+.15*field,.16+.12*field,.105+.09*field],axis=-1)
ROOT=Path(__file__).resolve().parents[2]
out=ROOT/'assets/blender/section-02/textures';out.mkdir(parents=True,exist_ok=True)
Image.fromarray((color*255).astype('uint8')).save(out/'soil_diff.jpg',quality=95)
dy,dx=np.gradient(field);norm=np.stack([-dx*2.5,-dy*2.5,np.ones_like(dx)],axis=-1);norm/=np.linalg.norm(norm,axis=-1,keepdims=True)
Image.fromarray(((norm*.5+.5)*255).astype('uint8')).save(out/'soil_normal.jpg',quality=95)
for kind,value in [('rough',np.full_like(field,.94)),('ao',.86+.14*field)]:Image.fromarray((value*255).astype('uint8')).save(out/f'soil_{kind}.jpg',quality=95)

from PIL import ImageEnhance
im=Image.open(ROOT/"assets/materials/pbr/rock_face_03_diff.jpg");im=ImageEnhance.Color(im).enhance(.7);im=ImageEnhance.Brightness(im).enhance(.66);im.save(out/"rock_damp_diff.jpg",quality=95)
im=Image.open(ROOT/"assets/materials/pbr/roof_planks_diff.jpg");im=ImageEnhance.Color(im).enhance(.40);im=ImageEnhance.Brightness(im).enhance(.76);im.save(out/"wood-aged-diff.jpg",quality=95)
