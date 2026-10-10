extends Node3D
const RoofClip = preload("res://scripts/roof_clip.gd")
const ATTIC_Y := 14.91
const Vault = preload("res://scripts/vault_mesh.gd")
const GALLERY_Y := 5.0
const UPPER_CLEAR := 3.0
const FLOOR_STEP := 3.26
const TOWER_LEVELS := [0.0,5.0,8.26,11.52]
var vaults: Array = []
var wall_finish_override := ""
var tower_room_doors: Array = []
var rail_posts: Dictionary = {}
const Door = preload("res://scripts/fortress_door.gd")
const Construction = preload("res://scripts/construction_mesh.gd")
const Masonry = preload("res://scripts/masonry_mesh.gd")
const Shingles = preload("res://scripts/shingle_mesh.gd")
const Scanned = preload("res://scripts/scanned_surface.gd")
var heights: Dictionary = {}
var relief_cells := 0
var roof_cells := 0
var stone_count := 0
var use_solid_masonry := false
var floor_patches: Array = []
var rail_routes: Array = []
var mats: Dictionary = {}
var batches: Dictionary = {}
var mesh_cache: Dictionary = {}
var repeats: Dictionary = {}
var doors: Array = []
var rooms: Array = []
var static_body: StaticBody3D
var stair_routes: Array = []
var wall_routes: Array = []
var roof_normals: Array[Vector3] = []
var windows: Array = []
var rng := RandomNumberGenerator.new()

func source_fingerprint() -> String:
	var source := ""
	for file in ["fortress_builder.gd","masonry_mesh.gd","construction_mesh.gd","blender_kit.gd","shingle_mesh.gd","fortress_door.gd","roof_clip.gd","vault_mesh.gd"]: source += FileAccess.get_file_as_string("res://scripts/"+file)
	source += FileAccess.get_file_as_string("res://assets/kit/fortress-kit.json")
	return source.sha256_text()

func build() -> void:
	if ResourceLoader.exists("res://assets/kit/assembled.scn"):
		var ready_world: Node3D = load("res://assets/kit/assembled.scn").instantiate()
		if ready_world.get_meta("source_fingerprint","")==source_fingerprint():
			add_child(ready_world)
			static_body = ready_world.get_node("ArchitectureCollision")
			for key in ["rooms","floor_patches","rail_routes","stair_routes","wall_routes","windows","vaults","mats","relief_cells","roof_cells","stone_count"]: set(key,ready_world.get_meta(key))
			roof_normals.assign(ready_world.get_meta("roof_normals"))
			for node in ready_world.find_children("*","Node3D",true,false):
				if node.get_script()==Door:
					doors.append(node)
					if node.title.begins_with("Pokoj věže"): tower_room_doors.append(node)
			return
		ready_world.free()
	print("ASSEMBLY: building Blender architecture")
	rng.seed = 1403
	make_materials()
	static_body = StaticBody3D.new()
	static_body.name = "ArchitectureCollision"
	add_child(static_body)
	box(Vector3(0,-.45,0),Vector3(170,.8,170),"grass",true)
	box(Vector3(0,-.08,0),Vector3(36,.16,36),"mortar",true)
	courtyard()
	for i in range(24):
		var angle := i*2.39996
		var radius := 30.0+float(i%4)*8
		var pos := Vector3(sin(angle)*radius,0,cos(angle)*radius)
		cylinder(pos+Vector3(0,2,0),.28,.42,4,"beam")
		for j in range(4):
			var foliage := SphereMesh.new()
			foliage.radius = 2.1-j*.22
			foliage.height = 3.7-j*.3
			foliage.radial_segments = 10
			foliage.rings = 6
			batch(foliage,Transform3D(Basis.IDENTITY,pos+Vector3(sin(j*2.4)*.7,4.5+j*.9,cos(j*2.4)*.7)),"leaves")
	use_solid_masonry = true
	var curtain_top := GALLERY_Y+1.1
	for x in [-18.0,20.5]:
		wall_piece(Vector3(x,curtain_top*.5,-1.25),Vector3(38.5,curtain_top,.85),PI/2)
	wall_piece(Vector3(1.25,curtain_top*.5,-20.5),Vector3(38.5,curtain_top,.85))
	gate_wall(curtain_top)
	for i in range(20):
		var p := -17.0+i*1.9
		for z in [-20.5,18.0]: wall_piece(Vector3(p,curtain_top+.5,z),Vector3(.95,1,1))
		var q := -19.5+i*1.9
		for x in [-18.0,20.5]: wall_piece(Vector3(x,curtain_top+.5,q),Vector3(1,1,.95))
	use_solid_masonry = false
	stone_floor(Vector3(0,0,-12.5),Vector2(34,9))
	stone_floor(Vector3(0,GALLERY_Y,-12.5),Vector2(34,9))
	floorboards(Vector3(0,GALLERY_Y+UPPER_CLEAR+.39,-12.5),Vector2(34,9))
	for y in [0.0,GALLERY_Y]:
		var h: float = GALLERY_Y if y==0 else UPPER_CLEAR+.45
		wall(Vector3(0,y,-8),34,h,[-8.8,0.0,6.8,14.5] if y==0 else [-15.4,-8.8,0.0,6.8,14.5],["Kovárna","Kuchyň","Hodovní síň","Průchod do věže"] if y==0 else ["Obranný ochoz","Komnata","Palácová komnata","Hodovní síň","Průchod do věže"])
		for x in [-5.65,5.65]: wall(Vector3(x,y,-12.5),9,h,[0.0],["Spojovací dveře"],PI/2)
		wall_piece(Vector3(0,y+h*.5,-17),Vector3(34,h,.6))
	for x in [-17.0,17.0]: wall_piece(Vector3(x,4.225,-12.5),Vector3(9,8.45,.6),PI/2)
	for x in [-11.325,0.0,11.325]: vaulted_ceiling(Vector3(x,0,-12.5),Vector2(10.7,8.4))
	rooms = [{"name":"Kovárna","rect":Rect2(-17,-17,11.35,9)},{"name":"Kuchyň","rect":Rect2(-5.65,-17,11.3,9)},{"name":"Hodovní síň","rect":Rect2(5.65,-17,11.35,9)}]
	roof(Vector3(0,8.45,-12.5),Vector2(35,10),3,true)
	for x in range(-16,17,2): beam(Vector3(x,8.15,-17.1),Vector3(x,8.15,-7.9),.30,"beam",true,false)
	for x in [-12.0,.5]:
		wall_piece(Vector3(x,9.9,-14),Vector3(.8,3.3,.8))
		box(Vector3(x,11.65,-14),Vector3(1,.25,1),"trim")
	gallery()
	for y in [0.0,GALLERY_Y]:
		var h: float = GALLERY_Y if y==0 else UPPER_CLEAR+.45
		stone_floor(Vector3(12.5,y,8),Vector2(9,14))
		if y==0: wall(Vector3(8,y,8),14,h,[0.0],["Obytné křídlo"],PI/2)
		else: window_wall(Vector3(8,y,8),14,h,[0.0],PI/2)
		wall(Vector3(12.5,y,1),9,h,[2.0],["Dveře do věže"])
		wall_piece(Vector3(17,y+h*.5,8),Vector3(14,h,.6),PI/2)
		if y==0: window_wall(Vector3(12.5,y,15),9,h,[0.0])
		else: wall(Vector3(12.5,y,15),9,h,[2.0],["Přístup na hradby"])
	vaulted_ceiling(Vector3(12.5,0,8),Vector2(8.4,13.4),true)
	floorboards(Vector3(12.5,8.39,8),Vector2(9,14))
	for z in range(2,15,2): beam(Vector3(7.95,8.15,z),Vector3(17.05,8.15,z),.30,"beam",true,false)
	roof(Vector3(12.5,8.45,8),Vector2(10,15),3,false)
	floorboards(Vector3(14.5,GALLERY_Y,15.25),Vector2(2.7,2.1))
	# The solid south facade protects this doorway; no rail crosses its wall.
	rooms.append({"name":"Obytné křídlo","rect":Rect2(8,1,9,14)})
	build_tower()
	defensive_walk()
	building_corners()
	details()
	for key in batches:
		var mesh := batches[key].commit() as ArrayMesh
		mesh.surface_set_material(0,mats[key])
		var instance := MeshInstance3D.new()
		instance.name = "Architecture_"+str(key)
		instance.mesh = mesh
		add_child(instance)
	for key in repeats:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh_cache[key]
		multi.instance_count = repeats[key].size()
		for i in range(repeats[key].size()):
			multi.set_instance_transform(i,repeats[key][i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Relief_"+key
		instance.multimesh = multi
		instance.material_override = mats[key]
		add_child(instance)

	batches.clear()
	repeats.clear()
	mesh_cache.clear()
	preload("res://scripts/blender_kit.gd").cached.clear()
	print("ASSEMBLY complete: ",stone_count," stones; ",roof_cells," roof pieces")

func plain(color: Color, roughness := .9, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func textured(path: String, scale: float, tint: Color, triplanar := true) -> StandardMaterial3D:
	var mat := plain(tint)
	var color_image := (load(path) as Texture2D).get_image()
	if color_image.is_compressed():
		color_image.decompress()
	color_image.resize(1024,1024)
	color_image.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(color_image)
	mat.uv1_triplanar = triplanar
	mat.uv1_world_triplanar = triplanar
	mat.uv1_scale = Vector3.ONE*scale if triplanar else Vector3.ONE
	var normal := color_image.duplicate() as Image
	normal.clear_mipmaps()
	normal.resize(256,256)
	normal.bump_map_to_normal_map(.3)
	normal.generate_mipmaps()
	mat.normal_enabled = true
	mat.normal_texture = ImageTexture.create_from_image(normal)
	mat.normal_scale = .18
	return mat

func mip_texture(path: String, normal_map := false) -> ImageTexture:
	var image := (load(path) as Texture2D).get_image()
	if image.is_compressed(): image.decompress()
	image.clear_mipmaps()
	image.generate_mipmaps(normal_map)
	return ImageTexture.create_from_image(image)

func pbr(asset: String, tint := Color.WHITE) -> StandardMaterial3D:
	var material := plain(tint)
	var prefix := "res://assets/materials/pbr/"+asset
	material.albedo_texture = mip_texture(prefix+"_diff.jpg")
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.normal_enabled = true
	material.normal_texture = mip_texture(prefix+"_normal.jpg",true)
	material.normal_scale = .45
	material.roughness_texture = mip_texture(prefix+"_rough.jpg")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_enabled = true
	material.ao_texture = mip_texture(prefix+"_ao.jpg")
	material.ao_light_affect = .35
	var image := (load(prefix+"_height.jpg") as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	heights[asset] = image
	return material

func make_materials() -> void:
	mats.stone = textured("res://assets/materials/rock.jpg",.9,Color("a49f91"))
	mats.trim = pbr("rock_face_03",Color("d4c4a5"))
	mats.trim.uv1_triplanar = true
	mats.trim.uv1_world_triplanar = true
	mats.trim.uv1_scale = Vector3.ONE*.5
	mats.trim.normal_enabled = false
	mats.rubble = pbr("stone_wall",Color("d9cbb7"))
	mats.paving = pbr("cobblestone_floor_04",Color("a4a69c"))
	mats.roofscan = pbr("roof_planks",Color("8c8880"))
	mats.roofscan.vertex_color_use_as_albedo = true
	mats.roofscan.roughness_texture = null
	mats.roofscan.roughness = .98
	mats.rock3d = pbr("rock_face_03",Color("b8b3a6"))
	mats.rock3d.vertex_color_use_as_albedo = true
	mats.rock3d.uv1_triplanar = false
	mats.rock3d.uv1_world_triplanar = false
	mats.rock3d.uv1_scale = Vector3.ONE
	stone_atlas(mats.rock3d)
	mats.stone_floor = mats.rock3d.duplicate()
	mats.stone_floor.albedo_color = Color("c6bcaa")
	mats.towerstone = mats.rubble.duplicate()
	mats.towerstone.albedo_color = Color("c8b99f")
	mats.rubble_edge = mats.rubble.duplicate()
	mats.rubble_edge.uv1_triplanar = true
	mats.rubble_edge.uv1_world_triplanar = true
	mats.rubble_edge.uv1_scale = Vector3.ONE*.5
	mats.mortar = plain(Color("968b73"))
	mats.vault_stone = mats.rock3d.duplicate()
	mats.vault_stone.vertex_color_use_as_albedo = true
	mats.vault_stone.albedo_color = Color("b8b3a6")
	mats.palace_rock = mats.rock3d.duplicate()
	mats.palace_rock.albedo_color = Color("d4c6ae")
	mats.tower_rock = mats.rock3d.duplicate()
	mats.tower_rock.albedo_color = Color("d0c4af")
	mats.path_rock = mats.rock3d.duplicate()
	mats.path_rock.albedo_color = Color("cdbda2")
	mats.path_rock.uv1_scale = Vector3.ONE
	mats.earth = earth_material()
	mats.clay = plain(Color("a97451"),.94)
	mats.clay.vertex_color_use_as_albedo = true
	mats.plaster = pbr("plastered_wall",Color("e4dccb"))
	mats.plaster.uv1_triplanar = true
	mats.plaster.uv1_world_triplanar = true
	mats.plaster.uv1_scale = Vector3.ONE*.55
	mats.plaster.vertex_color_use_as_albedo = true
	var ends := Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):
			var radius := Vector2(x-58,y-69).length()
			var shade := .84+sin(radius*.62+sin(y*.13)*.2)*.085+float((x*11+y*19)%9)*.008
			ends.set_pixel(x,y,Color("826f51")*shade)
	ends.generate_mipmaps()
	mats.endgrain = plain(Color.WHITE)
	mats.endgrain.albedo_texture = ImageTexture.create_from_image(ends)
	mats.beam = textured("res://assets/materials/timber.jpg",1,Color("8c7b61"),false)
	mats.wood = mats.beam.duplicate()
	mats.wood.albedo_color = Color("b8a58b")
	mats.door = mats.beam.duplicate()
	mats.door.albedo_color = Color("7c6b50")
	mats.iron = plain(Color("303532"),.73,.55)
	mats.grass = plain(Color("5b624d"),1)
	mats.leaves = plain(Color("45553b"),1)
	mats.linen = plain(Color("b8ac8c"),1)
	mats.glass = plain(Color("889c99"),.22,.15)
	mats.glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats.glass.albedo_color.a = .22
	mats.skin = plain(Color("b48763"),.8)
	mats.moss = plain(Color("495541"),1)
	mats.flame = plain(Color("e8a954"))
	mats.flame.emission_enabled = true
	mats.flame.emission = Color("ecb66a")
	mats.tile3 = mats.beam.duplicate()
	mats.tile3.albedo_color = Color("6b6152")

func batch(mesh: Mesh, transform: Transform3D, material_id: String) -> void:
	if mesh.get_surface_count()==0: return
	if mesh_cache.has(material_id) and mesh==mesh_cache[material_id]:
		if not repeats.has(material_id):
			repeats[material_id] = []
		repeats[material_id].append(transform)
		return
	if not batches.has(material_id):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[material_id] = surface
	batches[material_id].append_from(mesh,0,transform)

func collision(transform: Transform3D, size: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.transform = transform
	static_body.add_child(collider)

func box(pos: Vector3, size: Vector3, material_id: String, solid := false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	batch(mesh,Transform3D(Basis.IDENTITY,pos),material_id)
	if solid:
		collision(Transform3D(Basis.IDENTITY,pos),size)

func timber(pos: Vector3, size: Vector3, solid := false, material_id := "beam", along := Vector3.UP, show_ends := true) -> void:
	var basis := Basis(Quaternion(Vector3.UP,along.normalized()))
	var variant := int(absf(pos.x*7+pos.z*11+pos.y*3))%12
	var key := str(size)+"/timber/"+str(variant)
	if not mesh_cache.has(key):
		mesh_cache[key] = Construction.block(size,.012,true,Vector2(variant*.17,variant*.13),0.0,variant)
	batch(mesh_cache[key],Transform3D(basis,pos),material_id)
	if show_ends and material_id in ["wood","beam","door"]:
		var cap_key := key+"/ends"
		if not mesh_cache.has(cap_key):
			var cap := SurfaceTool.new()
			cap.begin(Mesh.PRIMITIVE_TRIANGLES)
			for side in [-1,1]:
				var x := size.x*.43
				var z := size.z*.43
				var y: float = side*(size.y*.5+.001)
				Construction.quad(cap,[Vector3(-x,y,-z),Vector3(x,y,-z),Vector3(x,y,z),Vector3(-x,y,z)],Vector3.UP*side)
			cap.index()
			mesh_cache[cap_key] = cap.commit()
		batch(mesh_cache[cap_key],Transform3D(basis,pos),"endgrain")
	if solid:
		collision(Transform3D(basis,pos),size)

func beam(a: Vector3, b: Vector3, thickness: float, material_id := "beam", solid := false, show_ends := true) -> void:
	timber((a+b)*.5,Vector3(thickness,a.distance_to(b),thickness),solid,material_id,b-a,show_ends)

func roof_beam(a: Vector3, b: Vector3, thickness: float, material_id := "beam") -> void:
	for part in RoofClip.beam_parts(a,b): beam(part[0],part[1],thickness,material_id,false,false)

func building_corners() -> void:
	# Interlocking quoins cover the entire corner thickness, including plaster returns.
	var corners := [Vector3(-17,0,-17),Vector3(17,0,-17),Vector3(-17,0,-8),Vector3(8,0,1),Vector3(17,0,15),Vector3(8,0,15),Vector3(8,0,-8),Vector3(17,0,-8),Vector3(17,0,1)]
	for corner in corners:
		var height := 17.30 if corner.z in [-8.0,1.0] and corner.x>=8 else 8.45
		var rows := int(ceil(height/.43))
		for row in range(rows):
			var h := height/rows
			var size := Vector3(.84 if row%2==0 else .78,h-.013,.78 if row%2==0 else .84)
			batch(Construction.block(size,.016,false,Vector2.ZERO,0.0,row),Transform3D(Basis.IDENTITY,corner+Vector3.UP*((row+.5)*h)),"trim")

func barrel_height(offset: float, span: float) -> float:
	var half := span*.5
	var rise := minf(1.4,half*.8)
	var radius := (half*half+rise*rise)/(2*rise)
	return 4.5-radius+sqrt(maxf(0,radius*radius-offset*offset))

func corridor_corner() -> void:
	# A groin vault shares the exact arch profiles of both perpendicular barrels.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 14
	for x in range(count):
		for z in range(count):
			var points: Array = []
			for corner in [Vector2(x,z),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:
				var px: float = 17.3+corner.x*2.8/count
				var pz: float = -20.1+corner.y*2.8/count
				points.append(Vector3(px,maxf(barrel_height(px-18.7,2.8),barrel_height(pz+18.7,2.8)),pz))
			var normal: Vector3 = (points[1]-points[0]).cross(points[3]-points[0]).normalized()
			if normal.y>0: normal = -normal
			surface.set_color(Color(.92,.91,.90))
			var phase := Vector2(((x*7+z*3)%2)*.5,((x+z*5)%4/2)*.5)+Vector2(.03,.03)
			Construction.quad(surface,points,normal,Vector2(.32,.32),phase)
			var top: Array = []
			for point in points: top.append(point+Vector3.UP*.20)
			Construction.quad(surface,top,-normal,Vector2(.32,.32),phase)
	surface.index()
	var mesh := surface.commit()
	batch(mesh,Transform3D.IDENTITY,"vault_stone")
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	static_body.add_child(collider)

func vault_portal(center: Vector3, span: float, angle: float) -> void:
	var basis := Basis(Vector3.UP,angle)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(18):
		var a := -span*.5+i*span/18
		var b := -span*.5+(i+1)*span/18
		var ya := barrel_height(a,span)
		var yb := barrel_height(b,span)
		for side in [-1,1]:
			var normal := basis*Vector3(0,0,side)
			var points := [Vector3(a,ya,side*.16),Vector3(b,yb,side*.16),Vector3(b,4.75,side*.16),Vector3(a,4.75,side*.16)]
			for j in range(4): points[j] = center+basis*points[j]
			surface.set_color(Color(.94,.93,.91))
			Construction.quad(surface,points,normal,Vector2(.22,.32),Vector2((i%2)*.5+.04,.04))
		var reveal := [Vector3(a,ya,-.16),Vector3(b,yb,-.16),Vector3(b,yb,.16),Vector3(a,ya,.16)]
		for j in range(4): reveal[j] = center+basis*reveal[j]
		Construction.quad(surface,reveal,Vector3.DOWN,Vector2(.22,.25),Vector2((i%2)*.5+.04,.04))
	surface.index()
	batch(surface.commit(),Transform3D.IDENTITY,"vault_stone")

func attic_roof() -> void:
	var base := 17.30
	# Raised knee walls permit standing along the attic access route.
	for x in [8.0,17.0]: wall_piece(Vector3(x,15.96,-3.5),Vector3(9,2.68,.6),PI/2)
	for z in [-8.0,1.0]: wall_piece(Vector3(12.5,15.96,z),Vector3(9,2.68,.6))
	hip_roof(Vector3(12.5,base,-3.5),Vector2(10,10),4.5)
	var peak := Vector3(12.5,base+4.32,-3.5)
	var plate := base+.54
	attic_wall_closure(base)
	# Common and jack rafters end at the hip rafters, rather than all meeting the peak.
	for z in [-7.7,.7]: beam(Vector3(8.25,plate,z),Vector3(16.75,plate,z),.28,"beam",true,false)
	for x in [8.3,16.7]: beam(Vector3(x,plate,-7.7),Vector3(x,plate,.7),.28,"beam",true,false)
	for x in [8.3,16.7]:
		for z in [-7.7,.7]: beam(Vector3(x,plate,z),peak,.24,"beam",true,false)
	for t in range(1,8):
		var q := 8.3+t*1.05
		var distance := absf(q-12.5)
		for side in [-1,1]:
			beam(Vector3(q,plate,-3.5+side*4.2),Vector3(q,peak.y-distance*.9,-3.5+side*distance),.18,"beam",true,false)
		var qz := -7.7+t*1.05
		var distance_z := absf(qz+3.5)
		for side in [-1,1]:
			beam(Vector3(12.5+side*4.2,plate,qz),Vector3(12.5+side*distance_z,peak.y-distance_z*.9,qz),.18,"beam",true,false)
	for z in [-6.65,-3.5,-.35]:
		beam(Vector3(8.35,base-.02,z),Vector3(16.65,base-.02,z),.28,"beam",true,false)
		if z==-3.5:
			beam(Vector3(12.5,base,z),peak,.24,"beam",true,false)
			for x in [9.1,15.9]:
				beam(Vector3(x,base,z),Vector3(10.3 if x<12.5 else 14.7,base+2.25,z),.18,"beam",true,false)
	# Purlins tie neighbouring rafters together above head height.
	for x in [10.3,14.7]: beam(Vector3(x,base+2.25,-5.7),Vector3(x,base+2.25,-1.3),.22,"beam",true,false)
	for z in [-5.7,-1.3]: beam(Vector3(10.3,base+2.25,z),Vector3(14.7,base+2.25,z),.22,"beam",true,false)
	rail(Vector3(11.55,ATTIC_Y,-7.65),Vector3(11.55,ATTIC_Y,-1.2))
	var light := OmniLight3D.new()
	light.position = Vector3(13,ATTIC_Y+2,-3.5)
	light.light_energy = .55
	light.omni_range = 12
	add_child(light)

func attic_wall_closure(base: float) -> void:
	# Wedge-shaped wall caps follow the underside of the hip roof, including corners.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rect in [Rect2(7.7,-8.3,.6,9.6),Rect2(16.7,-8.3,.6,9.6),Rect2(8.3,-8.3,8.4,.6),Rect2(8.3,.7,8.4,.6)]:
		var p: Array = []
		for offset in [Vector2.ZERO,Vector2(rect.size.x,0),rect.size,Vector2(0,rect.size.y)]:
			var q: Vector2 = rect.position+offset
			p.append(Vector3(q.x,base-.02,q.y))
		for i in range(4):
			var point: Vector3 = p[i]
			point.y = base+4.5*(1-maxf(absf(point.x-12.5),absf(point.z+3.5))/5.0)-.07
			p.append(point)
		for side in range(4):
			var next := (side+1)%4
			var normal: Vector3 = (p[next]-p[side]).cross(Vector3.UP).normalized()
			Construction.quad(surface,[p[side],p[next],p[next+4],p[side+4]],normal)
		Construction.quad(surface,[p[4],p[5],p[6],p[7]],Vector3.UP)
	surface.index()
	var mesh := surface.commit()
	batch(mesh,Transform3D.IDENTITY,"trim")
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	static_body.add_child(collider)

func cylinder(pos: Vector3, top: float, bottom: float, height: float, material_id: String, sides := 12) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	batch(mesh,Transform3D(Basis.IDENTITY,pos),material_id)

func floorboards(pos: Vector3, size: Vector2, across_x := false) -> void:
	if across_x:
		floor_patches.append({"pos":pos,"size":size})
		collision(Transform3D(Basis.IDENTITY,pos-Vector3(0,.07,0)),Vector3(size.x,.14,size.y))
		var count_x := int(ceil(size.y/.3))
		for i in range(count_x):
			timber(pos+Vector3(0,-.045,-size.y*.5+(i+.5)*size.y/count_x),Vector3(.09,size.x-.012,size.y/count_x-.009),false,"wood",Vector3.RIGHT)
		return
	floor_patches.append({"pos":pos,"size":size})
	collision(Transform3D(Basis.IDENTITY,pos-Vector3(0,.07,0)),Vector3(size.x,.14,size.y))
	var count := int(ceil(size.x/.3))
	var width := size.x/count
	for i in range(count):
		var x := pos.x-size.x/2+(i+.5)*width
		var sections := int(ceil(size.y/3.8))
		for j in range(sections):
			var length := size.y/sections
			timber(Vector3(x,pos.y-.045,pos.z-size.y/2+(j+.5)*length),Vector3(width-.009,length-.012,.09),false,"wood",Vector3.FORWARD)

func stone_atlas(material: StandardMaterial3D) -> void:
	# Surface detail comes from rock faces or the interior of ONE scanned stone.
	# Never paint a complete wall with its miniature mortar joints on a voussoir.
	var patches := [Rect2i(5,5,280,280),Rect2i(650,350,300,300),Rect2i(500,470,70,40),Rect2i(510,480,50,30)]
	for channel in ["diff","normal","rough","ao"]:
		var atlas := Image.create(1024,1024,false,Image.FORMAT_RGB8)
		for i in range(4):
			var asset := "rock_face_03" if i<2 else "stone_wall"
			var image := (load("res://assets/materials/pbr/"+asset+"_"+channel+".jpg") as Texture2D).get_image()
			if image.is_compressed(): image.decompress()
			image.clear_mipmaps()
			image.convert(Image.FORMAT_RGB8)
			var patch := image.get_region(patches[i])
			if channel=="diff":
				var mean := Vector3.ZERO
				for py in range(patch.get_height()):
					for px in range(patch.get_width()):
						var c := patch.get_pixel(px,py)
						mean += Vector3(c.r,c.g,c.b)
				mean /= patch.get_width()*patch.get_height()
				var target := Vector3(.51,.49,.44)*(1.0+float(i-1)*.014)
				for py in range(patch.get_height()):
					for px in range(patch.get_width()):
						var c := patch.get_pixel(px,py)
						patch.set_pixel(px,py,Color(c.r*target.x/mean.x,c.g*target.y/mean.y,c.b*target.z/mean.z))
			patch.resize(512,512)
			atlas.blit_rect(patch,Rect2i(0,0,512,512),Vector2i((i%2)*512,(i/2)*512))
		atlas.generate_mipmaps(channel=="normal")
		var texture := ImageTexture.create_from_image(atlas)
		if channel=="diff": material.albedo_texture = texture
		elif channel=="normal": material.normal_texture = texture
		elif channel=="rough": material.roughness_texture = texture
		else: material.ao_texture = texture

func earth_material() -> StandardMaterial3D:
	var image := Image.create(512,512,false,Image.FORMAT_RGB8)
	var rough := Image.create(512,512,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 1437
	noise.frequency = .32
	noise.fractal_octaves = 4
	for y in range(512):
		for x in range(512):
			var p := Vector2(x/511.0*36-18,y/511.0*36-18)
			var broad := noise.get_noise_2d(p.x,p.y)
			var fine := noise.get_noise_2d(p.x*23,p.y*23)
			var damp := clampf((broad+.12)*1.7,0,1)
			var color := Color("786b54").lerp(Color("514b3e"),damp)*(.94+fine*.16)
			if p.x < -14.3 and not Masonry.yard_path(Vector3(p.x,0,p.y)):
				color = color.lerp(Color("596047"),clampf(broad+.4,0,.5))
			image.set_pixel(x,y,color)
			rough.set_pixel(x,y,Color.WHITE*(.93-.18*damp))
	var normal := image.duplicate() as Image
	normal.bump_map_to_normal_map(.3)
	image.generate_mipmaps()
	rough.generate_mipmaps()
	normal.generate_mipmaps(true)
	var mat := plain(Color.WHITE)
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.roughness_texture = ImageTexture.create_from_image(rough)
	mat.normal_enabled = true
	mat.normal_texture = ImageTexture.create_from_image(normal)
	mat.normal_scale = .20
	return mat

func yard_surface() -> void:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	Construction.quad(s,[Vector3(-18,.002,-18),Vector3(18,.002,-18),Vector3(18,.002,18),Vector3(-18,.002,18)],Vector3.UP)
	s.index()
	batch(s.commit(),Transform3D.IDENTITY,"earth")
	mats.water = plain(Color("555548"),.23,0)
	mats.water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats.water.vertex_color_use_as_albedo = true
	mats.water.normal_enabled = true
	mats.water.normal_texture = mats.earth.normal_texture
	mats.water.normal_scale = .04
	for puddle in [Vector4(-11,8.2,1.25,.70),Vector4(-15.4,2.8,.85,.48),Vector4(4.6,12.6,.72,.45)]:
		var pool := SurfaceTool.new()
		pool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var center := Vector3(puddle.x,.006,puddle.y)
		for i in range(18):
			var a := i*TAU/18
			var b := (i+1)*TAU/18
			var pa := center+Vector3(cos(a)*puddle.z,0,sin(a)*puddle.w)*(1+.17*sin(a*3)+.07*cos(a*7))
			var pb := center+Vector3(cos(b)*puddle.z,0,sin(b)*puddle.w)*(1+.17*sin(b*3)+.07*cos(b*7))
			for vertex in [center,pb,pa]:
				pool.set_normal(Vector3.UP)
				pool.set_uv(Vector2(vertex.x,vertex.z)*.3)
				pool.set_color(Color(1,1,1,.85 if vertex==center else .0))
				pool.add_vertex(vertex)
		pool.index()
		batch(pool.commit(),Transform3D.IDENTITY,"water")

func courtyard() -> void:
	yard_surface()
	# Continuous flat collision is retained; visible stones only rise a few centimetres.
	var relief := Masonry.face(Vector3(-18,.009,-18),Vector3.RIGHT,Vector3.BACK,Vector3.UP,Vector2(36,36),1403,"path",true)
	batch(relief.mesh,Transform3D.IDENTITY,"path_rock")
	stone_count += relief.stones
	relief_cells += relief.stones*6
	# Small vegetation is confined to sheltered wall margins, outside doors and stairs.
	for i in range(180):
		var pos := Vector3(rng.randf_range(-16.8,7.3),.008,rng.randf_range(-3.5,13.5))
		if Masonry.yard_path(pos) or (pos.x>-14.4 and pos.x<5.5): continue
		for j in range(5):
			var stem := pos+Vector3(rng.randf_range(-.07,.07),0,rng.randf_range(-.07,.07))
			var lean := Vector3(rng.randf_range(-.045,.045),rng.randf_range(.04,.13),rng.randf_range(-.045,.045))
			beam(stem,stem+lean,.007,"moss")


func stone_floor(pos: Vector3, size: Vector2) -> void:
	floor_patches.append({"pos":pos,"size":size})
	box(pos-Vector3(0,.13,0),Vector3(size.x,.26,size.y),"mortar",true)
	if pos.y>1:
		var underside := Masonry.face(pos-Vector3(size.x*.5,.261,size.y*.5),Vector3.RIGHT,Vector3.BACK,Vector3.DOWN,size,int(absf(pos.x*173+pos.z*317))+1439,"floor",true)
		batch(underside.mesh,Transform3D.IDENTITY,"vault_stone")
	var surface := Masonry.face(pos-Vector3(size.x*.5,-.004,size.y*.5),Vector3.RIGHT,Vector3.BACK,Vector3.UP,size,int(absf(pos.x*171+pos.y*557+pos.z*313))+1403,"floor",true)
	batch(surface.mesh,Transform3D.IDENTITY,"stone_floor")
	stone_count += surface.stones
	relief_cells += surface.stones*6

func wall_piece(pos: Vector3, size: Vector3, angle := 0.0) -> void:
	var basis := Basis(Vector3.UP,angle)
	var mesh := BoxMesh.new()
	mesh.size = size
	batch(mesh,Transform3D(basis,pos),"mortar")
	collision(Transform3D(basis,pos),size)
	var style := "curtain" if use_solid_masonry else ("tower" if pos.x>7.5 and pos.z<1.1 else "palace")
	var material_id := "rock3d" if style=="curtain" else ("tower_rock" if style=="tower" else "palace_rock")
	var x := size.x*.5
	var y := size.y*.5
	var z := size.z*.5
	var faces := [
		[Vector3(-x,-y,z),Vector3.RIGHT,Vector3.UP,Vector3.BACK,Vector2(size.x,size.y)],
		[Vector3(-x,-y,-z),Vector3.RIGHT,Vector3.UP,Vector3.FORWARD,Vector2(size.x,size.y)],
		[Vector3(x,-y,-z),Vector3.BACK,Vector3.UP,Vector3.RIGHT,Vector2(size.z,size.y)],
		[Vector3(-x,-y,-z),Vector3.BACK,Vector3.UP,Vector3.LEFT,Vector2(size.z,size.y)],
		[Vector3(-x,y,-z),Vector3.RIGHT,Vector3.BACK,Vector3.UP,Vector2(size.x,size.z)]]
	for i in range(faces.size()):
		# Closed return faces prevent exposed grey strips at building corners.
		var f: Array = faces[i]
		var origin: Vector3 = pos+basis*f[0]
		var sample: Vector3 = origin+basis*f[1]*f[4].x*.5+basis*f[3]*.12
		var inside := (sample.z>-16.75 and sample.z< -8.25 and absf(sample.x)<16.75) or (sample.x>8.25 and sample.x<16.75 and sample.z>1.25 and sample.z<14.75)
		var rear := sample.z< -17.2 or sample.x>17.2
		var min_y := 5.0 if (inside or rear) and style=="palace" else -100.0
		if wall_finish_override=="plaster": min_y = -100.0
		var covered := style!="curtain" or wall_finish_override=="plaster"
		var interior := inside or wall_finish_override=="plaster"
		var stone := Masonry.face(origin,basis*f[1],basis*f[2],basis*f[3],f[4],int(absf(pos.x*131+pos.z*193+pos.y*557))+i*47+1403,style,false,covered,interior,min_y)
		batch(stone.mesh,Transform3D.IDENTITY,material_id)
		stone_count += stone.stones
		relief_cells += stone.stones*6
		if covered:
			var lime := Masonry.plaster(origin+basis*f[3]*.065,basis*f[1],basis*f[2],basis*f[3],f[4],interior,min_y)
			if lime.get_surface_count()>0: batch(lime,Transform3D.IDENTITY,"plaster")

func wall(pos: Vector3, width: float, height: float, centers: Array, titles: Array, angle := 0.0) -> void:
	var basis := Basis(Vector3.UP,angle)
	var start := -width/2
	var half_open := .65
	var opening_height := 2.16
	for i in range(centers.size()):
		var center: float = centers[i]
		var edge := center-half_open-.22
		if edge>start: wall_piece(pos+basis*Vector3((start+edge)*.5,height*.5,0),Vector3(edge-start,height,.55),angle)
		wall_piece(pos+basis*Vector3(center,(height+opening_height+.24)*.5,0),Vector3(half_open*2+.44,height-opening_height-.24,.55),angle)
		for side in [-1,1]:
			for j in range(5):
				var stone := Construction.block(Vector3(.22,opening_height/5-.016,.74),.025)
				batch(stone,Transform3D(basis,pos+basis*Vector3(center+side*(half_open+.11),(j+.5)*opening_height/5,0)),"trim")
		batch(Construction.block(Vector3(1.74,.24,.76),.03),Transform3D(basis,pos+basis*Vector3(center,2.28,0)),"trim")
		var door := Door.new()
		door.width = 1.10
		door.height = 2.10
		door.position = pos+basis*Vector3(center,0,0)
		door.rotation.y = angle
		add_child(door)
		door.configure(mats.door,mats.iron,titles[i])
		if titles[i] in ["Přístup na hradby","Východní hradby"]: door.opening_side = -1.0
		elif titles[i]=="Obranný ochoz" or str(titles[i]).begins_with("Pokoj věže"):
			door.opening_side = 1.0
		if str(titles[i]).begins_with("Pokoj věže"): tower_room_doors.append(door)
		doors.append(door)
		for side in [-1,1]: collision(Transform3D(basis,pos+basis*Vector3(center+side*(half_open+.11),opening_height*.5,0)),Vector3(.22,opening_height,.55))
		start = center+half_open+.22
	if start<width/2: wall_piece(pos+basis*Vector3((start+width/2)*.5,height*.5,0),Vector3(width/2-start,height,.55),angle)

func window_wall(pos: Vector3, width: float, height: float, centers: Array, angle := 0.0) -> void:
	var basis := Basis(Vector3.UP,angle)
	var start := -width/2
	for value in centers:
		var center: float = value
		var edge := center-.66
		if edge>start:
			wall_piece(pos+basis*Vector3((start+edge)*.5,height*.5,0),Vector3(edge-start,height,.6),angle)
		wall_piece(pos+basis*Vector3(center,.66,0),Vector3(1.32,1.32,.6),angle)
		wall_piece(pos+basis*Vector3(center,(height+2.62)*.5,0),Vector3(1.32,height-2.62,.6),angle)
		window_detail(pos+basis*Vector3(center,1.97,0),angle)
		start = center+.66
	if start<width/2:
		wall_piece(pos+basis*Vector3((start+width/2)*.5,height*.5,0),Vector3(width/2-start,height,.6),angle)

func window_detail(pos: Vector3, angle: float) -> void:
	windows.append(pos)
	var basis := Basis(Vector3.UP,angle)
	for side in [-1,1]:
		var trim := Construction.block(Vector3(.16,1.54,.8),.025)
		batch(trim,Transform3D(basis,pos+basis*Vector3(side*.71,0,0)),"trim")
	for y in [-.72,.72]:
		var trim := Construction.block(Vector3(1.56,.17,.82),.025)
		batch(trim,Transform3D(basis,pos+basis*Vector3(0,y,0)),"trim")
	var pane := BoxMesh.new()
	pane.size = Vector3(1.26,1.27,.025)
	batch(pane,Transform3D(basis,pos),"glass")
	# Glass opening has a sill collision, not a tall empty doorway.
	collision(Transform3D(basis,pos),Vector3(1.32,1.32,.03))
	for x in [-.59,0,.59]:
		var bar := Construction.block(Vector3(.055,1.28,.055),.006,true)
		batch(bar,Transform3D(basis,pos+basis*Vector3(x,0,.025)),"beam")
	for y in [-.6,0,.6]:
		var bar := BoxMesh.new()
		bar.size = Vector3(1.27,.06,.06)
		batch(bar,Transform3D(basis,pos+basis*Vector3(0,y,.025)),"beam")
	for side in [-1,1]:
		var shutter := Construction.block(Vector3(.55,1.25,.055),.012,true)
		batch(shutter,Transform3D(basis*Basis(Vector3.UP,side*.13),pos+basis*Vector3(side*1.05,0,.40)),"door")

func tiled_plane(origin: Vector3, across: Vector3, slope: Vector3, wooden := false) -> void:
	var a := across
	var start := origin
	var normal := slope.cross(a).normalized()
	if normal.y<0:
		start += a
		a = -a
		normal = -normal
	roof_normals.append(normal)
	var relief := Shingles.make(start,a.normalized(),slope.normalized(),normal,Vector2(a.length(),slope.length()),false,not wooden)
	batch(RoofClip.outside(relief.mesh),Transform3D.IDENTITY,"roofscan" if wooden else "clay")
	roof_cells += relief.count
	var underside := SurfaceTool.new()
	underside.begin(Mesh.PRIMITIVE_TRIANGLES)
	Construction.quad(underside,[start-normal*.055,start+a-normal*.055,start+a+slope-normal*.055,start+slope-normal*.055],-normal,Vector2(a.length()*.5,slope.length()*.5))
	underside.index()
	batch(RoofClip.outside(underside.commit()),Transform3D.IDENTITY,"wood")
	var columns := int(ceil(a.length()/.37))
	roof_beam(start,start+a,.19)
	for column in range(0,columns,5):
		var p := start+a.normalized()*(column*a.length()/columns)-normal*.1
		roof_beam(p,p+slope,.12)

func roof(pos: Vector3, size: Vector2, rise: float, along_x: bool) -> void:
	var w := size.x/2
	var d := size.y/2
	if along_x:
		tiled_plane(pos+Vector3(-w,0,-d),Vector3(size.x,0,0),Vector3(0,rise,d))
		tiled_plane(pos+Vector3(-w,0,d),Vector3(size.x,0,0),Vector3(0,rise,-d))
		for x in [-w,w]:
			gable([pos+Vector3(x,0,-d),pos+Vector3(x,rise,0),pos+Vector3(x,0,d)],Vector3(signf(x),0,0))
		roof_beam(pos+Vector3(-w,rise+.07,0),pos+Vector3(w,rise+.07,0),.17,"tile3")
	else:
		tiled_plane(pos+Vector3(-w,0,-d),Vector3(0,0,size.y),Vector3(w,rise,0))
		tiled_plane(pos+Vector3(w,0,-d),Vector3(0,0,size.y),Vector3(-w,rise,0))
		for z in [-d,d]:
			gable([pos+Vector3(-w,0,z),pos+Vector3(0,rise,z),pos+Vector3(w,0,z)],Vector3(0,0,signf(z)))
		roof_beam(pos+Vector3(0,rise+.07,-d),pos+Vector3(0,rise+.07,d),.17,"tile3")

func hip_roof(pos: Vector3, size: Vector2, rise: float) -> void:
	var w := size.x*.5
	var d := size.y*.5
	var corners := [Vector3(-w,0,-d),Vector3(-w,0,d),Vector3(w,0,d),Vector3(w,0,-d)]
	var peak := pos+Vector3(0,rise,0)
	for i in range(4):
		var a: Vector3 = pos+corners[i]
		var b: Vector3 = pos+corners[(i+1)%4]
		var u := (b-a).normalized()
		var climb := peak-(a+b)*.5
		var v := climb.normalized()
		var normal := u.cross(v).normalized()
		roof_normals.append(normal)
		var relief := Shingles.make(a,u,v,normal,Vector2(a.distance_to(b),climb.length()),true,true)
		batch(relief.mesh,Transform3D.IDENTITY,"clay")
		roof_cells += relief.count
		var lining := SurfaceTool.new()
		lining.begin(Mesh.PRIMITIVE_TRIANGLES)
		Masonry.triangle(lining,a-normal*.07,b-normal*.07,peak-normal*.07,[Vector2.ZERO,Vector2(a.distance_to(b)*.5,0),Vector2(a.distance_to(b)*.25,climb.length()*.5)],-normal,Color.WHITE)
		lining.index()
		batch(lining.commit(),Transform3D.IDENTITY,"wood")
		beam(a,b,.19)
		beam(a+Vector3.UP*.04,peak+Vector3.UP*.04,.12,"tile3")

func gable(points: Array, normal: Vector3) -> void:
	var base: Vector3 = points[0]
	var axis: Vector3 = (points[2]-base).normalized()
	var width := base.distance_to(points[2])
	var rise: float = points[1].y-base.y
	var core := SurfaceTool.new()
	core.begin(Mesh.PRIMITIVE_TRIANGLES)
	Masonry.triangle(core,points[0],points[1],points[2],[Vector2.ZERO,Vector2(width*.5,rise),Vector2(width,0)],normal,Color.WHITE)
	core.index()
	batch(RoofClip.outside(core.commit()),Transform3D.IDENTITY,"mortar")
	var relief := Masonry.face(base,axis,Vector3.UP,normal,Vector2(width,rise),int(absf(base.x*713+base.z*193)),"palace",false,false,false,-100.0,true)
	batch(RoofClip.outside(relief.mesh),Transform3D.IDENTITY,"palace_rock")
	stone_count += relief.stones

func rail(a: Vector3, b: Vector3, opening := false) -> void:
	if a.distance_to(b)<.01: return
	rail_routes.append({"a":a,"b":b})
	var count := maxi(1,int(ceil(a.distance_to(b)/.32)))
	var direction := (b-a).normalized()
	# Handrails slightly overlap at shared corners; posts terminate inside the rail.
	beam(a+Vector3(0,1.02,0)-direction*.07,b+Vector3(0,1.02,0)+direction*.07,.14,"beam",false,false)
	beam(a+Vector3(0,.18,0),b+Vector3(0,.18,0),.09,"beam",false,false)
	for i in range(count+1):
		var p := a.lerp(b,float(i)/count)
		var key := str(p.snapped(Vector3.ONE*.005))
		if rail_posts.has(key): continue
		rail_posts[key] = true
		beam(p-Vector3.UP*.04,p+Vector3.UP*1.00,.14 if i==0 or i==count or i%6==0 else .065,"beam",false,false)
	# A continuous guard box has no overlapping panel corners to catch the capsule.
	var flat := Vector3(direction.x,0,direction.z).normalized()
	var basis := Basis(flat,Vector3.UP,flat.cross(Vector3.UP))
	if absf(a.y-b.y)<.01:
		collision(Transform3D(basis,(a+b)*.5+Vector3.UP*.52),Vector3(Vector2(b.x-a.x,b.z-a.z).length(),1.04,.10))
	else:
		for i in range(count):
			var p := a.lerp(b,(i+.5)/count)+Vector3.UP*.52
			collision(Transform3D(basis,p),Vector3(Vector2(b.x-a.x,b.z-a.z).length()/count,1.04,.10))

func flight(first: Vector3, direction: Vector3, count: int, rise: float, run: float, width: float, guard_sides: Array = [-1,1]) -> Vector3:
	var across := Vector3(direction.z,0,-direction.x)
	for i in range(count):
		var top := first+direction*(i*run)+Vector3(0,(i+1)*rise,0)
		# The tread grain follows the plank across the staircase.
		var size := Vector3(run+.015,width,.11)
		var basis := Basis(direction,across,Vector3.UP)
		var key := str(size)+"/tread"
		if not mesh_cache.has(key):
			mesh_cache[key] = Construction.block(size,.012,true)
		var transform := Transform3D(basis,top-Vector3(0,.055,0))
		batch(mesh_cache[key],transform,"wood")
		collision(transform,size)
	var last := first+direction*((count-1)*run)+Vector3(0,count*rise,0)
	for side in [-1,1]:
		beam(first+across*side*(width/2-.10)-Vector3(0,.12,0),last+across*side*(width/2-.10)-Vector3(0,.16,0),.15)
		if side not in guard_sides: continue
		rail(first+across*side*(width/2-.01),last+across*side*(width/2-.01),true)
	return last

func gallery() -> void:
	var y := GALLERY_Y
	floorboards(Vector3(-4.75,y,-6.5),Vector2(25.5,3))
	for x in [-17.3,-14.0,-11.0,-8.0,-5.0,-2.0,1.0,4.0,8.0]:
		beam(Vector3(x,0,-5),Vector3(x,y+3.0,-5),.30,"beam",true)
		beam(Vector3(x,y+2.1,-5),Vector3(x,y+3.0,-6.5),.20,"beam",false,false)
		beam(Vector3(x,y-1.1,-5),Vector3(x,y-.46,-6.4),.24,"beam",false,false)
	beam(Vector3(-17.5,y-.19,-5.05),Vector3(8.15,y-.19,-5.05),.30,"beam",false,false)
	beam(Vector3(-17.5,y-.19,-7.85),Vector3(8.15,y-.19,-7.85),.30,"beam",false,false)
	for i in range(22):
		var x: float = -17.35+i*1.2
		beam(Vector3(x,y-.49,-8.15),Vector3(x,y-.49,-4.80),.30)
	flight(Vector3(-5.44,0,-4.1),Vector3.LEFT,25,.20,.32,1.6)
	floorboards(Vector3(-14.4,y,-4.1),Vector2(3.04,1.95))
	rail(Vector3(-15.65,y,-3.31),Vector3(-13.12,y,-3.31))
	rail(Vector3(-13.12,y,-4.89),Vector3(-13.12,y,-5))
	rail(Vector3(-13.12,y,-5),Vector3(6.06,y,-5))
	stair_routes.append({"start":Vector3(-4.79,.08,-4.1),"mid":Vector3(-9.28,2.7,-4.1),"turn":Vector3(-13.7,y+.1,-4.1),"end":Vector3(-14.7,y+.1,-4.1),"exit":Vector3(-14.7,y+.1,-6.4)})
	flight(Vector3(6.85,0,3.76),Vector3.FORWARD,25,.20,.32,1.6,[1])
	floorboards(Vector3(6.8,y,-4.95),Vector2(2.4,2.1))
	rail(Vector3(6.06,y,-5),Vector3(6.06,y,-3.92))
	stair_routes.append({"start":Vector3(6.85,.08,4.41),"mid":Vector3(6.85,2.7,-.08),"turn":Vector3(6.85,y+.1,-4.4),"end":Vector3(6.85,y+.1,-4.8),"exit":Vector3(6.85,y+.1,-6.5)})
	tiled_plane(Vector3(-17.6,y+3.4,-8.3),Vector3(26,0,0),Vector3(0,-.70,4.95),true)
	tiled_plane(Vector3(8.15,y+3.4,-6.2),Vector3(0,0,10.8),Vector3(-2.80,-.90,0),true)
	roof_beam(Vector3(8.15,y+3.22,-6.2),Vector3(8.15,y+3.22,4.6),.28)
	beam(Vector3(5.55,y+2.38,-6.2),Vector3(5.55,y+2.38,4.6),.28,"beam",false,false)
	for z in [-5.8,-.5,4.0]:
		beam(Vector3(5.55,0,z),Vector3(5.55,y+2.5,z),.28,"beam",true)
		beam(Vector3(5.55,y+1.75,z),Vector3(6.35,y+2.63,z),.20,"beam",false,false)
	for z in [-4.85,-3.45]: beam(Vector3(-16.15,y-.19,z),Vector3(-12.9,y-.19,z),.28,"beam",false,false)
	for x in [6.15,7.65]: beam(Vector3(x,y-.19,-6.2),Vector3(x,y-.19,-3.85),.28,"beam",false,false)

func defensive_walk() -> void:
	var y := GALLERY_Y
	floorboards(Vector3(-16.6,y,4.6),Vector2(1.8,24.2),true)
	floorboards(Vector3(-.05,y,16.6),Vector2(34.9,1.8))
	rail(Vector3(-15.65,y,-3.31),Vector3(-15.65,y,13.85))
	rail(Vector3(-15.65,y,13.85),Vector3(-15.415,y,14.24))
	rail(Vector3(-13.785,y,15.65),Vector3(7.65,y,15.65))
	# No guard against the solid east-wing facade.
	# Cross beams sit below the longitudinal bearers; struts seat in their underside.
	for z in range(-4,17,3):
		beam(Vector3(-17.90,y-.49,z),Vector3(-15.50,y-.49,z),.30)
		beam(Vector3(-17.90,y-1.7,z),Vector3(-15.80,y-.57,z),.30,"beam",false,false)
	for x in [-16.0,-13.0,-10.0,-7.0,-4.7,4.7,7.0,10.0,13.0,16.0]:
		beam(Vector3(x,y-.49,17.90),Vector3(x,y-.49,15.50),.30)
		beam(Vector3(x,y-1.7,17.90),Vector3(x,y-.57,15.80),.30,"beam",false,false)
	for x in [-17.2,-15.9]: beam(Vector3(x,y-.19,-7.5),Vector3(x,y-.19,17.3),.30,"beam",false,false)
	for z in [16.0,17.2]: beam(Vector3(-17.5,y-.19,z),Vector3(17.3,y-.19,z),.30,"beam",false,false)
	flight(Vector3(-14.6,0,6.56),Vector3.BACK,25,.20,.32,1.65)
	floorboards(Vector3(-15.55,y,15.05),Vector2(3.90,1.9),true)
	rail(Vector3(-13.785,y,14.24),Vector3(-13.785,y,15.65))
	for x in [-15.3,-13.8]: beam(Vector3(x,y-.19,14.1),Vector3(x,y-.19,16.3),.30,"beam",false,false)
	stair_routes.append({"start":Vector3(-14.6,.08,5.91),"mid":Vector3(-14.6,2.7,10.40),"turn":Vector3(-14.6,y+.1,15.05),"end":Vector3(-16.5,y+.1,15.05),"exit":Vector3(-16.5,y+.1,16.6)})
	stone_floor(Vector3(18.75,y,-.25),Vector2(2.7,36.5))
	stone_floor(Vector3(1.275,y,-18.70),Vector2(37.65,2.80))
	stone_floor(Vector3(18.75,0,-.65),Vector2(2.7,37.3))
	stone_floor(Vector3(1.275,0,-18.70),Vector2(37.65,2.80))
	# Barrel vaults terminate in stone portals before the shared groin-vault corner.
	vaulted_ceiling(Vector3(18.7,0,.35),Vector2(2.80,35.3),true)
	vaulted_ceiling(Vector3(-.075,0,-18.70),Vector2(34.95,2.80))
	corridor_corner()
	vault_portal(Vector3(18.7,0,-17.3),2.80,0.0)
	vault_portal(Vector3(17.4,0,-18.7),2.80,PI/2)
	# Building walls already protect the rear walk; guards only border open courtyard edges.
	wall_routes = [Vector3(-16.5,y+.1,-4),Vector3(-16.5,y+.1,16.6),Vector3(0,y+.1,16.6),Vector3(18.75,y+.1,16.6),Vector3(18.75,y+.1,-18.75),Vector3(-16.4,y+.1,-18.75)]
	rooms.append({"name":"Kamenný ochoz za věží","rect":Rect2(17.35,-20.1,2.7,37.6)})
	rooms.append({"name":"Severní hradby","rect":Rect2(-16.55,-20.1,36.5,2.7)})
	rooms.append({"name":"Obranný ochoz","rect":Rect2(-17.5,-7.5,1.9,25)})
	rooms.append({"name":"Ochoz nad bránou","rect":Rect2(-17.5,15.6,35,1.9)})

func build_tower() -> void:
	for index in range(4):
		var y: float = TOWER_LEVELS[index]
		var h: float = GALLERY_Y if index==0 else FLOOR_STEP
		window_wall(Vector3(8,y,-3.5),9,h,[0.0],PI/2)
		if index==1: wall(Vector3(17,y,-3.5),9,h,[0.0],["Východní hradby"],PI/2)
		else: wall_piece(Vector3(17,y+h*.5,-3.5),Vector3(9,h,.6),PI/2)
		if index>=2:
			window_wall(Vector3(12.5,y,-8),9,h,[1.65])
			window_wall(Vector3(12.5,y,1),9,h,[1.65])
	stone_floor(Vector3(12.5,0,-3.5),Vector2(9,9))
	wall_finish_override = "plaster"
	for index in range(4):
		var level: float = TOWER_LEVELS[index]
		wall(Vector3(11.5,level,-3.5),8.4,GALLERY_Y if index==0 else FLOOR_STEP,[-3.15],["Pokoj věže · "+str(index)],PI/2)
	wall_finish_override = ""
	# The western bay stays open for the stairwell; the main ground-floor room is vaulted.
	vaulted_ceiling(Vector3(14.15,0,-3.5),Vector2(5.05,8.4),true)
	for floor in range(4):
		var y: float = TOWER_LEVELS[floor]
		if floor>0:
			stone_floor(Vector3(14.15,y,-3.5),Vector2(5.05,8.2))
			stone_floor(Vector3(9.95,y,-.18),Vector2(3.46,1.9))
		if floor<=3:
			var next: float = TOWER_LEVELS[floor+1] if floor<3 else ATTIC_Y
			var half: float = (next-y)*.5
			var count := 13 if floor==0 else 9
			var run := 4.32/(count-1)
			flight(Vector3(9.12,y,-.9),Vector3.FORWARD,count,half/count,run,1.5,[-1])
			floorboards(Vector3(9.93,y+half,-6.35),Vector2(3.40,2.82))
			rail(Vector3(9.86,y+half,-5.22),Vector3(10.08,y+half,-5.22))
			flight(Vector3(10.82,y+half,-5.22),Vector3.BACK,count,half/count,run,1.5,[-1])
			stair_routes.append({"start":Vector3(9.12,y+.08,-.2),"mid":Vector3(9.12,y+half+.1,-6.05),"turn":Vector3(10.82,y+half+.1,-6.05),"end":Vector3(10.82,next+.1,-.35),"exit":Vector3(14,next+.1,-.35)})
	stone_floor(Vector3(16.55,GALLERY_Y,-3.5),Vector2(1.9,2.7))
	# No railing against a solid wall at the eastern doorway.
	# Attic floor keeps the stairwell opening; beams stop at its trimmed edge.
	floorboards(Vector3(14.15,ATTIC_Y,-3.5),Vector2(5.05,8.4))
	floorboards(Vector3(9.95,ATTIC_Y,-.18),Vector2(3.46,1.9))
	for z in [-7.45,-6.0,-4.5,-3.0,-1.5,.45]:
		beam(Vector3(11.58,14.67,z),Vector3(17.05,14.67,z),.30,"beam",true,false)
	beam(Vector3(11.58,14.67,-7.65),Vector3(11.58,14.67,.85),.30,"beam",true,false)
	attic_roof()
	rooms.append({"name":"Věž","rect":Rect2(8,-8,9,9)})

func vaulted_ceiling(pos: Vector3, size: Vector2, across_x := false) -> void:
	var result := Vault.make(pos,size,across_x)
	batch(result.mesh,Transform3D.IDENTITY,"vault_stone")
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(result.mesh.get_faces())
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	static_body.add_child(collider)
	vaults.append({"center":pos,"size":size,"apex":4.5,"across_x":across_x})

func gate_wall(height: float) -> void:
	var half_open := 2.50
	wall_piece(Vector3(-10.25,height*.5,18),Vector3(15.5,height,.85))
	wall_piece(Vector3(11.5,height*.5,18),Vector3(18.0,height,.85))
	wall_piece(Vector3(0,(height+3.75)*.5,18),Vector3(5.0,height-3.75,.85))
	for x in [-2.64,2.64]:
		for j in range(8):
			batch(Construction.block(Vector3(.32,.45,1.03),.025),Transform3D(Basis.IDENTITY,Vector3(x,(j+.5)*.47,18)),"trim")
	batch(Construction.block(Vector3(5.65,.38,1.03),.035),Transform3D(Basis.IDENTITY,Vector3(0,3.91,18)),"trim")
	var leaves: Array = []
	for side in [-1,1]:
		var door := Door.new()
		door.width = 2.38
		door.height = 3.68
		door.position = Vector3(side*1.21,0,18)
		door.rotation.y = PI if side==1 else 0.0
		door.opening_side = -1.0 if side==1 else 1.0
		add_child(door)
		door.configure(mats.door,mats.iron,"Vstupní brána")
		doors.append(door)
		leaves.append(door)
	leaves[0].partner = leaves[1]
	leaves[1].partner = leaves[0]
	# Clear wall areas beside both jambs are reserved for future torch sockets.

func details() -> void:
	for pos in [Vector3(-11,2,-14),Vector3(0,2,-14),Vector3(11,2,-14),Vector3(14,5,-4),Vector3(14,9,-4),Vector3(14,12,-4),Vector3(13,2,9),Vector3(13,5.5,9)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color("f5dab3")
		light.light_energy = .35
		light.omni_range = 9
		add_child(light)

func table(pos: Vector3, size: Vector2) -> void:
	box(pos+Vector3(0,1,0),Vector3(size.x,.13,size.y),"wood",true)
	for x in [-1,1]:
		for z in [-1,1]:
			box(pos+Vector3(x*(size.x/2-.2),.5,z*(size.y/2-.2)),Vector3(.13,1,.13),"wood")

func lantern(pos: Vector3) -> void:
	beam(pos+Vector3(0,.15,-.25),pos+Vector3(0,.15,0),.045,"iron")
	box(pos,Vector3(.18,.27,.16),"iron")
	box(pos+Vector3(0,0,.084),Vector3(.12,.19,.008),"flame")
	var light := OmniLight3D.new()
	light.position = pos+Vector3(0,0,.15)
	light.light_color = Color("f0c487")
	light.light_energy = .3
	light.omni_range = 4
	add_child(light)
