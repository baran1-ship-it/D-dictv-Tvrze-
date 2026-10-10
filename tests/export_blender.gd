extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scripts/fortress_builder.gd").new()
	root.add_child(world)
	world.build()
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	assert(document.append_from_scene(world,state)==OK)
	assert(document.write_to_filesystem(state,"res://build/tvrz-012-assembled.glb")==OK)
	print("PASS: assembled fortress exported from exact game geometry")
	quit()
