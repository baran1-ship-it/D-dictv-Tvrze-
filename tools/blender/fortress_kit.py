"""Build 112 native Blender meshes. Blender 4.5; metres, closed manifold topology.
Godot consumes the exact evaluated triangles, not a reconstructed texture surface.
"""
import bpy,bmesh,json,math,random,zlib,base64
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2];O=R/'assets/kit';O.mkdir(parents=True,exist_ok=True)
D=R/'build';D.mkdir(exist_ok=True);(D/'.gdignore').touch()
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
random.seed(140312);records=[];objects=[]
colors={'rubble':(.48,.45,.38),'paving':(.44,.42,.36),'beam':(.22,.15,.08),'plank':(.32,.24,.14),'quoin':(.58,.52,.42),'shingle':(.28,.23,.17),'tile':(.46,.27,.16),'plaster':(.75,.70,.61)}
mats={}
for g,c in colors.items():
 m=bpy.data.materials.new(g);m.use_nodes=True;m.diffuse_color=(*c,1)
 m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*c,1)
 m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.95;mats[g]=m

def obj(name,g,vs,fs):
 m=bpy.data.meshes.new(name);m.from_pydata([(x,-z,y) for x,y,z in vs],[],fs);m.update()
 bm=bmesh.new();bm.from_mesh(m);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
 assert all(e.is_manifold for e in bm.edges),name
 bm.to_mesh(m);bm.free();m.calc_loop_triangles();rows=[]
 for t in m.loop_triangles:
  assert t.area>1e-9,name
  n=t.normal
  for idx in t.vertices:
   p=m.vertices[idx].co
   rows.append([round(q,5) for q in (p.x,p.z,-p.y,n.x,n.z,-n.y,p.x+.5,p.z+.5)])
 o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o);m.materials.append(mats[g]);objects.append(o)
 records.append({'name':name,'group':g,'rows':rows});return o

def stone(name,g,n,wear):
 ring=[]
 outline=[(-.5,-.45),(-.43,-.5),(.45,-.5),(.5,-.43),(.5,.44),(.43,.5),(-.44,.5),(-.5,.43)] if n==8 else [(-.5,-.46),(.4,-.5),(.5,-.34),(.5,.46),(-.42,.5),(-.5,.32)]
 for i,(x,y) in enumerate(outline):
  chip=random.uniform(0,.025)+(wear*.35 if i==random.randrange(n) else 0)
  ring.append((x*(1-chip),y*(1-chip)))
 v=[(x*.93,y*.93,-.5) for x,y in ring]+[(x,y,.44+random.uniform(-.055,.04)) for x,y in ring]
 v += [(random.uniform(-.09,.09),random.uniform(-.06,.06),.49),(0,0,-.5)]
 f=[]
 for i in range(n):
  j=(i+1)%n;f += [(i,j,n+j,n+i),(2*n,n+i,n+j),(2*n+1,j,i)]
 obj(name,g,v,f)

def wood(name,g,k):
 outline=[(-.46,-.5),(.45,-.5),(.5,-.44),(.5,.45),(.44,.5),(-.45,.5),(-.5,.44),(-.5,-.45)]
 v=[];levels=5
 for j in range(levels):
  y=-.5+j/(levels-1);bow=math.sin((y+.5)*math.pi)*random.uniform(-.04,.04)
  for i,(x,z) in enumerate(outline):
   chip=random.uniform(0,.025)+(.08 if i==k%8 and j==k%3+1 else 0)
   v.append((x*(1-chip)+bow,y,z*(1-chip)+math.sin(j*1.7+k)*.008))
 f=[]
 for j in range(levels-1):
  for i in range(8):f.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
 f += [tuple(range(7,-1,-1)),tuple((levels-1)*8+i for i in range(8))];obj(name,g,v,f)

def roof(name,g,k):
 v=[];w=3;h=3
 for layer in [-1,1]:
  for j in range(h):
   y=-.5+j/(h-1)
   for i in range(w):
    x=-.5+i/(w-1);cup=(.08 if g=='tile' else .035)*(1-(x*2)**2)
    v.append((x,y+(random.uniform(-.035,.035) if j==0 else 0),layer*.14+.26*(.5-y)+cup+math.sin(i+j+k)*.01))
 f=[];off=w*h
 for j in range(h-1):
  for i in range(w-1):
   a=j*w+i;b=a+1;c=a+w+1;d=a+w;f += [(a,d,c,b),(off+a,off+b,off+c,off+d)]
 ring=[0,1,2,5,8,7,6,3]
 for i,a in enumerate(ring):
  b=ring[(i+1)%len(ring)];f.append((a,b,off+b,off+a))
 obj(name,g,v,f)
for i in range(32):stone('rubble_%02d'%i,'rubble',6 if i%3 else 8,.14)
for i in range(16):stone('paving_%02d'%i,'paving',8,.16)
for i in range(12):wood('beam_%02d'%i,'beam',i)
for i in range(12):wood('plank_%02d'%i,'plank',i+3)
for i in range(8):stone('quoin_%02d'%i,'quoin',8,.025)
for i in range(12):roof('shingle_%02d'%i,'shingle',i)
for i in range(12):roof('tile_%02d'%i,'tile',i)
for i in range(8):stone('plaster_%02d'%i,'plaster',8,.19)
assert len(records)==112
raw=json.dumps({'count':112,'generator':'Blender '+bpy.app.version_string,'assets':records},separators=(',',':')).encode()
(O/'fortress-kit.json').write_text(json.dumps({'length':len(raw),'zlib_base64':base64.b64encode(zlib.compress(raw,9)).decode()},separators=(',',':')))
sizes={'rubble':(.65,.4,.32),'paving':(.68,.04,.52),'beam':(.22,.22,2.1),'plank':(.30,.07,2.0),'quoin':(.72,.6,.42),'shingle':(.26,.07,.55),'tile':(.33,.08,.52),'plaster':(.48,.04,.4)}
for i,o in enumerate(objects):
 o.location=((i%14)*1.6,-(i//14)*1.6,1.2);o.scale=sizes[records[i]['group']];o['variant']=records[i]['name']
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(D/'fortress-kit-112.glb'),export_format='GLB',use_selection=True)
s=bpy.context.scene;s.world.color=(.2,.2,.2)
bpy.ops.object.camera_add(location=(11,-17,21));cam=bpy.context.object;cam.rotation_euler=(Vector((10,-5,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=24;s.camera=cam
bpy.ops.object.light_add(type='AREA',location=(8,-5,18));bpy.context.object.data.energy=2800;bpy.context.object.data.size=15
s.render.engine='CYCLES';s.cycles.samples=16;s.cycles.use_denoising=True;s.render.resolution_x=1400;s.render.resolution_y=900;s.render.resolution_percentage=100;s.render.filepath=str(D/'blender-kit-112.png')
bpy.ops.wm.save_as_mainfile(filepath=str(D/'tvrz-stavebni-sada-112.blend'),compress=True)
bpy.ops.render.render(write_still=True)
(D/'kit-manifest.json').write_text(json.dumps({'count':112,'blender':bpy.app.version_string,'closed_manifold_checked':True,'groups':{g:sum(a['group']==g for a in records) for g in colors}},indent=2))
print('PASS: 112 closed Blender models, native blend, GLB and compressed exact triangle export')
