extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func own_all(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children(): own_all(child,owner_node)
func run() -> void:
	if FileAccess.file_exists("res://assets/kit/assembled.scn"): DirAccess.remove_absolute("res://assets/kit/assembled.scn")
	var world = load("res://scripts/fortress_builder.gd").new()
	root.add_child(world)
	world.build()
	var kit = preload("res://scripts/blender_kit.gd")
	print("BLENDER variants used: ",kit.uses.size())
	assert(kit.uses.size()==112)
	var assembled := Node3D.new()
	assembled.name = "Fortress012"
	root.add_child(assembled)
	for key in ["rooms","floor_patches","rail_routes","stair_routes","wall_routes","windows","vaults","mats","relief_cells","roof_cells","stone_count","roof_normals"]: assembled.set_meta(key,world.get(key))
	var fingerprint: String = world.source_fingerprint()
	FileAccess.open("res://assets/kit/source-fingerprint.txt",FileAccess.WRITE).store_string(fingerprint)
	assembled.set_meta("source_fingerprint",fingerprint)
	assembled.set_meta("blender_variants",kit.uses.size())
	for child in world.get_children():
		world.remove_child(child)
		assembled.add_child(child)
		own_all(child,assembled)
	var packed := PackedScene.new()
	assert(packed.pack(assembled)==OK)
	assert(ResourceSaver.save(packed,"res://assets/kit/assembled.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("PASS: baked Blender architecture; all 112 source variants used")
	quit()
