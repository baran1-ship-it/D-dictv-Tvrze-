"""Blender 3.6+, one measured section of the existing east courtyard facade.
X horizontal, Z up; front is -Y. Exported glTF: +Z front, Y up.
No change to building footprint, doors, windows, floors or player controls.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2];O=R/'assets/blender/section-02';O.mkdir(parents=True,exist_ok=True);ART=R/'source_art/blender/section-02';ART.mkdir(parents=True,exist_ok=True)
random.seed(913)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
static=[];leaf=[];images={};stone_count=0

def img(asset,kind):
 if asset=='rock_damp' and kind!='diff':asset='rock_face_03'
 key=asset+'_'+kind
 if key not in images:
  source=O/'textures'/(key+'.jpg') if asset in ['soil','rock_damp'] else (O/'textures'/'wood-aged-diff.jpg' if key=='roof_planks_diff' else R/'assets/materials/pbr'/(key+'.jpg'))
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
rock=pbr('Limestone', 'rock_face_03',normal=.32);damp=pbr('Damp lower limestone','rock_damp',normal=.32);lime=pbr('Limewash','plastered_wall',normal=.35);wood=pbr('Weathered oak','roof_planks',normal=.45)
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
# Global irregular rubble: no horizontal course or repeating masonry square.
def clip(poly,a,b,c):
 out=[]
 for k,P in enumerate(poly):
  Q=poly[(k+1)%len(poly)];fp=a*P[0]+b*P[1]-c;fq=a*Q[0]+b*Q[1]-c
  if fp<=0:out.append(P)
  if (fp<=0)!=(fq<=0):
   t=fp/(fp-fq);out.append((P[0]+t*(Q[0]-P[0]),P[1]+t*(Q[1]-P[1])))
 return out
points=[(-3.5+(i+.5+random.uniform(-.48,.48))*7/17,(j+.5+random.uniform(-.46,.46))*7.2/27) for j in range(27) for i in range(17)]
def cell(points,idx,rect):
 px,pz=points[idx];poly=[(rect[0],rect[2]),(rect[1],rect[2]),(rect[1],rect[3]),(rect[0],rect[3])]
 for qx,qz in points:
  if (px,pz)==(qx,qz):continue
  poly=clip(poly,qx-px,qz-pz,(qx*qx+qz*qz-px*px-pz*pz)/2)
  if not poly:break
 return poly
def subtract(poly,hole):
 a,b,c,d=hole
 center=clip(clip(poly,-1,0,-a),1,0,b)
 return [q for q in [clip(poly,1,0,a),clip(poly,-1,0,-b),clip(center,0,1,c),clip(center,0,-1,-d)] if len(q)>=3]
def pebble(name,poly,front,back,mat,floor=False):
 cx=sum(x for x,z in poly)/len(poly);cz=sum(z for x,z in poly)/len(poly)
 shrink=.975 if floor else random.uniform(.925,.96)
 poly=[(cx+(x-cx)*shrink,cz+(z-cz)*shrink) for x,z in poly];n=len(poly)
 verts=([(x,z,back) for x,z in poly]+[(x,z,front+random.uniform(-.003,.003)) for x,z in poly]) if floor else ([(x,back,z) for x,z in poly]+[(x,front+random.uniform(-.003,.003),z) for x,z in poly])
 verts.append((cx,cz,front+.008) if floor else (cx,front-.008,cz))
 faces=[tuple(range(n-1,-1,-1))]+[(n+j,n+(j+1)%n,2*n) for j in range(n)]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,mat,.009 if floor else .017)
 for f in o.data.polygons:
  if (abs(f.normal.z)>.8 if floor else abs(f.normal.y)>.8):f.use_smooth=True
for idx in range(len(points)):
 polys=[cell(points,idx,(-3.5,3.5,0,7.2))]
 for hole in holes:polys=[part for poly in polys if len(poly)>=3 for part in subtract(poly,hole)]
 for poly in polys:
  if len(poly)<3:continue
  wet=max(z for x,z in poly)<random.uniform(.40,.65) and abs(sum(x for x,z in poly)/len(poly))>1.2
  pebble('Rubble_%03d'%stone_count,poly,-.33-random.uniform(0,.012),-.275,damp if wet else rock);stone_count+=1
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
for name,poly in [('Limewash A',[(-3.5,3.6),(-3.5,6.6),(-2.55,6.65),(-2.6,6.3),(-2.4,5.4),(-2.55,4.7),(-2.3,4.5),(-2.5,3.6)]),('Limewash bridge',[(-2.65,3.4),(-2.5,4.7),(-1.5,4.5),(-.8,4.65),(.7,4.62),(1.7,4.6),(2.1,3.7),(1.7,3.2),(.5,3.4),(-.3,3.1),(-1.4,3.35)]),('Limewash crown',[(-3.5,6.5),(-2.4,6.55),(-1.5,6.3),(-.8,6.45),(.9,6.44),(1.5,6.25),(2.5,6.4),(3.5,6.5),(3.5,7.2),(-3.5,7.2)]),('Limewash B',[(1.9,3.6),(2.0,4.1),(1.7,4.45),(1.9,5.1),(1.7,5.3),(2.2,6.4),(3.5,6.4),(3.5,3.6)])]:
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
# Courtyard is a site-specific transition, not a tile to duplicate.
soil=pbr('Compacted earth','soil',normal=.55)
box('Earth bed',(0,-2.65,-.055),(9,5.9,.10),soil,0)
paving_points=[(-4.5+(i+.5+random.uniform(-.44,.44))*9/27,-5.5+(j+.5+random.uniform(-.46,.46))*5.9/19) for j in range(19) for i in range(27)]
paving_count=0
for idx,(px,py) in enumerate(paving_points):
 route=abs(px-.30*math.sin(py))<1.45+.2*math.sin(py*2)
 edge=py>-.95 and abs(px)>1.45
 apron=abs(px)<2.3 and py>-2.4
 if not (route or edge or apron):continue
 if abs(px)<1.15 and py>-.95:continue
 poly=cell(paving_points,idx,(-4.5,4.5,-5.5,.4))
 if len(poly)>=3:pebble('Worn paving_%03d'%idx,poly,random.uniform(.005,.027),-.04,rock,True);paving_count+=1
box('Worn threshold',(0,-.47,.018),(2.14,.84,.065),rock,.018)
# Small peripheral clumps: none obstruct the doorway or main footpath.
grass=simple('Grass at unused margins',(.075,.115,.035))
for k in range(70):
 x=random.uniform(-4.3,4.3);y=random.uniform(-5.2,-.45)
 if abs(x)<1.9 or (x>0 and y<-3.0):continue
 for blade in range(9):
  xx=x+random.uniform(-.08,.08);yy=y+random.uniform(-.08,.08);h=random.uniform(.035,.11)
  verts=[]
  for level in range(4):
   t=level/3;width=.009*(1-t)+.001;verts.extend([(xx-width+t*t*.02,yy+t*t*.04,h*t),(xx+width+t*t*.02,yy+t*t*.04,h*t)])
  me=bpy.data.meshes.new('Curved grass blade');me.from_pydata(verts,[],[(i*2,i*2+1,i*2+3,i*2+2) for i in range(3)]);me.update();o=bpy.data.objects.new('Peripheral grass',me);bpy.context.collection.objects.link(o);finish(o,grass,0)
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
groups={mat:[o for o in static if o.data.materials[0]==mat] for mat in [rock,damp,lime,mortar,wood,iron,glass,tiles,soil,grass]}
for mat,objs in groups.items():
 if not objs:continue
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name='Static_'+mat.name.replace(' ','_');merged.append(o);o.select_set(False)
static=merged
for o in static:
 if o.data.materials[0] in [rock,damp]:
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
report={'stone_count':stone_count,'paving_count':paving_count,'static_triangles':triangles(static),'door_triangles':triangles(leaf),'static_material_batches':len(static),'door_material_batches':len(leaf),'lod1_triangles':lod_triangles,'width_m':7,'height_m':7.2,'stone_protrusion_m_max':.042,'target_world_position_godot':[8,0,8],'target_y_rotation_deg':-90,'door_width':2.1,'door_height':2.65,'window_opening':[1.32,1.30],'hardware_fps_measured':False}
(O/'geometry-report.json').write_text(json.dumps(report,indent=2))
# Preview rig, not exported. Sun and soft sky; indoor occlusion comes from geometry.
bpy.ops.object.select_all(action='DESELECT');box('Preview ground',(0,0,-.10),(100,100,.14),mortar,0,[])
w=bpy.context.scene.world;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.57,.66,.8,1);w.node_tree.nodes['Background'].inputs[1].default_value=.4
bpy.ops.object.light_add(type='SUN',location=(-4,-5,9));sun=bpy.context.object;sun.rotation_euler=(math.radians(28),math.radians(-25),math.radians(-25));sun.data.energy=2.3;sun.data.angle=.07
bpy.ops.object.light_add(type='AREA',location=(-4,-5,7));bpy.context.object.data.energy=250;bpy.context.object.data.size=5
bpy.ops.object.camera_add();cam=bpy.context.object;bpy.context.scene.camera=cam
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=20;s.cycles.use_denoising=True;s.render.resolution_x=1100;s.render.resolution_y=1000;s.render.resolution_percentage=100;s.view_settings.view_transform='Filmic';s.view_settings.look='Medium High Contrast'
shots=[('facade',(9,-14,9),(0,0,3.6),12.5),('door-detail',(3.7,-5.8,3.1),(0,-.3,1.75),4.1),('ground-detail',(4,-7,2.8),(1.1,-1.8,.3),5.0)]
for name,pos,target,scale in shots:
 pivot.rotation_euler.z=math.radians(88.2) if name=='door-open' else 0
 cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale;s.render.filepath=str(ART/(name+'.png'));bpy.ops.render.render(write_still=True)
pivot.rotation_euler.z=0;bpy.ops.wm.save_as_mainfile(filepath=str(ART/'section-02.blend'),compress=True)
print('PASS SECTION',json.dumps(report))
