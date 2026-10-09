extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	assert(scene.world.loaded.size() == 5, "Nearby world chunks must load")
	assert(scene.interaction_nodes.has("bed"))
	var target = scene.interaction_nodes["target_0"]
	scene.player.position = Vector3(target.position.x, 0.05, target.position.z + 7)
	scene.player.rotation = Vector3.ZERO
	scene.camera.rotation = Vector3.ZERO
	scene.charging = true
	scene.charge = 1.5
	scene.release_arrow()
	for i in range(80):
		await physics_frame
	assert(scene.score == 1, "Arrow must hit the target")
	# Walk up the full tower staircase using the same movement physics.
	scene.player.position = Vector3(12, 0.1, 17.8)
	scene.player.velocity = Vector3.ZERO
	Input.action_press("forward")
	for i in range(115):
		await physics_frame
	Input.action_release("forward")
	assert(scene.player.position.y > 3.8, "Tower bed must be reachable")
	scene.player.position = Vector3(13, 4.05, 9.5)
	scene.camera.rotation.x = -0.45
	await physics_frame
	scene.aim.force_raycast_update()
	assert(scene.aim.is_colliding(), "Bed must be in interaction range")
	assert(scene.aim.get_collider().get_meta("interaction", "") == "bed")
	var previous_day = scene.day
	scene.forge_level = 1
	scene.interact()
	assert(scene.day == previous_day + 1)
	var saved = scene.SaveStore.read_save()
	assert(saved.score == 1 and saved.forge_level == 1 and saved.day == scene.day)
	scene.world.update_position(Vector3(1000, 0, 1000))
	assert(scene.world.loaded.is_empty(), "Distant chunks must unload")
	scene.queue_free()
	await process_frame
	var restored = load("res://main.tscn").instantiate()
	root.add_child(restored)
	await physics_frame
	assert(restored.score == 1 and restored.forge_level == 1)
	assert(restored.player.position.y > 3.8)
	print("PASS: chunk streaming, arrow collision, tower access, sleep save and reload")
	quit()
