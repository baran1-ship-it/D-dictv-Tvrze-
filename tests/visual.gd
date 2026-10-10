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
	await shot("corridor-corner.png",Vector3(18.7,.1,-18.2),.8,.85)
	await shot("corridor-portal-east.png",Vector3(18.7,.1,-14.8),0,.58)
	await shot("corridor-portal-north.png",Vector3(14.8,.1,-18.7),-1.57,.55)
	await shot("south-wall-walk.png",Vector3(11.7,5.1,16.5),-1.57,.0)
	await shot("building-corner.png",Vector3(18.75,5.1,14.2),1.0,.35)
	await shot("tower-room-1.png",Vector3(14.15,5.1,-.1),0,.48)
	await shot("tower-room-2.png",Vector3(14.15,8.36,-.1),0,.48)
	await shot("tower-room-3.png",Vector3(14.15,11.62,-.1),0,.58)
	await shot("tower-stair-ceiling.png",Vector3(9.1,5.1,-.35),0,.55)
	await shot("attic-access.png",Vector3(10.82,14.0,-2.3),PI,.4)
	await shot("attic-roof.png",Vector3(14.4,15.01,-.35),.3,.72)
	await shot("attic-room.png",Vector3(15.8,15.01,-.35),.6,.24)
	await shot("attic-floor.png",Vector3(15.9,15.01,-6.7),2.55,-.35)
	await shot("wooden-ceiling.png",Vector3(12.5,5.1,8),.3,.8)
	await shot("ordinary-jamb.png",Vector3(-8.2,.1,-6.8),.32,.52)
	await shot("tower-jamb.png",Vector3(12.2,8.36,-.35),1.57,.4)

	await shot("rubble-detail.png",Vector3(18.75,5.1,9.2),-1.57,-.16)
	await shot("paving-detail.png",Vector3(1,.1,11),0,-.7)
	await shot("plaster-detail.png",Vector3(-1,5.1,-6.6),.0,.16)
	print("GEOMETRY: masonry/paving mesh cells=",game.world.relief_cells," individual shingles=",game.world.roof_cells," closed stones=",game.world.stone_count," draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	game.queue_free()
	await process_frame
	quit()
