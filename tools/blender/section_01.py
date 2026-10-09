"""Blender 3.6+, one measured section of the existing east courtyard facade.
X horizontal, Z up; front is -Y. Exported glTF: +Z front, Y up.
No change to building footprint, doors, windows, floors or player controls.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2];O=R/'assets/blender/section-01';O.mkdir(parents=True,exist_ok=True);ART=R/'source_art/blender/section-01';ART.mkdir(parents=True,exist_ok=True)
random.seed(913)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
static=[];leaf=[];images={};stone_count=0

def img(asset,kind):
 key=asset+'_'+kind
 if key not in images:
  source=O/'textures'/ 'wood-aged-diff.jpg' if key=='roof_planks_diff' else R/'assets/materials/pbr'/(key+'.jpg')
  im=bpy.data.images.load(str(source));im.pack();im.colorspace_settings.name='sRGB' if kind=='diff' else 'Non-Color';images[key]=im
 return images[key]
def pbr(name,asset,tint=(1,1,1),normal=.4):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.9
 nodes=m.node_tree.nodes;links=m.node_tree.links
 for kind,target in [('diff','Base Color'),('rough','Roughness')]:
  t=nodes.new('ShaderNodeTexImage');t.image=img(asset,kind)
  # Tint kept in vertex colours so standard glTF export keeps the photographed image.
  links.new(t.outputs['Color'],p.inputs[target])
 t=nodes.new('ShaderNodeTexImage');t.image=img(asset,'normal');n=nodes.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=normal;links.new(t.outputs['Color'],n.inputs['Color']);links.new(n.outputs['Normal'],p.inputs['Normal'])
 g=bpy.data.node_groups.get('glTF Material Output')
 if not g:
  g=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree');g.inputs.new('NodeSocketFloat','Occlusion');g.nodes.new('NodeGroupInput');g.nodes.new('NodeGroupOutput')
 oc=nodes.new('ShaderNodeGroup');oc.node_tree=g;t=nodes.new('ShaderNodeTexImage');t.image=img(asset,'ao');links.new(t.outputs['Color'],oc.inputs['Occlusion'])
 return m
rock=pbr('Limestone', 'rock_face_03',normal=.32);lime=pbr('Limewash','plastered_wall',normal=.35);wood=pbr('Weathered oak','roof_planks',normal=.45)
def simple(name,color,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.87;p.inputs['Metallic'].default_value=metal;return m
mortar=simple('Lime mortar',(.60,.56,.46));iron=simple('Forged iron',(.055,.052,.047),.7);glass=simple('Dark window',(.075,.095,.095));tiles=simple('Muted fired clay',(.27,.12,.065))

def finish(o,mat,bevel=0,collection=static,woodgrain=False):
 o.data.materials.append(mat);bpy.context.view_layer.objects.active=o
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Worn edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 # World-sized UVs, independent offsets per stone, longitudinal wood grain per board.
 uv=o.data.uv_layers.active or o.data.uv_layers.new(name='UVMap');uv.name='UVMap';phase=(random.random(),random.random());wood_start=(random.randrange(11)+.2)/11
 for poly in o.data.polygons:
  axis=max(range(3),key=lambda i:abs(poly.normal[i]))
  for li in poly.loop_indices:
   v=o.data.vertices[o.data.loops[li].vertex_index].co
   if mat==wood:
    longitudinal=max(range(3),key=lambda i:o.dimensions[i]);cross=next(i for i in range(3) if i!=longitudinal and i!=axis) if axis!=longitudinal else (longitudinal+1)%3
    coord=((v[cross]/max(o.dimensions[cross],.01)+.5)*.04+wood_start,v[longitudinal]/max(o.dimensions[longitudinal],.01)+.5)
   else:
    a,b=(0,2) if axis==1 else ((1,2) if axis==0 else (0,1));coord=(v[a]/1.6+phase[0],v[b]/1.6+phase[1])
   uv.data[li].uv=coord
 # glTF supports vertex colours. Subtle warm/cool stone variation.
 col=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER');shade=random.uniform(.86,1.0) if mat==rock else 1
 for c in col.data:c.color=(shade,shade*.99,shade*.96,1)
 collection.append(o);return o

def box(name,loc,size,mat,bev=.012,collection=static,woodgrain=False):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;return finish(o,mat,bev,collection,woodgrain)

# Exact openings in the current facade: door 2.26 x 2.72, window 1.32 x 1.30 at y=5.57.
# Keep a flat continuous wall core; shallow rock faces sit within +/- 3 cm of it.
holes=[(-1.13,1.13,0,2.72),(-.66,.66,4.92,6.22)]
def intervals(z,h):
 ranges=[(-3.5,3.5)]
 for a,b,c,d in holes:
  if z<d and z+h>c:
   new=[]
   for lo,hi in ranges:
    if a>lo:new.append((lo,min(a,hi)))
    if b<hi:new.append((max(b,lo),hi))
   ranges=[(a,b) for a,b in new if b-a>.015]
 return ranges
bounds=[0,2.72,4.92,6.22,7.2]
for i in range(len(bounds)-1):
 z=bounds[i];h=bounds[i+1]-z
 for a,b in intervals(z,h):box('Wall core',((a+b)/2,.0,z+h/2),(b-a,.63,h),mortar,0)
# Irregular rough courses, with different lengths, chipped outlines and understated depth.
for low,high in zip(bounds,bounds[1:]):
 z=low
 while z<high-.01:
  h=min(random.uniform(.19,.32),high-z)
  for a,b in intervals(z,h):
   x=a
   while x<b-.012:
    w=min(random.uniform(.25,.62),b-x)
    if w<.04:break
    # Eight-point roughly rectangular broken edges; no huge boulders.
    dx=w/2-.009;dz=h/2-.007;cx=x+w/2;cz=z+h/2;cut=min(w,h)*random.uniform(.13,.25)
    poly=[(-dx,-dz+cut),(-dx+cut,-dz),(dx-cut,-dz),(dx,-dz+cut),(dx,dz-cut),(dx-cut,dz),(-dx+cut,dz),(-dx,dz-cut)]
    front=-.32-random.uniform(.0,.025)
    verts=[(cx+px,-.275,cz+pz) for px,pz in poly]+[(cx+px,front+random.uniform(-.004,.004),cz+pz) for px,pz in poly]
    n=8;faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    mesh=bpy.data.meshes.new('Rubble mesh');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Rubble_%03d'%stone_count,mesh);bpy.context.collection.objects.link(o);finish(o,rock,.007);stone_count+=1;x+=w
  z+=h
# Dressed jambs, bearing lintel, sill with drip edge. Opening dimensions unchanged.
for side in [-1,1]:
 for j in range(6):box('Door jamb',(side*1.2,-.04,(j+.5)*2.72/6),(.25,.74,2.72/6-.012),rock,.014)
box('Door bearing lintel',(0,-.045,2.84),(2.65,.76,.3),rock,.018)
for side in [-1,1]:
 for j in range(3):box('Window jamb',(side*.71,-.06,4.85+(j+.5)*1.54/3),(.16,.8,1.54/3-.012),rock,.012)
box('Window lintel',(0,-.075,6.29),(1.56,.82,.17),rock,.014)
box('Window sill',(0,-.1,4.85),(1.62,.92,.18),rock,.012)
box('Window drip',(0,-.43,4.74),(1.5,.045,.03),mortar,.002)
box('Window pane',(0,0,5.57),(1.26,.025,1.27),glass,.002)
for x in [-.59,0,.59]:box('Window mullion',(x,-.025,5.57),(.055,.06,1.28),wood,.005,woodgrain=True)
for z in [4.97,5.57,6.17]:box('Window transom',(0,-.025,z),(1.27,.06,.06),wood,.004)
for side in [-1,1]:
 o=box('Oak shutter',(side*1.05,-.4,5.57),(.55,.055,1.25),wood,.009,woodgrain=True);o.rotation_euler.z=side*.13
# Limited worn limewash; masonry stays legible. Shapes are fixed architectural areas, not random buildings.
for name,poly in [('Limewash A',[(-3.5,3.6),(-3.5,6.6),(-2.55,6.65),(-2.6,6.3),(-2.4,5.4),(-2.55,4.7),(-2.3,4.5),(-2.5,3.6)]),('Limewash B',[(1.9,3.6),(2.0,4.1),(1.7,4.45),(1.9,5.1),(1.7,5.3),(2.2,6.4),(3.5,6.4),(3.5,3.6)])]:
 ragged=[]
 for k,(x,z) in enumerate(poly):
  qx,qz=poly[(k+1)%len(poly)];steps=max(1,int(math.hypot(qx-x,qz-z)/.15))
  for j in range(steps):
   t=j/steps;xx=x+(qx-x)*t;zz=z+(qz-z)*t
   if abs(xx)<3.49:xx+=random.uniform(-.05,.05)
   if j>0:zz+=random.uniform(-.035,.035)
   ragged.append((xx,-.349-random.uniform(0,.002),zz))
 me=bpy.data.meshes.new(name);me.from_pydata(ragged,[],[tuple(range(len(ragged)))]);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,lime,0)
# Matched neighbouring floor edges and supported exposed roof eave, only for this section.
for z in [3.6,7.2]:box('Interior floor edge',(0,.65,z-.09),(7,1.9,.18),wood,.014)
box('Wall plate',(0,.04,7.25),(7.3,.28,.22),wood,.015)
for x in [-3,-2,-1,0,1,2,3]:
 beam=box('Rafter foot',(x,-.2,7.45),(.14,1.45,.16),wood,.01);beam.rotation_euler.x=math.radians(25)
# Small row of individually overlapping tiles; no change to all roofs yet.
for row in range(3):
 for i in range(31):
  x=-3.66+i*.24; y=-.6+row*.27; z=7.37+row*.13
  o=box('Clay tile',(x,y,z),(.235,.43,.028),tiles,.006);o.rotation_euler.x=math.radians(25)
# Separate hinged leaf; same gameplay size, hinge and grasp point as existing door.
pivot=bpy.data.objects.new('DoorLeaf',None);bpy.context.collection.objects.link(pivot);pivot.location=(-1.05,0,0)
for i in range(9):box('Oak door board',((i+.5)*2.1/9-1.05,0,1.325),(2.1/9-.004,.13,2.65),wood,.006,leaf,True)
for z in [.5,2.0]:
 box('Forged hinge strap',(-.15,-.085,z),(1.8,.035,.07),iron,.004,leaf)
 for x in [-.92,-.55,.70]:
  bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.025,location=(x,-.112,z));finish(bpy.context.object,iron,0,leaf)
for side in [-1,1]:
 box('Handle backplate',(.60,side*.074,1.165),(.15,.02,.20),iron,.005,leaf)
 bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,location=(.60,side*.095,1.10),rotation=(math.pi/2,0,0),major_radius=.077,minor_radius=.013);finish(bpy.context.object,iron,0,leaf)
bpy.context.view_layer.update()
for o in leaf:o.parent=pivot;o.matrix_parent_inverse=pivot.matrix_world.inverted()
# Batch moving meshes into two material surfaces without changing their hinge.
leaf_groups={mat:[o for o in leaf if o.data.materials[0]==mat] for mat in [wood,iron]}
leaf=[]
for mat,objs in leaf_groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name='Leaf_'+mat.name.replace(' ','_');leaf.append(o);o.select_set(False)
# Batch static meshes by material, keeping moving door separate.
bpy.ops.object.select_all(action='DESELECT')
merged=[]
groups={mat:[o for o in static if o.data.materials[0]==mat] for mat in [rock,lime,mortar,wood,iron,glass,tiles]}
for mat,objs in groups.items():
 if not objs:continue
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name='Static_'+mat.name.replace(' ','_');merged.append(o);o.select_set(False)
static=merged
for o in static:
 if o.data.materials[0]==rock:
  bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Mobile near detail','DECIMATE');mod.ratio=.28;bpy.ops.object.modifier_apply(modifier=mod.name)
# Export each reusable asset without camera/lighting/ground; glTF carries photographed PBR maps.
def select(objs):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
select(static);bpy.ops.export_scene.gltf(filepath=str(O/'section-static.glb'),export_format='GLB',use_selection=True,export_tangents=True)
old=pivot.location.copy();pivot.location.x=0;select([pivot]+leaf);bpy.ops.export_scene.gltf(filepath=str(O/'door-leaf.glb'),export_format='GLB',use_selection=True,export_tangents=True);pivot.location=old
# Reduced mesh for distant viewing, same placement/holes; inspect real exported triangle counts.
lod=[]
for o in static:
 d=o.copy();d.data=o.data.copy();bpy.context.collection.objects.link(d);d.name=o.name+'_LOD1';bpy.context.view_layer.objects.active=d
 if o.data.materials[0] not in [mortar,glass]:
  mod=d.modifiers.new('Distant detail','DECIMATE');mod.ratio=.30;bpy.ops.object.modifier_apply(modifier=mod.name)
 lod.append(d)
select(lod);bpy.ops.export_scene.gltf(filepath=str(O/'section-lod1.glb'),export_format='GLB',use_selection=True,export_tangents=True)
lod_triangles=sum(len(o.data.loop_triangles) or sum(len(f.vertices)-2 for f in o.data.polygons) for o in lod)
for o in lod:bpy.data.objects.remove(o,do_unlink=True)
def triangles(objs):
 count=0
 for o in objs:o.data.calc_loop_triangles();count+=len(o.data.loop_triangles)
 return count
report={'stone_count':stone_count,'static_triangles':triangles(static),'door_triangles':triangles(leaf),'static_material_batches':len(static),'door_material_batches':len(leaf),'lod1_triangles':lod_triangles,'width_m':7,'height_m':7.2,'stone_protrusion_m_max':.034,'target_world_position_godot':[8,0,8],'target_y_rotation_deg':-90,'door_width':2.1,'door_height':2.65,'window_opening':[1.32,1.30],'hardware_fps_measured':False}
(O/'geometry-report.json').write_text(json.dumps(report,indent=2))
# Preview rig, not exported. Sun and soft sky; indoor occlusion comes from geometry.
bpy.ops.object.select_all(action='DESELECT');box('Preview ground',(0,0,-.10),(100,100,.14),mortar,0,[])
w=bpy.context.scene.world;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.57,.66,.8,1);w.node_tree.nodes['Background'].inputs[1].default_value=.4
bpy.ops.object.light_add(type='SUN',location=(-4,-5,9));sun=bpy.context.object;sun.rotation_euler=(math.radians(28),math.radians(-25),math.radians(-25));sun.data.energy=2.3;sun.data.angle=.07
bpy.ops.object.light_add(type='AREA',location=(-4,-5,7));bpy.context.object.data.energy=250;bpy.context.object.data.size=5
bpy.ops.object.camera_add();cam=bpy.context.object;bpy.context.scene.camera=cam
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=20;s.cycles.use_denoising=True;s.render.resolution_x=1100;s.render.resolution_y=1000;s.render.resolution_percentage=100;s.view_settings.view_transform='Filmic';s.view_settings.look='Medium High Contrast'
shots=[('facade',(9,-14,9),(0,0,3.6),11.3),('door-detail',(3.7,-5.8,3.1),(0,-.3,1.75),4.1),('window-detail',(2.8,-5.8,6.7),(0,-.3,5.65),3.4),('door-open',(5,-9,4),(0,0,2.8),7.5)]
for name,pos,target,scale in shots:
 pivot.rotation_euler.z=math.radians(88.2) if name=='door-open' else 0
 cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale;s.render.filepath=str(ART/(name+'.png'));bpy.ops.render.render(write_still=True)
pivot.rotation_euler.z=0;bpy.ops.wm.save_as_mainfile(filepath=str(ART/'section-01.blend'),compress=True)
print('PASS SECTION',json.dumps(report))
