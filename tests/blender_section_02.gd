extends SceneTree
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: errors.append(message)
func ray(a: Vector3,b: Vector3) -> Dictionary:
	return root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b))
func run() -> void:
	var section = load("res://scenes/blender/section_02.tscn").instantiate()
	root.add_child(section)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(20,.2,20)
	cs.shape=box
	cs.position.y=-.1
	ground.add_child(cs)
	root.add_child(ground)
	for i in range(4): await physics_frame
	var floor_query := PhysicsRayQueryParameters3D.create(Vector3(3,1,5),Vector3(3,-.3,5))
	floor_query.exclude=[ground.get_rid()]
	var floor_hit := root.get_world_3d().direct_space_state.intersect_ray(floor_query)
	check(not floor_hit.is_empty() and floor_hit.collider==section.wall_body,"New terrain collision missing")
	check(section.door.width==2.1 and section.door.height==2.65,"Door dimensions changed")
	var hit:=ray(Vector3(0,1,2),Vector3(0,1,-2))
	check(not hit.is_empty() and hit.collider==section.door.body,"Closed door fails to block")
	check(section.door.body.has_meta("door"),"Door targeting metadata missing")
	check(section.near_visual.visible and not section.far_visual.visible,"Default LOD incorrect")
	check(not ray(Vector3(2,1,2),Vector3(2,1,-2)).is_empty(),"Solid wall has a gap")
	check(not ray(Vector3(0,5.57,2),Vector3(0,5.57,-2)).is_empty(),"Window barrier missing")
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current=true
	cam.position=Vector3(0,3.6,40)
	for i in range(3): await process_frame
	check(section.far_visual.visible and not section.near_visual.visible,"Far LOD not selected")
	cam.position=Vector3(0,3.6,21.5)
	for i in range(3): await process_frame
	check(section.far_visual.visible,"LOD hysteresis missing")
	cam.position=Vector3(0,3.6,19)
	for i in range(3): await process_frame
	check(section.near_visual.visible and not section.far_visual.visible,"Near LOD not restored")
	var meshes: Array[MeshInstance3D] = []
	collect(section.door.body,meshes)
	check(not meshes.is_empty(),"Imported leaf missing")
	var leaf_bounds := AABB()
	var first := true
	for m in meshes:
		var b: AABB = section.door.body.global_transform.affine_inverse()*m.global_transform*m.get_aabb()
		leaf_bounds=b if first else leaf_bounds.merge(b)
		first=false
	check(absf(leaf_bounds.position.x)<.02 and absf(leaf_bounds.end.x-2.1)<.02,"Leaf is offset from hinge")
	check(absf(leaf_bounds.position.y)<.02 and absf(leaf_bounds.end.y-2.65)<.02,"Leaf height mismatches collider")
	# Sweep real collision shape through both possible opening directions.
	var shape := BoxShape3D.new()
	shape.size=Vector3(2.1,2.61,.13)
	var q:=PhysicsShapeQueryParameters3D.new()
	q.shape=shape
	q.exclude=[section.door.body.get_rid()]
	q.margin=.002
	for side in [-1.0,1.0]:
		for i in range(13):
			var angle: float=side*PI*.49*i/12.0
			var tr: Transform3D=section.door.pivot.global_transform
			tr.basis=tr.basis*Basis(Vector3.UP,angle)
			q.transform=tr*Transform3D(Basis.IDENTITY,Vector3(1.05,1.325,0))
			check(root.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"Door strikes wall at angle %s"%angle)
	check(section.door.toggle(Vector3(0,0,2)),"Open toggle refused")
	await create_timer(.8).timeout
	check(section.door.opened and not section.door.busy,"Open animation incomplete")
	check(ray(Vector3(0,1,2),Vector3(0,1,-2)).is_empty(),"Open passage blocked")
	check(not section.door.toggle(Vector3(0,0,0)),"Door closes through player")
	var player := CharacterBody3D.new()
	var cc:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=.3
	capsule.height=1.76
	cc.shape=capsule
	cc.position.y=.88
	player.add_child(cc)
	player.position=Vector3(0,.02,1.5)
	root.add_child(player)
	await physics_frame
	for i in range(55):
		player.move_and_collide(Vector3(0,0,-.06))
		await physics_frame
	check(player.position.z<-.8,"Player capsule cannot pass door")
	player.position=Vector3(3,0,3)
	check(section.door.toggle(player.position),"Close toggle refused")
	await create_timer(.8).timeout
	check(not section.door.opened and not section.door.busy,"Close animation incomplete")
	check(not ray(Vector3(0,1,2),Vector3(0,1,-2)).is_empty(),"Closed door lost collision")
	if errors.is_empty():
		print("PASS section 02: Blender GLB imports; measured hinge and collider; both door sweeps; capsule passage; close collision; window barrier; near/far LOD and hysteresis; safe close")
		quit(0)
	else:
		for e in errors: push_error(e)
		quit(1)
func collect(node: Node,out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: out.append(node)
	for child in node.get_children(): collect(child,out)
