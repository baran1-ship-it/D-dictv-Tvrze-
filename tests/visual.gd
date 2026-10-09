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
	await shot("wall-walk.png",Vector3(-16.5,5.1,8),3.25,-.06)
	await shot("stairs-west.png",Vector3(-2.5,.1,2),.95,.22)
	await shot("stairs-tower.png",Vector3(1,.1,9),-.65,.28)
	await shot("gallery-join.png",Vector3(-14.7,5.1,-6.4),1.57,-.03)
	await shot("landing.png",Vector3(-14.7,5.1,-4.1),0,-.35)
	await shot("stairs-gate.png",Vector3(-7,.1,8),1.8,.32)
	await shot("gallery-bearers.png",Vector3(6,.1,12),3.14,.68)
	await shot("vault-palace.png",Vector3(-11,.1,-11),0,.82)
	await shot("vault-east.png",Vector3(12,.1,10),.4,.9)
	await shot("double-gate.png",Vector3(0,.1,12),PI,.28)
	await shot("joint-west.png",Vector3(-14.7,5.1,-4.1),1.57,-.48)
	await shot("joint-gate.png",Vector3(-16.3,5.1,15),-1.57,-.48)
	var south = game.world.doors.filter(func(d): return d.title=="Přístup na hradby")[0]
	south.toggle(Vector3(14.5,5.1,14.1))
	await create_timer(.8).timeout
	await shot("door-swing.png",Vector3(15.6,5.1,14.1),-.3,0)

	print("GEOMETRY: masonry/paving mesh cells=",game.world.relief_cells," individual shingles=",game.world.roof_cells," closed stones=",game.world.stone_count," draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	game.queue_free()
	await process_frame
	quit()
