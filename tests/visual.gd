extends SceneTree
var game: Node3D
func _initialize() -> void:
	call_deferred("run")
func shot(file: String, pos: Vector3, yaw: float, pitch: float) -> void:
	game.player.position = pos
	game.player.rotation.y = yaw
	game.pitch = pitch
	game.camera.rotation.x = pitch
	for i in range(4):
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+file)
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.controls.touch_visible = true
	game.message_time = 0
	game.hint.text = ""
	await shot("courtyard.png",Vector3(-2,.1,14.8),-.22,.28)
	await shot("soil-puddle.png",Vector3(-10,.1,10.7),.3,-.43)
	await shot("wall-walk.png",Vector3(-16.5,5.1,8),3.25,-.06)
	await shot("north-corner.png",Vector3(17.5,5.1,-18.5),-.6,-.42)
	await shot("north-walk.png",Vector3(12,5.1,-18.7),1.57,-.15)
	await shot("east-walk.png",Vector3(18.75,5.1,10),0,-.15)
	await shot("corridor-east.png",Vector3(18.75,.1,12),0,.13)
	await shot("corridor-north.png",Vector3(12,.1,-18.70),1.57,.22)
	await shot("vault-palace.png",Vector3(-11,.1,-11),0,.82)
	await shot("vault-east.png",Vector3(12,.1,10),.4,.9)
	await shot("tower-divider.png",Vector3(9.05,5.1,-.35),-1.57,-.08)
	await shot("tower-ground.png",Vector3(14.15,.1,-5.8),-.25,.75)
	await shot("ordinary-door.png",Vector3(-8.8,.1,-5.3),0,.05)
	await shot("double-gate.png",Vector3(0,.1,12),PI,.28)

	print("GEOMETRY: masonry/paving mesh cells=",game.world.relief_cells," individual shingles=",game.world.roof_cells," closed stones=",game.world.stone_count," draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	game.queue_free()
	await process_frame
	quit()
