extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,720)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.controls.touch_visible = true
	game.message_time = 0
	game.hint.text = ""
	game.player.position = Vector3(-3,.1,10)
	game.player.rotation.y = -.18
	game.pitch = .06
	game.camera.rotation.x = .06
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/courtyard.png")
	game.player.position = Vector3(-11,.1,-5.9)
	game.player.rotation = Vector3.ZERO
	game.pitch = 0
	game.camera.rotation = Vector3.ZERO
	for i in range(8):
		await physics_frame
	game.interact()
	await create_timer(.29).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/door-hand.png")
	game.queue_free()
	await process_frame
	quit()
