extends Node3D
const Door = preload("res://scripts/fortress_door.gd")
const Construction = preload("res://scripts/construction_mesh.gd")
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
var stone_count := 0
var tile_count := 0
var rng := RandomNumberGenerator.new()

func build() -> void:
	rng.seed = 1403
	make_materials()
	static_body = StaticBody3D.new()
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
	for x in [-18.0,18.0]:
		wall_piece(Vector3(x,2.8,0),Vector3(36,5.6,.85),PI/2)
	wall_piece(Vector3(0,2.8,-18),Vector3(36,5.6,.85))
	wall(Vector3(0,0,18),36,5.6,[0.0],["Vstupní brána"])
	for i in range(18):
		var p := -17.0+i*2
		for z in [-18.0,18.0]:
			wall_piece(Vector3(p,6.1,z),Vector3(.95,1,1))
		for x in [-18.0,18.0]:
			wall_piece(Vector3(x,6.1,p),Vector3(1,1,.95))
	# A connected palace with real floorboards and masonry openings.
	floorboards(Vector3(0,0,-12.5),Vector2(34,9))
	for y in [3.6,7.2]:
		floorboards(Vector3(0,y,-12.5),Vector2(34,9))
	for y in [0.0,3.6]:
		wall(Vector3(0,y,-8),34,3.6,[-8.8,0.0,6.8,14.5] if y==0 else [-15.9,-8.8,0.0,6.8,14.5],["Kovárna","Kuchyň","Hodovní síň","Průchod do věže"] if y==0 else ["Obranný ochoz","Komnata","Palácová komnata","Hodovní síň","Průchod do věže"])
		for x in [-5.65,5.65]:
			wall(Vector3(x,y,-12.5),9,3.6,[0.0],["Spojovací dveře"],PI/2)
		window_wall(Vector3(0,y,-17),34,3.6,[-13.0,-8.5,0.0,8.5,13.0])
	for x in [-17.0,17.0]:
		wall_piece(Vector3(x,3.6,-12.5),Vector3(9,7.2,.6),PI/2)
	rooms = [{"name":"Kovárna","rect":Rect2(-17,-17,11.35,9)},{"name":"Kuchyň","rect":Rect2(-5.65,-17,11.3,9)},{"name":"Hodovní síň","rect":Rect2(5.65,-17,11.35,9)}]
	roof(Vector3(0,7.25,-12.5),Vector2(35,10),3,true)
	for x in [-12.0,.5]:
		wall_piece(Vector3(x,9,-14),Vector3(.8,3.3,.8))
		box(Vector3(x,10.75,-14),Vector3(1,.25,1),"trim")
	gallery()
	# East upper courtyard opening is a window, never a door into empty air.
	for y in [0.0,3.6]:
		floorboards(Vector3(12.5,y,8),Vector2(9,14))
		if y==0:
			wall(Vector3(8,y,8),14,3.6,[0.0],["Obytné křídlo"],PI/2)
		else:
			window_wall(Vector3(8,y,8),14,3.6,[0.0],PI/2)
		wall(Vector3(12.5,y,1),9,3.6,[2.0],["Dveře do věže"])
		window_wall(Vector3(17,y,8),14,3.6,[-4.0,4.0],PI/2)
		if y==0:
			window_wall(Vector3(12.5,y,15),9,3.6,[0.0])
		else:
			wall_piece(Vector3(12.5,4.05,15),Vector3(9,.9,.6))
			wall(Vector3(12.5,4.5,15),9,2.75,[2.0],["Přístup na hradby"])
	floorboards(Vector3(12.5,7.2,8),Vector2(9,14))
	roof(Vector3(12.5,7.25,8),Vector2(10,15),3,false)
	flight(Vector3(14.5,3.6,12.45),Vector3.BACK,5,.18,.4,1.6)
	floorboards(Vector3(14.5,4.5,15.25),Vector2(2.7,2.1))
	for x in [13.15,15.85]:
		rail(Vector3(x,4.5,14.2),Vector3(x,4.5,14.7))
	rail(Vector3(13.15,4.5,14.2),Vector3(13.7,4.5,14.2))
	rail(Vector3(15.3,4.5,14.2),Vector3(15.85,4.5,14.2))
	stair_routes.append({"start":Vector3(14.5,3.68,11.9),"mid":Vector3(14.5,4.14,13.3),"turn":Vector3(14.5,4.6,14.4),"end":Vector3(14.5,4.6,14.4),"exit":Vector3(14.5,4.6,14.4)})
	rooms.append({"name":"Obytné křídlo","rect":Rect2(8,1,9,14)})
	build_tower()
	defensive_walk()
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

func make_materials() -> void:
	mats.stone = textured("res://assets/materials/rock.jpg",.9,Color("a49f91"))
	mats.trim = plain(Color("b5ac96"))
	mats.mortar = plain(Color("5b5548"))
	mats.plaster = plain(Color("c8bda4"))
	var noise := FastNoiseLite.new()
	noise.frequency = .11
	noise.seed = 1403
	var plaster_normal := NoiseTexture2D.new()
	plaster_normal.width = 128
	plaster_normal.height = 128
	plaster_normal.noise = noise
	plaster_normal.as_normal_map = true
	plaster_normal.bump_strength = .2
	mats.plaster.normal_enabled = true
	mats.plaster.normal_texture = plaster_normal
	mats.plaster.normal_scale = .12
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
	for i in range(6):
		mats["rock"+str(i)] = mats.stone.duplicate()
		mats["rock"+str(i)].albedo_color = Color("a49f91")*(.86+i*.045)
		mats["rock"+str(i)].uv1_scale = Vector3.ONE*2.2
		mats["cobble"+str(i)] = mats.stone.duplicate()
		mats["cobble"+str(i)].albedo_color = Color("858579")*(.77+i*.075)
		mats["tile"+str(i)] = mats.stone.duplicate()
		mats["tile"+str(i)].albedo_color = Color("925c41")*(.78+i*.07)
		mats["tile"+str(i)].normal_scale = .08
		mesh_cache["rock"+str(i)] = Construction.block(Vector3.ONE,.12+i*.009,false,Vector2.ZERO,.055,1403+i)
		mesh_cache["cobble"+str(i)] = Construction.block(Vector3.ONE,.17+i*.008,false,Vector2.ZERO,.04,2403+i)
		mesh_cache["tile"+str(i)] = Construction.block(Vector3(.39,.055,.53),.02)

func batch(mesh: Mesh, transform: Transform3D, material_id: String) -> void:
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

func timber(pos: Vector3, size: Vector3, solid := false, material_id := "beam", along := Vector3.UP) -> void:
	var basis := Basis(Quaternion(Vector3.UP,along.normalized()))
	var variant := int(absf(pos.x*7+pos.z*11+pos.y*3))%5
	var key := str(size)+"/timber/"+str(variant)
	if not mesh_cache.has(key):
		mesh_cache[key] = Construction.block(size,.012,true,Vector2(variant*.17,variant*.13))
	batch(mesh_cache[key],Transform3D(basis,pos),material_id)
	if material_id in ["wood","beam","door"]:
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

func beam(a: Vector3, b: Vector3, thickness: float, material_id := "beam", solid := false) -> void:
	timber((a+b)*.5,Vector3(thickness,a.distance_to(b),thickness),solid,material_id,b-a)

func cylinder(pos: Vector3, top: float, bottom: float, height: float, material_id: String, sides := 12) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	batch(mesh,Transform3D(Basis.IDENTITY,pos),material_id)

func floorboards(pos: Vector3, size: Vector2) -> void:
	collision(Transform3D(Basis.IDENTITY,pos-Vector3(0,.07,0)),Vector3(size.x,.14,size.y))
	var count := int(ceil(size.x/.3))
	var width := size.x/count
	for i in range(count):
		var x := pos.x-size.x/2+(i+.5)*width
		var sections := int(ceil(size.y/3.8))
		for j in range(sections):
			var length := size.y/sections
			timber(Vector3(x,pos.y-.045,pos.z-size.y/2+(j+.5)*length),Vector3(width-.009,length-.012,.09),false,"wood",Vector3.FORWARD)

func courtyard() -> void:
	for z in range(76):
		for x in range(76):
			var px := -17.75+x*.47+(0.22 if z%2 else 0.0)
			var pz := -17.75+z*.47
			if px>17.6:
				continue
			var id := "cobble"+str(rng.randi_range(0,5))
			var scale := Vector3(rng.randf_range(.44,.46),rng.randf_range(.075,.10),rng.randf_range(.44,.46))
			var basis := Basis(Vector3.UP,rng.randf_range(-.08,.08)).scaled_local(scale)
			batch(mesh_cache[id],Transform3D(basis,Vector3(px,rng.randf_range(-.026,-.018),pz)),id)
			stone_count += 1
	# A shallow drain is visible, while the movement surface stays smooth.
	for z in range(-16,17):
		box(Vector3(6.5,-.002,z),Vector3(.1,.018,.94),"mortar")
	for i in range(40):
		var z := rng.randf_range(-4,16)
		box(Vector3(-17.5,.025,z),Vector3(.16,.015,rng.randf_range(.18,.5)),"moss")

func wall_piece(pos: Vector3, size: Vector3, angle := 0.0) -> void:
	var basis := Basis(Vector3.UP,angle)
	var mesh := BoxMesh.new()
	mesh.size = size
	batch(mesh,Transform3D(basis,pos),"mortar")
	collision(Transform3D(basis,pos),size)
	# Rubble relief on both faces of structural masonry; stones project from joints.
	var rows := maxi(1,int(ceil(size.y/.43)))
	var h := size.y/rows
	for row in range(rows):
		var start := -size.x/2
		while start<size.x/2-.015:
			var w := minf(rng.randf_range(.48,.85),size.x/2-start)
			var id := "rock"+str(rng.randi_range(0,5))
			for side in [-1,1]:
				var depth := rng.randf_range(.10,.16)
				var offset := Vector3(start+w/2,-size.y/2+(row+.5)*h,side*(size.z/2+.015))
				offset.y += rng.randf_range(-.018,.018)
				var scale := Vector3(maxf(.02,w-.022),maxf(.02,h-.028+rng.randf_range(-.035,.015)),depth)
				batch(mesh_cache[id],Transform3D(basis.scaled_local(scale),pos+basis*offset),id)
				stone_count += 1
			start += w

func wall(pos: Vector3, width: float, height: float, centers: Array, titles: Array, angle := 0.0) -> void:
	var basis := Basis(Vector3.UP,angle)
	var start := -width/2
	for i in range(centers.size()):
		var center: float = centers[i]
		var edge := center-1.13
		if edge>start:
			wall_piece(pos+basis*Vector3((start+edge)*.5,height*.5,0),Vector3(edge-start,height,.55),angle)
		wall_piece(pos+basis*Vector3(center,(height+2.72)*.5,0),Vector3(2.26,height-2.72,.55),angle)
		for side in [-1,1]:
			for j in range(6):
				var stone := Construction.block(Vector3(.25,.43,.74),.025)
				batch(stone,Transform3D(basis,pos+basis*Vector3(center+side*1.20,.22+j*.44,0)),"trim")
		var lintel := Construction.block(Vector3(2.65,.3,.76),.04)
		batch(lintel,Transform3D(basis,pos+basis*Vector3(center,2.84,0)),"trim")
		var door := Door.new()
		door.position = pos+basis*Vector3(center,0,0)
		door.rotation.y = angle
		add_child(door)
		door.configure(mats.door,mats.iron,titles[i])
		doors.append(door)
		start = center+1.13
	if start<width/2:
		wall_piece(pos+basis*Vector3((start+width/2)*.5,height*.5,0),Vector3(width/2-start,height,.55),angle)

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

func tiled_plane(origin: Vector3, across: Vector3, slope: Vector3) -> void:
	var a := across
	var start := origin
	var normal := slope.cross(a).normalized()
	if normal.y<0:
		start += a
		a = -a
		normal = -normal
	roof_normals.append(normal)
	var basis := Basis(a.normalized(),normal,slope.normalized())
	var sheet := SurfaceTool.new()
	sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
	Construction.quad(sheet,[start,start+a,start+a+slope,start+slope],normal)
	sheet.index()
	batch(sheet.commit(),Transform3D.IDENTITY,"tile0")
	var columns := int(ceil(a.length()/.37))
	var rows := int(ceil(slope.length()/.39))
	for row in range(rows):
		for column in range(columns):
			var id := "tile"+str(rng.randi_range(0,5))
			var p := start+a.normalized()*((column+.5)*a.length()/columns)+slope.normalized()*((row+.5)*slope.length()/rows)+normal*(.032+(row%2)*.002)
			batch(mesh_cache[id],Transform3D(basis,p),id)
			tile_count += 1
	beam(start,start+a,.19)
	for column in range(0,columns,5):
		var p := start+a.normalized()*(column*a.length()/columns)-normal*.1
		beam(p,p+slope,.12)

func roof(pos: Vector3, size: Vector2, rise: float, along_x: bool) -> void:
	var w := size.x/2
	var d := size.y/2
	if along_x:
		tiled_plane(pos+Vector3(-w,0,-d),Vector3(size.x,0,0),Vector3(0,rise,d))
		tiled_plane(pos+Vector3(-w,0,d),Vector3(size.x,0,0),Vector3(0,rise,-d))
		for x in [-w,w]:
			gable([pos+Vector3(x,0,-d),pos+Vector3(x,rise,0),pos+Vector3(x,0,d)],Vector3(signf(x),0,0))
		beam(pos+Vector3(-w,rise+.07,0),pos+Vector3(w,rise+.07,0),.17,"tile3")
	else:
		tiled_plane(pos+Vector3(-w,0,-d),Vector3(0,0,size.y),Vector3(w,rise,0))
		tiled_plane(pos+Vector3(w,0,-d),Vector3(0,0,size.y),Vector3(-w,rise,0))
		for z in [-d,d]:
			gable([pos+Vector3(-w,0,z),pos+Vector3(0,rise,z),pos+Vector3(w,0,z)],Vector3(0,0,signf(z)))
		beam(pos+Vector3(0,rise+.07,-d),pos+Vector3(0,rise+.07,d),.17,"tile3")

func gable(points: Array, normal: Vector3) -> void:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,2,1]:
		s.set_normal(normal)
		s.set_uv(Vector2(points[i].x,points[i].y))
		s.add_vertex(points[i])
	s.index()
	batch(s.commit(),Transform3D.IDENTITY,"mortar")
	var center: Vector3 = (points[0]+points[2])*.5
	var axis: Vector3 = (points[2]-points[0]).normalized()
	var width: float = points[0].distance_to(points[2])
	var rise: float = points[1].y-center.y
	var rows := int(ceil(rise/.43))
	var h := rise/rows
	var basis := Basis(axis,Vector3.UP,axis.cross(Vector3.UP))
	for row in range(rows):
		var half := width*.5*(1-(row+1.0)*h/rise)
		var x := -half
		while x<half-.02:
			var w := minf(.68,half-x)
			var id := "rock"+str(rng.randi_range(0,5))
			for side in [-1,1]:
				var p: Vector3 = center+axis*(x+w/2)+Vector3(0,(row+.5)*h,0)+normal*side*.025
				batch(mesh_cache[id],Transform3D(basis.scaled_local(Vector3(maxf(.02,w-.02),h-.03,.13)),p),id)
			x += w

func rail(a: Vector3, b: Vector3, opening := false) -> void:
	var count := int(ceil(a.distance_to(b)/.32))
	beam(a+Vector3(0,1.02,0),b+Vector3(0,1.02,0),.10,"beam",true)
	beam(a+Vector3(0,.18,0),b+Vector3(0,.18,0),.08)
	for i in range(count+1):
		var p := a.lerp(b,float(i)/count)
		beam(p,p+Vector3(0,1.02,0),.055 if i%6 else .12)
	if not opening:
		var center := (a+b)/2+Vector3(0,.52,0)
		var direction := (b-a).normalized()
		var flat := Vector3(direction.x,0,direction.z).normalized()
		var basis := Basis(flat,Vector3.UP,flat.cross(Vector3.UP))
		collision(Transform3D(basis,center),Vector3(a.distance_to(b),1.04,.09))

func flight(first: Vector3, direction: Vector3, count: int, rise: float, run: float, width: float) -> Vector3:
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
		rail(first+across*side*(width/2-.01)+Vector3(0,rise,0),last+across*side*(width/2-.01),true)
	return last

func gallery() -> void:
	floorboards(Vector3(-1.2,3.6,-6.5),Vector2(18.4,3))
	for x in [-10.0,-7.0,-4.0,-1.0,2.0,5.0,8.0]:
		beam(Vector3(x,0,-5),Vector3(x,6.7,-5),.23)
		beam(Vector3(x,5.8,-5),Vector3(x,6.8,-6.5),.15)
		beam(Vector3(x,2.5,-5),Vector3(x,3.48,-6.4),.17)
		if x<8:
			rail(Vector3(x,3.6,-5),Vector3(minf(x+3,8),3.6,-5))
	beam(Vector3(-10.4,3.45,-5),Vector3(8,3.45,-5),.25)
	# Compact U stair runs parallel to the facade, under one joined canopy.
	flight(Vector3(-10.6,0,-4.5),Vector3.LEFT,10,.18,.48,1.6)
	floorboards(Vector3(-15.6,1.8,-5.5),Vector2(1.4,2.7))
	flight(Vector3(-14.92,1.8,-6.5),Vector3.RIGHT,10,.18,.48,1.6)
	for z in [-6.7,-4.3]:
		beam(Vector3(-16.2,0,z),Vector3(-16.2,6.8,z),.23)
		beam(Vector3(-16.2,1.3,z),Vector3(-15.0,1.73,z),.16)
	rail(Vector3(-16.3,1.8,-6.85),Vector3(-16.3,1.8,-4.15))
	rail(Vector3(-16.3,1.8,-4.15),Vector3(-14.9,1.8,-4.15))
	floorboards(Vector3(-15.9,3.6,-7.6),Vector2(2.7,.8))
	rail(Vector3(-15.7,3.6,-7.2),Vector3(-14.55,3.6,-7.2))
	for x in [-17.25,-14.55]:
		rail(Vector3(x,3.6,-8),Vector3(x,3.6,-7.2))
	flight(Vector3(-16.5,3.6,-6.9),Vector3.BACK,5,.18,.4,1.6)
	stair_routes.append({"start":Vector3(-9.95,.08,-4.5),"mid":Vector3(-15.6,1.9,-4.5),"turn":Vector3(-15.6,1.9,-6.5),"end":Vector3(-9.7,3.7,-6.5),"exit":Vector3(-8.8,3.7,-6.5)})
	stair_routes.append({"start":Vector3(-16.5,3.68,-7.6),"mid":Vector3(-16.5,4.6,-4.7),"turn":Vector3(-16.5,4.6,-4.4),"end":Vector3(-16.5,4.6,-3),"exit":Vector3(-16.5,4.6,0)})
	tiled_plane(Vector3(-17.2,7.15,-8.3),Vector3(25.6,0,0),Vector3(0,-.70,4.95))

func defensive_walk() -> void:
	floorboards(Vector3(-16.6,4.5,5.8),Vector2(1.8,21.6))
	floorboards(Vector3(0,4.5,16.6),Vector2(35,1.8))
	rail(Vector3(-15.65,4.5,-4.9),Vector3(-15.65,4.5,13.5))
	rail(Vector3(-15.6,4.5,15.65),Vector3(17.2,4.5,15.65))
	for z in range(-4,17,3):
		beam(Vector3(-17.6,4.37,z),Vector3(-15.65,4.37,z),.22)
		beam(Vector3(-17.55,2.8,z),Vector3(-15.7,4.3,z),.20)
	for x in range(-16,18,3):
		beam(Vector3(x,4.37,17.55),Vector3(x,4.37,15.65),.22)
		beam(Vector3(x,2.8,17.55),Vector3(x,4.3,15.7),.20)
	# Independent stair from the yard and a continuous platform above the gate.
	flight(Vector3(-5.0,0,14.5),Vector3.LEFT,25,.18,.36,1.65)
	floorboards(Vector3(-15.0,4.5,14.5),Vector2(3.1,1.8))
	rail(Vector3(-15.6,4.5,13.55),Vector3(-14,4.5,13.55))
	stair_routes.append({"start":Vector3(-4.45,.08,14.5),"mid":Vector3(-14.7,4.6,14.5),"turn":Vector3(-16.5,4.6,14.5),"end":Vector3(-16.5,4.6,16.6),"exit":Vector3(-12.0,4.6,16.6)})
	wall_routes = [Vector3(-16.5,4.6,-4),Vector3(-16.5,4.6,16.6),Vector3(0,4.6,16.6),Vector3(16.5,4.6,16.6)]
	rooms.append({"name":"Obranný ochoz","rect":Rect2(-17.5,-5,1.9,22.5)})
	rooms.append({"name":"Ochoz nad bránou","rect":Rect2(-17.5,15.6,35,1.9)})

func build_tower() -> void:
	for y in [0.0,3.6,7.2,10.8]:
		window_wall(Vector3(8,y,-3.5),9,3.6,[0.0],PI/2)
		window_wall(Vector3(17,y,-3.5),9,3.6,[0.0],PI/2)
		if y>=7.2:
			window_wall(Vector3(12.5,y,-8),9,3.6,[0.0])
			window_wall(Vector3(12.5,y,1),9,3.6,[0.0])
	floorboards(Vector3(12.5,0,-3.5),Vector2(9,9))
	for floor in range(4):
		var y := floor*3.6
		if floor>0:
			floorboards(Vector3(14.15,y,-3.5),Vector2(5.05,8.2))
			floorboards(Vector3(10.1,y,-.35),Vector2(3.8,1.1))
		if floor<3:
			flight(Vector3(9.12,y,-.9),Vector3.FORWARD,10,.18,.48,1.5)
			floorboards(Vector3(9.95,y+1.8,-6.05),Vector2(3.25,1.2))
			flight(Vector3(10.82,y+1.8,-5.22),Vector3.BACK,10,.18,.48,1.5)
			stair_routes.append({"start":Vector3(9.12,y+.08,-.2),"mid":Vector3(9.12,y+1.9,-6.05),"turn":Vector3(10.82,y+1.9,-6.05),"end":Vector3(10.82,y+3.7,-.35),"exit":Vector3(14,y+3.7,-.35)})
	floorboards(Vector3(12.5,14.4,-3.5),Vector2(9,9))
	roof(Vector3(12.5,14.45,-3.5),Vector2(10,10),3.2,false)
	rooms.append({"name":"Věž","rect":Rect2(8,-8,9,9)})

func details() -> void:
	for y in [0.0,3.6]:
		box(Vector3(-4.6,y+1.9,-16.59),Vector3(5,2.65,.055),"plaster")
		box(Vector3(4,y+1.9,-16.59),Vector3(3,2.65,.055),"plaster")
	for pos in [Vector3(-8.8,2.3,-7.55),Vector3(0,2.3,-7.55),Vector3(8.4,2.3,9),Vector3(14,2.3,1.5)]:
		lantern(pos)
	box(Vector3(-13,.8,-14),Vector3(2,1.6,1.8),"stone",true)
	box(Vector3(-10,.45,-12),Vector3(.4,.9,.4),"wood",true)
	box(Vector3(-10,1,-12),Vector3(1.25,.22,.55),"iron",true)
	box(Vector3(-15,1.1,-10.2),Vector3(2.7,.15,1),"wood",true)
	box(Vector3(2,.5,-14.8),Vector3(2.5,1,1.4),"stone",true)
	table(Vector3(-1,0,-12),Vector2(3,1.4))
	table(Vector3(11,0,-12.5),Vector2(3,5))
	for x in [8.9,13.1]:
		box(Vector3(x,.45,-12.5),Vector3(.55,.18,4.8),"wood",true)
		for z in [-14.5,-10.5]:
			box(Vector3(x,.22,z),Vector3(.12,.44,.12),"wood")
	for floor in [1,2,3]:
		table(Vector3(15,floor*3.6,-6.3),Vector2(1.7,.8))
	box(Vector3(15,11.25,-3.2),Vector3(1.8,.65,2.5),"wood",true)
	box(Vector3(15,11.63,-3.2),Vector3(1.7,.13,2.4),"linen")
	box(Vector3(15,11.77,-4.1),Vector3(1.5,.2,.45),"linen")
	for y in [0.0,3.6]:
		for z in [5.0,10.0]:
			box(Vector3(15,y+.55,z),Vector3(1.65,1.1,2.3),"wood",true)
			box(Vector3(15,y+1.17,z),Vector3(1.55,.14,2.2),"linen")
	for i in range(6):
		var pos := Vector3(-16+i*.8,.58,15)
		cylinder(pos,.34,.36,1.1,"wood")
		for y in [.18,.93]:
			cylinder(Vector3(pos.x,y,pos.z),.365,.365,.05,"iron")
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
