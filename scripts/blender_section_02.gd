extends Node3D
## Standalone, measured asset. Existing fortress is unchanged until this section is approved.
const Door = preload("res://scripts/fortress_door.gd")
const StaticNear = preload("res://assets/blender/section-02/section-static.glb")
const StaticFar = preload("res://assets/blender/section-02/section-lod1.glb")
const Leaf = preload("res://assets/blender/section-02/door-leaf.glb")
var door: Node3D
var near_visual: Node3D
var far_visual: Node3D
var wall_body: StaticBody3D
var last_lod := -1
func _ready() -> void:
	near_visual = StaticNear.instantiate()
	far_visual = StaticFar.instantiate()
	add_child(near_visual)
	add_child(far_visual)
	far_visual.visible = false
	wall_body = StaticBody3D.new()
	add_child(wall_body)
	# Identical wall thickness and door/window openings to fortress_builder.gd.
	block(Vector3(-2.315,1.36,0),Vector3(2.37,2.72,.6))
	block(Vector3(2.315,1.36,0),Vector3(2.37,2.72,.6))
	block(Vector3(0,3.82,0),Vector3(7,2.2,.6))
	block(Vector3(-2.08,5.57,0),Vector3(2.84,1.3,.6))
	block(Vector3(2.08,5.57,0),Vector3(2.84,1.3,.6))
	block(Vector3(0,6.71,0),Vector3(7,.98,.6))
	block(Vector3(0,5.57,0),Vector3(1.32,1.3,.03))
	block(Vector3(0,-.08,2.65),Vector3(9,.16,5.9))
	for y in [3.6,7.2]:
		block(Vector3(0,y-.09,-.65),Vector3(7,.18,1.9))
	var wood := StandardMaterial3D.new()
	var iron := StandardMaterial3D.new()
	door = Door.new()
	add_child(door)
	door.configure(wood,iron,"Obytné křídlo")
	# Retain original gameplay collider, hinge, tween, grasp point and metadata.
	for child in door.body.get_children():
		if child is MeshInstance3D:
			door.body.remove_child(child)
			child.free()
	for child in door.handle.get_children():
		door.handle.remove_child(child)
		child.free()
	door.body.add_child(Leaf.instantiate())
func block(pos: Vector3,size: Vector3) -> void:
	var c := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=size
	c.shape=shape
	c.position=pos
	wall_body.add_child(c)
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var distance := camera.global_position.distance_to(to_global(Vector3(0,3.6,0)))
	var lod := 1 if distance>22.0 else 0
	# Hysteresis prevents flickering at the threshold.
	if last_lod==0 and distance<24.0: lod=0
	if last_lod==1 and distance>20.0: lod=1
	if lod != last_lod:
		near_visual.visible=lod==0
		far_visual.visible=lod==1
		last_lod=lod
