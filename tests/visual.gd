extends SceneTree
var game: Node3D
func _initialize() -> void:
	call_deferred("run")
func shot(file: String, pos: Vector3, yaw: float, pitch: float) -> void:
	game.player.position = pos
	game.player.rotation.y = yaw
	game.pitch = pitch
	game.camera.rotation.x = pitch
	for i in range(10):
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
	await shot("courtyard.png",Vector3(-3,.1,10),-.18,-.13)
	await shot("east-wing.png",Vector3(-3,.1,8),-.75,-.10)
	await shot("wall-walk.png",Vector3(-16.5,4.6,8),2.9,-.06)
	await shot("tower-stairs.png",Vector3(14,3.7,-.4),1.15,.05)
	await shot("door-hand.png",Vector3(-8.8,.1,-7.0),0,0)
	game.interact()
	await create_timer(.29).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/door-hand.png")
	print("GEOMETRY: masonry/paving=",game.world.stone_count," roof tiles=",game.world.tile_count," draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	game.queue_free()
	await process_frame
	quit()
