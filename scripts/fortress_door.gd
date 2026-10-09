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

func configure(wood: Material, iron: Material, door_title: String) -> void:
	title = door_title
	pivot = Node3D.new()
	pivot.position.x = -width / 2
	add_child(pivot)
	body = StaticBody3D.new()
	body.set_meta("door", self)
	pivot.add_child(body)
	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(width, height, 0.13)
	panel.mesh = panel_mesh
	panel.material_override = wood
	panel.position = Vector3(width / 2, height / 2, 0)
	body.add_child(panel)
	collider = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = panel_mesh.size
	collider.shape = shape
	collider.position = panel.position
	body.add_child(collider)
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
	handle.position = Vector3(width - 0.25, 1.05, 0.12)
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
		ring.position.z = side * 0.12
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
	var side := 1.0 if to_local(player_position).z >= 0 else -1.0
	opened = not opened
	collider.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(pivot, "rotation:y", side * PI * 0.52 if opened else 0.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		collider.set_deferred("disabled", false)
		busy = false)
	return true
