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
	await shot("east-wing.png",Vector3(-3,.1,8),-1.25,.20)
	await shot("roof-detail.png",Vector3(-4,4.6,16.6),-.28,.20)
	await shot("wall-walk.png",Vector3(-16.5,4.6,8),3.25,-.06)
	await shot("tower-stairs.png",Vector3(14,3.7,-.4),1.15,.05)
	await shot("south-door.png",Vector3(14.5,4.6,16.9),0,0)
	await shot("gallery-access.png",Vector3(-15.9,3.7,-7.3),PI,-.12)
	await shot("rear-walk.png",Vector3(18.75,4.6,9),0,.08)
	await shot("north-walk.png",Vector3(16.5,4.6,-18.75),1.57,.05)
	await shot("masonry-corner.png",Vector3(-16.5,4.6,15.5),-2.4,.18)
	await shot("landing.png",Vector3(-15.5,1.9,-4.1),0,-.35)
	await shot("tower-landing.png",Vector3(10.6,5.5,-5.7),1.45,-.35)
	await shot("empty-room.png",Vector3(1.8,.1,-10.4),.25,.02)
	var south = game.world.doors.filter(func(d): return d.title=="Přístup na hradby")[0]
	south.toggle(Vector3(14.5,4.6,14.1))
	await create_timer(.8).timeout
	await shot("door-swing.png",Vector3(15.6,4.6,14.1),-.3,0)
	await shot("door-hand.png",Vector3(-8.8,.1,-7.0),0,0)
	game.interact()
	await create_timer(.29).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/door-hand.png")
	print("GEOMETRY: masonry/paving mesh cells=",game.world.relief_cells," individual shingles=",game.world.roof_cells," closed stones=",game.world.stone_count," draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	game.queue_free()
	await process_frame
	quit()
