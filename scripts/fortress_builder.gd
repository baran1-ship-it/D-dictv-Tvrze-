extends Node3D
const Door = preload("res://scripts/fortress_door.gd")
var mats: Dictionary = {}
var batches: Dictionary = {}
var doors: Array = []
var rooms: Array = []
var static_body: StaticBody3D
var stair_routes: Array = []

func build() -> void:
	make_materials()
	static_body = StaticBody3D.new()
	add_child(static_body)
	box(Vector3(0,-.45,0),Vector3(170,.8,170),"grass",true)
	box(Vector3(0,-.14,0),Vector3(36,.26,36),"paving",true)
	for i in range(24):
		var angle := i*2.39996
		var radius := 28.0+float(i%4)*8
		var pos := Vector3(sin(angle)*radius,0,cos(angle)*radius)
		cylinder(pos+Vector3(0,2,0),.28,.42,4,"wood")
		cylinder(pos+Vector3(0,6,0),.2,3.2,6,"leaves",10)
	for x in [-18.0,18.0]:
		box(Vector3(x,2.8,0),Vector3(.85,5.6,36),"stone",true)
	box(Vector3(0,2.8,-18),Vector3(36,5.6,.85),"stone",true)
	wall(Vector3(0,0,18),36,5.6,[0.0],["Vstupní brána"])
	box(Vector3(0,-.04,21),Vector3(7,.2,6),"paving",true)
	for x in [-3.5,3.5]:
		box(Vector3(x,2.2,21),Vector3(.5,4.4,6),"stone",true)
	box(Vector3(0,2.2,24),Vector3(7,4.4,.5),"stone",true)
	for i in range(18):
		var p := -17.0+i*2
		for z in [-18.0,18.0]:
			box(Vector3(p,6,z),Vector3(.9,.8,1),"stone")
		for x in [-18.0,18.0]:
			box(Vector3(x,6,p),Vector3(1,.8,.9),"stone")
	# One continuous north wing, shared floors, walls and pitched roof.
	box(Vector3(0,-.05,-12.5),Vector3(34,.15,9),"paving",true)
	for y in [3.5,7.15]:
		box(Vector3(0,y,-12.5),Vector3(34,.2,9),"wood",true)
	box(Vector3(0,3.6,-17),Vector3(34,7.2,.6),"stone",true)
	for x in [-17.0,17.0]:
		box(Vector3(x,3.6,-12.5),Vector3(.6,7.2,9),"stone",true)
	for y in [0.0,3.6]:
		wall(Vector3(0,y,-8),34,3.6,[-11.0,0.0,6.8,14.5],["Kovárna" if y==0 else "Komnata","Kuchyň" if y==0 else "Palácová komnata","Hodovní síň","Průchod do věže"])
		for x in [-5.65,5.65]:
			wall(Vector3(x,y,-12.5),9,3.6,[0.0],["Spojovací dveře"],PI/2)
	rooms = [{"name":"Kovárna","rect":Rect2(-17,-17,11.35,9)},{"name":"Kuchyň","rect":Rect2(-5.65,-17,11.3,9)},{"name":"Hodovní síň","rect":Rect2(5.65,-17,11.35,9)}]
	roof(Vector3(0,7.25,-12.5),Vector2(35,10),3,true)
	for x in [-12.0,.5]:
		box(Vector3(x,9,-14),Vector3(.8,3.3,.8),"stone")
		box(Vector3(x,10.75,-14),Vector3(1,.25,1),"stone")
	# Supported timber gallery, stairs have two flights and a turning platform.
	box(Vector3(-4.5,3.5,-6.5),Vector3(25,.2,3),"wood",true)
	box(Vector3(-4.5,6.6,-6.5),Vector3(25,.2,3.2),"wood")
	for x in range(-16,9,3):
		box(Vector3(x,3.2,-5),Vector3(.2,6.4,.2),"wood")
		beam(Vector3(x,5.7,-5),Vector3(x,6.5,-6.5),.16,"wood")
		if x < -11 or x > -8.6:
			box(Vector3(x,4.1,-5),Vector3(.1,1.1,.1),"wood",true)
	box(Vector3(-14,4.62,-5),Vector3(6,.12,.12),"wood",true)
	box(Vector3(-.3,4.62,-5),Vector3(16.6,.12,.12),"wood",true)
	for i in range(10):
		step(Vector3(-15,(i+1)*.18,2-i*.42),Vector2(1.8,.45))
	box(Vector3(-15,1.7,-2.35),Vector3(2.2,.2,1.8),"wood",true)
	for i in range(10):
		step(Vector3(-14.2+i*.42,1.8+(i+1)*.18,-2.35),Vector2(.45,1.8))
	box(Vector3(-9.4,3.5,-3.65),Vector3(1.8,.2,2.5),"wood",true)
	stair_routes.append({"start":Vector3(-15,.08,2.5),"mid":Vector3(-15,1.9,-2.35),"turn":Vector3(-14.6,1.9,-2.35),"end":Vector3(-9.8,3.7,-2.35),"exit":Vector3(-9.8,3.7,-6.3)})
	for x in [-15.7,-14.3]:
		beam(Vector3(x,.02,2.2),Vector3(x,1.65,-2.1),.17,"wood")
	for z in [-3.1,-1.6]:
		beam(Vector3(-14.4,1.65,z),Vector3(-10.1,3.45,z),.17,"wood")
	for x in [-15.8,-14.2]:
		box(Vector3(x,.8,-2.35),Vector3(.16,1.6,.16),"wood")
	beam(Vector3(-16,1.1,2.3),Vector3(-16,2.9,-2.3),.1,"wood")
	# The east residential wing joins the tower, not a separate house.
	for y in [0.0,3.6]:
		box(Vector3(12.5,y-.08,9),Vector3(9,.16,16),"wood",true)
		wall(Vector3(8,y,9),16,3.6,[0.0],["Obytné křídlo"],PI/2)
		wall(Vector3(12.5,y,1),9,3.6,[2.0],["Dveře do věže"])
		box(Vector3(17,y+1.8,9),Vector3(.6,3.6,16),"stone",true)
		box(Vector3(12.5,y+1.8,17),Vector3(9,3.6,.6),"stone",true)
	box(Vector3(12.5,7.15,9),Vector3(9,.2,16),"wood",true)
	roof(Vector3(12.5,7.25,9),Vector2(10,17),3,false)
	rooms.append({"name":"Obytné křídlo","rect":Rect2(8,1,9,16)})
	build_tower()
	details()
	for key in batches:
		var mesh := batches[key].commit() as ArrayMesh
		mesh.surface_set_material(0,mats[key])
		var instance := MeshInstance3D.new()
		instance.name = "Architecture_"+str(key)
		instance.mesh = mesh
		add_child(instance)

func plain(color: Color, roughness := .9, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func textured(path: String, scale: float, tint: Color) -> StandardMaterial3D:
	var mat := plain(tint)
	mat.albedo_texture = load(path) as Texture2D
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE*scale
	var color_image := mat.albedo_texture.get_image()
	if color_image.is_compressed():
		color_image.decompress()
	color_image.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(color_image)
	var normal := color_image.duplicate() as Image
	if normal.is_compressed():
		normal.decompress()
	normal.resize(256,256)
	normal.bump_map_to_normal_map(.35)
	mat.normal_enabled = true
	mat.normal_texture = ImageTexture.create_from_image(normal)
	mat.normal_scale = .22
	return mat

func make_materials() -> void:
	mats.stone = textured("res://assets/materials/stone.jpg",.38,Color("b8b2a5"))
	mats.wood = textured("res://assets/materials/oak.jpg",.5,Color.WHITE)
	mats.paving = textured("res://assets/materials/stone.jpg",.65,Color("a8a18d"))
	mats.iron = plain(Color("373936"),.72,.65)
	mats.grass = plain(Color("59614b"),1)
	mats.leaves = plain(Color("3c5032"),1)
	mats.linen = plain(Color("b0a48a"),1)
	mats.glass = plain(Color("607878"),.25,.2)
	mats.skin = plain(Color("b48763"),.8)
	var texture_image := Image.create(256,256,false,Image.FORMAT_RGB8)
	for y in range(256):
		for x in range(256):
			var row := int(y/32)
			var column := int((x+(16 if row%2 else 0))/32)
			var seam := y%32<2 or (x+(16 if row%2 else 0))%32<2
			var shade := .75+float((row*17+column*11)%9)*.025+float((x*13+y*7)%19)/190
			texture_image.set_pixel(x,y,Color("755346")*(.48 if seam else shade))
	var roof_mat := plain(Color.WHITE,.9)
	texture_image.generate_mipmaps()
	roof_mat.albedo_texture = ImageTexture.create_from_image(texture_image)
	roof_mat.uv1_triplanar = true
	roof_mat.uv1_world_triplanar = true
	roof_mat.uv1_scale = Vector3.ONE*.65
	var normal := texture_image.duplicate() as Image
	normal.bump_map_to_normal_map(.65)
	roof_mat.normal_enabled = true
	roof_mat.normal_texture = ImageTexture.create_from_image(normal)
	roof_mat.normal_scale = .3
	mats.roof = roof_mat

func batch(mesh: Mesh, transform: Transform3D, material_id: String) -> void:
	if not batches.has(material_id):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[material_id] = surface
	batches[material_id].append_from(mesh,0,transform)

func box(pos: Vector3, size: Vector3, material_id: String, solid := false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	batch(mesh,Transform3D(Basis.IDENTITY,pos),material_id)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		collider.position = pos
		static_body.add_child(collider)

func cylinder(pos: Vector3, top: float, bottom: float, height: float, material_id: String, sides := 12) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	batch(mesh,Transform3D(Basis.IDENTITY,pos),material_id)

func beam(a: Vector3, b: Vector3, thickness: float, material_id: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness,a.distance_to(b),thickness)
	batch(mesh,Transform3D(Basis(Quaternion(Vector3.UP,(b-a).normalized())),(a+b)*.5),material_id)

func step(top: Vector3, footprint: Vector2) -> void:
	box(top-Vector3(0,.1,0),Vector3(footprint.x,.2,footprint.y),"wood",true)

func wall(pos: Vector3, width: float, height: float, centers: Array, titles: Array, angle := 0.0) -> void:
	var basis := Basis(Vector3.UP,angle)
	var start := -width/2
	for i in range(centers.size()):
		var center: float = centers[i]
		var edge := center-1.13
		if edge>start:
			wall_part(pos,basis,Vector3((start+edge)*.5,height*.5,0),Vector3(edge-start,height,.55))
		wall_part(pos,basis,Vector3(center,(height+2.72)*.5,0),Vector3(2.26,height-2.72,.55))
		for s in [-1,1]:
			wall_part(pos,basis,Vector3(center+s*1.21,1.35,.05),Vector3(.22,2.7,.7))
		for j in range(11):
			var t := PI*float(j)/10
			var p := pos+basis*Vector3(center+cos(t)*1.25,2.6+sin(t)*.42,.08)
			var mesh := BoxMesh.new()
			mesh.size = Vector3(.27,.28,.72)
			batch(mesh,Transform3D(basis*Basis(Vector3.FORWARD,t-PI/2),p),"stone")
		var door := Door.new()
		door.position = pos+basis*Vector3(center,0,0)
		door.rotation.y = angle
		add_child(door)
		door.configure(mats.wood,mats.iron,titles[i])
		doors.append(door)
		start = center+1.13
	if start<width/2:
		wall_part(pos,basis,Vector3((start+width/2)*.5,height*.5,0),Vector3(width/2-start,height,.55))

func wall_part(pos: Vector3, basis: Basis, offset: Vector3, size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var transform := Transform3D(basis,pos+basis*offset)
	batch(mesh,transform,"stone")
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.transform = transform
	static_body.add_child(collider)

func roof(pos: Vector3, size: Vector2, rise: float, along_x: bool) -> void:
	var w := size.x*.5
	var d := size.y*.5
	var vertices: Array[Vector3]
	if along_x:
		vertices = [Vector3(-w,0,-d),Vector3(w,0,-d),Vector3(w,rise,0),Vector3(-w,rise,0),Vector3(-w,0,d),Vector3(w,0,d)]
	else:
		vertices = [Vector3(-w,0,-d),Vector3(-w,0,d),Vector3(0,rise,d),Vector3(0,rise,-d),Vector3(w,0,-d),Vector3(w,0,d)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,1,2,0,2,3,4,2,5,4,3,2]:
		surface.set_uv(Vector2(vertices[index].x,vertices[index].z))
		surface.add_vertex(vertices[index]+pos)
	surface.generate_normals()
	surface.index()
	batch(surface.commit(),Transform3D.IDENTITY,"roof")
	var ends := SurfaceTool.new()
	ends.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,3,4,1,5,2]:
		ends.set_uv(Vector2(vertices[index].x,vertices[index].y))
		ends.add_vertex(vertices[index]+pos)
	ends.generate_normals()
	ends.index()
	batch(ends.commit(),Transform3D.IDENTITY,"stone")
	if along_x:
		beam(pos+Vector3(-w,rise,0),pos+Vector3(w,rise,0),.13,"roof")
	else:
		beam(pos+Vector3(0,rise,-d),pos+Vector3(0,rise,d),.13,"roof")

func build_tower() -> void:
	box(Vector3(12.5,10.8,-8),Vector3(9,7.2,.65),"stone",true)
	for x in [8.0,17.0]:
		box(Vector3(x,7.2,-3.5),Vector3(.65,14.4,9),"stone",true)
	box(Vector3(12.5,10.8,1),Vector3(9,7.2,.65),"stone",true)
	box(Vector3(12.5,-.05,-3.5),Vector3(9,.15,9),"paving",true)
	for floor in range(4):
		var y := floor*3.6
		if floor>0:
			box(Vector3(14.65,y-.1,-3.5),Vector3(4.05,.2,8.2),"wood",true)
			box(Vector3(10.7,y-.1,-.35),Vector3(3.9,.2,1.1),"wood",true)
		box(Vector3(16.64,y+1.9,-3.5),Vector3(.035,1.6,1),"glass")
		box(Vector3(12.5,y+2.2,1.35),Vector3(1.1,1.7,.03),"glass")
		if floor<3:
			for i in range(10):
				box(Vector3(9.65,y+(i+1)*.18-.1,-.9-i*.48),Vector3(1.5,.2,.5),"wood",true)
				box(Vector3(11.35,y+1.8+(i+1)*.18-.1,-5.22+i*.48),Vector3(1.5,.2,.5),"wood",true)
			box(Vector3(10.5,y+1.7,-6.05),Vector3(3.25,.2,1.2),"wood",true)
			beam(Vector3(8.88,y+.95,-.65),Vector3(8.88,y+2.65,-5.6),.085,"wood")
			beam(Vector3(12.13,y+2.75,-5.4),Vector3(12.13,y+4.5,-.6),.085,"wood")
			for i in range(5):
				box(Vector3(8.88,y+i*.36+.65,-.9-i*.96),Vector3(.06,.9,.06),"wood")
				box(Vector3(12.13,y+2.45+i*.36,-5.22+i*.96),Vector3(.06,.9,.06),"wood")
			stair_routes.append({"start":Vector3(9.65,y+.08,-.2),"mid":Vector3(9.65,y+1.9,-6.05),"turn":Vector3(11.35,y+1.9,-6.05),"end":Vector3(11.35,y+3.7,-.35),"exit":Vector3(14,y+3.7,-.35)})
	box(Vector3(12.5,14.3,-3.5),Vector3(9,.2,9),"wood",true)
	roof(Vector3(12.5,14.45,-3.5),Vector2(10,10),3.2,false)
	rooms.append({"name":"Věž","rect":Rect2(8,-8,9,9)})

func details() -> void:
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
		for z in [5.0,12.0]:
			box(Vector3(15,y+.55,z),Vector3(1.65,1.1,2.3),"wood",true)
			box(Vector3(15,y+1.17,z),Vector3(1.55,.14,2.2),"linen")
	for floor in [0,1]:
		for x in range(-14,16,4):
			box(Vector3(x,floor*3.6+1.9,-16.65),Vector3(1.1,1.4,.03),"glass")
			box(Vector3(x,floor*3.6+1.9,-16.56),Vector3(.07,1.6,.12),"wood")
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
