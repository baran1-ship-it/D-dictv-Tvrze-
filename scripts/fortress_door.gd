extends Node3D

var pivot: Node3D
var body: StaticBody3D
var collider: CollisionShape3D
var handle: Node3D
var opened := false
var busy := false
var title := "Dveře"
var width := 2.1
var height := 2.65
var opening_side := 0.0

func configure(wood: Material, iron: Material, door_title: String) -> void:
	title = door_title
	pivot = Node3D.new()
	pivot.position.x = -width / 2
	add_child(pivot)
	body = StaticBody3D.new()
	body.set_meta("door", self)
	pivot.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(width,height,.13)
	collider = CollisionShape3D.new()
	collider.shape = shape
	collider.position = Vector3(width/2,height/2,0)
	body.add_child(collider)
	var wood_batch := SurfaceTool.new()
	wood_batch.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(9):
		var board := preload("res://scripts/construction_mesh.gd").block(Vector3(width/9-.004,height,.13),.008,true,Vector2(i*.117+absf(position.x)*.04,i*.13))
		wood_batch.append_from(board,0,Transform3D(Basis.IDENTITY,Vector3((i+.5)*width/9,height/2,0)))
	var panel := MeshInstance3D.new()
	panel.mesh = wood_batch.commit()
	panel.material_override = wood
	body.add_child(panel)
	for y in [0.5, 2.0]:
		var strap := MeshInstance3D.new()
		var strap_mesh := BoxMesh.new()
		strap_mesh.size = Vector3(1.8, 0.07, 0.17)
		strap.mesh = strap_mesh
		strap.material_override = iron
		strap.position = Vector3(width / 2, y, 0)
		body.add_child(strap)
		for x in [0.13, 0.5, 1.75]:
			var rivet := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.035
			sphere.height = 0.07
			rivet.mesh = sphere
			rivet.material_override = iron
			rivet.position = Vector3(x, y, 0.095)
			body.add_child(rivet)
	handle = Node3D.new()
	handle.position = Vector3(width - 0.45, 1.10, 0.0)
	body.add_child(handle)
	for side in [-1, 1]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.064
		torus.outer_radius = 0.09
		torus.rings = 12
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = iron
		ring.rotation.x = PI / 2
		ring.position.z = side * 0.095
		var plate := MeshInstance3D.new()
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(.15,.20,.02)
		plate.mesh = plate_mesh
		plate.material_override = iron
		plate.position = Vector3(0,.065,side*.074)
		handle.add_child(plate)
		var stem := MeshInstance3D.new()
		var stem_mesh := SphereMesh.new()
		stem_mesh.radius = .035
		stem_mesh.height = .07
		stem.mesh = stem_mesh
		stem.material_override = iron
		stem.position = Vector3(0,.07,side*.091)
		handle.add_child(stem)
		handle.add_child(ring)

func blocked_by(player_position: Vector3) -> bool:
	var p := to_local(player_position)
	return absf(p.x) < width / 2 + 0.4 and absf(p.z) < 0.65 and p.y > -1.8 and p.y < height

func toggle(player_position: Vector3) -> bool:
	if busy:
		return false
	if opened and blocked_by(player_position):
		return false
	busy = true
	var side := opening_side if opening_side!=0 else (1.0 if to_local(player_position).z >= 0 else -1.0)
	opened = not opened
	collider.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(pivot, "rotation:y", side * PI * 0.49 if opened else 0.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		collider.set_deferred("disabled", false)
		busy = false)
	return true

func grasp_position(player_position: Vector3) -> Vector3:
	var side := 1.0 if body.to_local(player_position).z>=0 else -1.0
	return handle.to_global(Vector3(0,0,side*.11))
