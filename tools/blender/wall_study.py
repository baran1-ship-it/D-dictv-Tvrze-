"""Small Blender masonry study, compatible with Blender 3.6+. Metres; one approved section at a time."""
import bpy, random, math, hashlib
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2]; O=R/'assets/blender';O.mkdir(parents=True,exist_ok=True)
random.seed(46)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
texpath=R/'assets/materials/pbr/rock_face_03_diff.jpg'
assert hashlib.sha256(texpath.read_bytes()).hexdigest()=='ea48e0e47ad42c8bd312476178b1248ec66f0eb19156a26a1c222f2a40caaf2d'
image=bpy.data.images.load(str(texpath));image.pack()
def material(name,color,photo=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.95
 if photo:
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=image;t.projection='BOX';t.projection_blend=.25
  c=m.node_tree.nodes.new('ShaderNodeTexCoord');mapping=m.node_tree.nodes.new('ShaderNodeVectorMath');mapping.operation='SCALE';mapping.inputs[3].default_value=1.5
  m.node_tree.links.new(c.outputs['Object'],mapping.inputs[0]);m.node_tree.links.new(mapping.outputs[0],t.inputs[0])
  mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.35;mix.inputs[2].default_value=(*color,1)
  m.node_tree.links.new(t.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],p.inputs['Base Color'])
  noise=m.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=100;noise.inputs['Detail'].default_value=3
  m.node_tree.links.new(c.outputs['Object'],noise.inputs['Vector'])
  bump=m.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.3;bump.inputs['Distance'].default_value=.009
  m.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs[0],p.inputs['Normal'])
 return m
stones=[material('Limestone_%02d'%i,(.68+i*.045,.63+i*.04,.53+i*.035),True) for i in range(6)]
mortar=material('Recessed lime mortar',(.39,.37,.31));ground=material('Preview ground',(.18,.17,.14))
def cube(name,loc,dimensions,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dimensions;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);return o
core=cube('Solid wall core',(0,.15,1.2),(3,.6,2.4),mortar)
# Jittered Voronoi cells: no repeating square or straight brick courses.
points=[]
for j in range(8):
 for i in range(8):points.append((-1.5+(i+.5+random.uniform(-.37,.37))*3/8,(j+.5+random.uniform(-.39,.39))*2.4/8))
def clip(poly,a,b,c):
 out=[]
 for k,P in enumerate(poly):
  Q=poly[(k+1)%len(poly)];fp=a*P[0]+b*P[1]-c;fq=a*Q[0]+b*Q[1]-c
  if fp<=0:out.append(P)
  if (fp<=0)!=(fq<=0):
   t=fp/(fp-fq);out.append((P[0]+t*(Q[0]-P[0]),P[1]+t*(Q[1]-P[1])))
 return out
for idx,(px,pz) in enumerate(points):
 poly=[(-1.5,0),(1.5,0),(1.5,2.4),(-1.5,2.4)]
 for qx,qz in points:
  if (qx,qz)==(px,pz):continue
  poly=clip(poly,qx-px,qz-pz,(qx*qx+qz*qz-px*px-pz*pz)/2)
  if not poly:break
 if len(poly)<3:continue
 cx=sum(v[0] for v in poly)/len(poly);cz=sum(v[1] for v in poly)/len(poly)
 poly=[(cx+(x-cx)*.95,cz+(z-cz)*.95) for x,z in poly]
 n=len(poly);front=-random.uniform(.21,.29)
 verts=[(x,.08,z) for x,z in poly]+[(x,front+random.uniform(-.015,.015),z) for x,z in poly]
 faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(k,(k+1)%n,(k+1)%n+n,k+n) for k in range(n)]
 mesh=bpy.data.meshes.new('Stone mesh');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Rubble_%03d'%idx,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(random.choice(stones))
 bpy.context.view_layer.objects.active=o;o.select_set(True)
 bevel=o.modifiers.new('Worn stone edges','BEVEL');bevel.width=random.uniform(.018,.032);bevel.segments=3
 bpy.ops.object.modifier_apply(modifier=bevel.name)
 # Fix orientation after construction; keep broad faces flat and edge strips smooth.
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
cube('Preview ground',(0,0,-.08),(200,200,.12),ground)
w=bpy.context.scene.world;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.48,.55,.65,1);w.node_tree.nodes['Background'].inputs[1].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,6));bpy.context.object.data.energy=700;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(3.3,-6,3));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.15))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=4.2;bpy.context.scene.camera=cam
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=True;s.render.resolution_x=1000;s.render.resolution_y=750;s.render.resolution_percentage=100;s.render.filepath=str(O/'wall-study-01.png');s.view_settings.view_transform='Filmic'
bpy.ops.wm.save_as_mainfile(filepath=str(O/'wall-study-01.blend'),compress=True)
bpy.ops.render.render(write_still=True)
print('PASS: Blender wall study saved; 64 independent stones; 3 x 2.4 metres')
