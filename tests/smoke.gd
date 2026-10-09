extends SceneTree
var game: Node3D
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	game.controls._input(event)

func walk_to(target: Vector3) -> bool:
	for i in range(350):
		var current: Vector3 = game.player.position
		var offset := Vector2(target.x-current.x,target.z-current.z)
		if offset.length()<.22:
			game.controls.touch_move = Vector2.ZERO
			for frame in range(8):
				await physics_frame
			return absf(game.player.position.y-target.y)<.38
		game.controls.touch_move = offset.normalized()*minf(1,offset.length()*3)
		await physics_frame
	game.controls.touch_move = Vector2.ZERO
	return false

func run() -> void:
	Engine.time_scale = 2.0
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for frame in range(10):
		await physics_frame
	check(game.world.doors.size()==18,"18 usable doors should be present")
	check(game.world.stair_routes.size()==7,"gallery, wall access and three tower flights should exist")
	check(not game.has_method("release_arrow"),"archery must be absent")
	var c = game.controls
	var center: Vector2 = c.joystick_center()
	touch(2,center,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = center+Vector2(0,-70)
	drag.relative = Vector2(0,-70)
	c._input(drag)
	check(c.movement().y<-.8,"touch joystick should move forward")
	touch(3,Vector2(800,300),true)
	var before: float = game.player.rotation.y
	drag.index = 3
	drag.position = Vector2(820,300)
	drag.relative = Vector2(20,0)
	c._input(drag)
	check(game.player.rotation.y<before,"independent touch look should rotate camera")
	touch(3,Vector2(820,300),false)
	check(c.movement().y<-.8,"releasing look finger must retain movement")
	touch(2,center,false)
	check(c.movement()==Vector2.ZERO,"movement must stop when its finger lifts")
	check(c.filtered(Vector2(.08,.08))==Vector2.ZERO,"Xbox stick dead zone should remove drift")
	check(c.filtered(Vector2(1,0)).x==1.0,"Xbox stick should retain full speed")
	var menu := InputEventJoypadButton.new()
	menu.device = 0
	menu.button_index = JOY_BUTTON_START
	menu.pressed = true
	c._input(menu)
	check(c.paused,"Xbox menu should pause")
	menu.button_index = JOY_BUTTON_A
	c._input(menu)
	check(not c.paused,"Xbox A should resume")
	c.gamepad = -1
	game.player.rotation = Vector3.ZERO
	game.pitch = 0
	game.camera.rotation = Vector3.ZERO
	game.player.position = Vector3(-8.8,.1,-7.0)
	for frame in range(8):
		await physics_frame
	game.interact()
	check(game.using_door and game.hand.visible,"using a door should reach with a visible hand")
	await create_timer(1.2).timeout
	var door = game.world.doors[1]
	check(door.opened and not door.busy,"door opening animation should finish")
	check(not game.hand.visible and not game.using_door,"hand should retract after opening")
	check(await walk_to(Vector3(-8.8,.1,-9.5)),"open doorway should be traversable")
	check(door.toggle(game.player.global_position),"door should close from inside")
	await create_timer(.8).timeout
	check(not door.opened,"door should be closed")
	check(game.player.test_move(game.player.transform,Vector3(0,0,2)),"closed door should block movement")
	check(game.world.windows.size()>20,"windows should be actual framed openings")
	check(game.world.relief_cells>10000,"masonry and paving must have geometric relief")
	check(game.world.roof_cells>3000,"roof slopes must have physically displaced scanned tiles")
	for normal in game.world.roof_normals:
		check(normal.y>0,"all roof faces must point out and upward")
	for d in game.world.doors:
		check(not (d.title=="Obytné křídlo" and d.position.y>1),"upper yard door must be replaced by a window")
		check(absf(d.handle.position.z)<.001,"handle roots must lie on door plane")
	# Verify the actual capsule climbs each staircase, not just geometric markers.
	for route in game.world.stair_routes:
		game.player.position = route.start
		game.player.velocity = Vector3.ZERO
		for frame in range(8):
			await physics_frame
		var passed := true
		for name in ["mid","turn","end","exit"]:
			if not await walk_to(route[name]):
				passed = false
				print("Stair failure: ",name," player=",game.player.position," target=",route[name])
				break
		check(passed,"capsule should climb staircase from "+str(route.start))
	game.player.position = game.world.wall_routes[0]
	game.player.velocity = Vector3.ZERO
	for frame in range(8):
		await physics_frame
	for point in game.world.wall_routes.slice(1):
		var passed: bool = await walk_to(point)
		if not passed:
			print("Wall failure: player=",game.player.position," target=",point)
		check(passed,"wall walk must connect through courtyard corners and across gate")
	# Walk through the complete upper doorway, including its outer railing gap.
	for d in game.world.doors:
		if d.title not in ["Přístup na hradby","Obranný ochoz"]:
			continue
		game.player.position = d.to_global(Vector3(0,.1,-.65))
		game.player.velocity = Vector3.ZERO
		for frame in range(8):
			await physics_frame
		check(d.toggle(game.player.global_position),"upper access door must open")
		await create_timer(.8).timeout
		var distance := .95 if d.title=="Přístup na hradby" else .5
		check(await walk_to(d.to_global(Vector3(0,.1,distance))),"upper doorway and railing gap must be traversable: "+d.title)
		check(await walk_to(d.to_global(Vector3(0,.1,-1.0))),"upper doorway must work in reverse: "+d.title)
		check(d.toggle(game.player.global_position),"upper access door must close")
		await create_timer(.8).timeout
	# Check every threshold has support on both sides, and no overhead collision.
	for d in game.world.doors:
		for side in [-1,1]:
			for offset in [-.7,0.0,.7]:
				var pos: Vector3 = d.to_global(Vector3(offset,.15,side*.65))
				var query := PhysicsRayQueryParameters3D.create(pos+Vector3(0,.15,0),pos-Vector3(0,.65,0))
				query.exclude = [game.player.get_rid()]
				check(not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"door must have a floor on both sides: "+d.title)
	game.controls.reset_touches()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: exploration, multitouch, controller mapping, animated doors, collision, gallery and three tower floors")
		quit(0)
	else:
		print("FAIL: ",failures)
		quit(1)
