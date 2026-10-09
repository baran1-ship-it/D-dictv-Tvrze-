extends SceneTree
const Masonry = preload("res://scripts/masonry_mesh.gd")
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
	for i in range(900):
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
	check(game.world.doors.size()==24,"22 doors and two gate leaves should be present")
	check(game.world.stair_routes.size()==7,"three straight external stairs and four tower flights including attic should exist")
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
	var door = game.world.doors.filter(func(d): return d.title=="Kovárna")[0]
	check(door.opened and not door.busy,"door opening animation should finish")
	check(not game.hand.visible and not game.using_door,"hand should retract after opening")
	check(await walk_to(Vector3(-8.8,.1,-9.5)),"open doorway should be traversable")
	check(door.toggle(game.player.global_position),"door should close from inside")
	await create_timer(.8).timeout
	check(not door.opened,"door should be closed")
	check(game.player.test_move(game.player.transform,Vector3(0,0,2)),"closed door should block movement")
	check(game.world.windows.size()>=8,"windows should be actual framed openings")
	check(game.world.relief_cells>10000,"masonry and paving must have geometric relief")
	check(game.world.roof_cells>3000,"roof slopes must contain individual overlapping tiles and canopy shingles")
	check(game.world.stone_count>5000,"fortifications must contain closed individual 3D stones")
	check(game.world.mats.has("palace_rock") and game.world.mats.has("tower_rock"),"palace and tower should have separate stone materials")
	check(game.world.mats.has("earth") and game.world.mats.has("clay"),"courtyard earth and tile roofs should be present")
	check(Masonry.yard_path(Vector3(0,0,12)),"main gate path must be paved")
	check(Masonry.yard_path(Vector3(7,0,8)),"east doorway path must be paved")
	check(not Masonry.yard_path(Vector3(-8,0,6)),"unused courtyard should retain earth")
	for w in game.world.windows:
		check(absf(w.x-17)>.01 and absf(w.z+17)>.01,"windows facing the inaccessible inner perimeter must be removed")
	# Sample the corrected wall-side seams, using visible floor footprints as well as collision rays.
	for pos in [Vector3(-17.35,5.0,-6.5),Vector3(-14.7,5.0,-4.1),Vector3(6.85,5.0,-4.8),Vector3(8.4,5.0,.6),Vector3(9.2,2.5,-7.6),Vector3(9.2,6.63,-7.6),Vector3(9.2,9.89,-7.6)]:
		var supported := false
		for f in game.world.floor_patches:
			if absf(f.pos.y-pos.y)<.02 and Rect2(Vector2(f.pos.x,f.pos.z)-f.size*.5,f.size).has_point(Vector2(pos.x,pos.z)): supported = true
		check(supported,"visible landing must reach the wall at "+str(pos))
	# Guard the enlarged tower turning platforms on their exposed side.
	for y in [2.5,6.63,9.89]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(10.9,y+.6,-6.3),Vector3(12.0,y+.6,-6.3))
		query.exclude = [game.player.get_rid()]
		check(not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"tower turning landing needs an effective guard")
	for normal in game.world.roof_normals:
		check(normal.y>0,"all roof faces must point out and upward")
	for d in game.world.doors:
		check(not (d.title=="Obytné křídlo" and d.position.y>1),"upper yard door must be replaced by a window")
		check(absf(d.handle.position.z)<.001,"handle roots must lie on door plane")
	# Test the actual vault crown, first-floor slab and 3 m clear tower storeys.
	check(game.world.vaults.size()==7,"all main ground-floor rooms must have stone vaults")
	for v in game.world.vaults:
		var offset := Vector3(.07,0,.07)
		var query := PhysicsRayQueryParameters3D.create(v.center+offset+Vector3.UP*4.0,v.center+offset+Vector3.UP*4.8)
		query.exclude = [game.player.get_rid()]
		var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.get("position",Vector3.ZERO).y-4.5)<.04,"vault crown must be 4.5 m above the ground floor")
	for level in [5.0,8.26]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(14,level+1,-3.5),Vector3(14,level+3.5,-3.5))
		query.exclude = [game.player.get_rid()]
		var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.get("position",Vector3.ZERO).y-level-3.0)<.03,"tower storey must have 3 m clear height")
	check(game.world.tower_room_doors.size()==4,"all tower storeys need room doors")
	for d in game.world.tower_room_doors:
		check(absf(d.width-1.10)<.001 and absf(d.height-2.10)<.001,"room doors need human proportions")
		d.toggle(d.global_position+Vector3(-1,0,0))
	await create_timer(.8).timeout
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
		if passed:
			for name in ["end","turn","mid","start"]:
				check(await walk_to(route[name]),"stair and landing must also work downhill: "+str(route.start))
	for x in [17.6,18.75,19.8]:
		for z in [-19.9,-18.75,-17.5]:
			var visible := false
			for f in game.world.floor_patches:
				if absf(f.pos.y-5)<.02 and Rect2(Vector2(f.pos.x,f.pos.z)-f.size*.5,f.size).has_point(Vector2(x,z)): visible = true
			check(visible,"north-east corner needs continuous visible floor")
	for d in game.world.tower_room_doors:
		game.player.position = d.to_global(Vector3(0,.1,.65))
		game.player.velocity = Vector3.ZERO
		for frame in range(8): await physics_frame
		check(await walk_to(d.to_global(Vector3(0,.1,-.85))),"tower door must be traversable")
		check(await walk_to(d.to_global(Vector3(0,.1,.65))),"tower doorway must allow return")
	game.player.position = Vector3(18.75,.1,15.4)
	game.player.velocity = Vector3.ZERO
	for frame in range(8): await physics_frame
	for point in [Vector3(18.75,.1,-18.75),Vector3(-16.4,.1,-18.75),Vector3(18.75,.1,-18.75),Vector3(18.75,.1,15.4)]:
		check(await walk_to(point),"vaulted passage must support movement and return")
	# Cross the new groin-vault corner diagonally and back with the real capsule.
	game.player.position = Vector3(18.7,.1,-16.7)
	game.player.velocity = Vector3.ZERO
	for frame in range(8): await physics_frame
	for point in [Vector3(18.7,.1,-18.7),Vector3(16.6,.1,-18.7),Vector3(18.7,.1,-18.7),Vector3(18.7,.1,-16.7)]:
		check(await walk_to(point),"stone portals and groin vault must remain traversable")
	game.player.position = Vector3(14,game.world.ATTIC_Y+.1,-.35)
	game.player.velocity = Vector3.ZERO
	for frame in range(8): await physics_frame
	for point in [Vector3(15.8,game.world.ATTIC_Y+.1,-.35),Vector3(15.8,game.world.ATTIC_Y+.1,-6.7),Vector3(12.4,game.world.ATTIC_Y+.1,-6.7),Vector3(12.4,game.world.ATTIC_Y+.1,-.35)]:
		check(await walk_to(point),"attic must allow standing movement under its roof framing")
	game.player.position = game.world.wall_routes[0]
	game.player.velocity = Vector3.ZERO
	for frame in range(8):
		await physics_frame
	for point in game.world.wall_routes.slice(1):
		var passed: bool = await walk_to(point)
		if not passed:
			print("Wall failure: player=",game.player.position," target=",point)
		check(passed,"wall walk must connect through courtyard corners and across gate")
	var reverse: Array = game.world.wall_routes.duplicate()
	reverse.reverse()
	for point in reverse.slice(1): check(await walk_to(point),"complete wall walk must also allow return")
	game.player.position = Vector3(-14.7,5.1,-6.4)
	game.player.velocity = Vector3.ZERO
	for frame in range(8): await physics_frame
	for point in [Vector3(-16.6,5.1,-6.4),Vector3(-16.6,5.1,-4),Vector3(-16.6,5.1,0),Vector3(-16.6,5.1,-6.4),Vector3(-14.7,5.1,-6.4)]:
		check(await walk_to(point),"palace gallery and wall walk must join at one level")
	# Walk through the complete upper doorway, including its outer railing gap.
	for d in game.world.doors:
		if d.title not in ["Přístup na hradby","Obranný ochoz","Východní hradby"]:
			continue
		game.player.position = d.to_global(Vector3(0,.1,-.65))
		game.player.velocity = Vector3.ZERO
		for frame in range(8):
			await physics_frame
		check(d.toggle(game.player.global_position),"upper access door must open")
		await create_timer(.8).timeout
		var distance := .95 if d.title in ["Přístup na hradby","Východní hradby"] else .5
		check(await walk_to(d.to_global(Vector3(0,.1,distance))),"upper doorway and railing gap must be traversable: "+d.title)
		check(await walk_to(d.to_global(Vector3(0,.1,-1.0))),"upper doorway must work in reverse: "+d.title)
		check(d.toggle(game.player.global_position),"upper access door must close")
		await create_timer(.8).timeout
	# Check the complete swing against static walls and guards, not only the threshold.
	for d in game.world.doors:
		if d.title not in ["Přístup na hradby","Obranný ochoz","Východní hradby"]: continue
		for side in [-1.0,1.0]:
			var direction: float = d.opening_side if d.opening_side!=0 else side
			for i in range(1,13):
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = BoxShape3D.new()
				query.shape.size = Vector3(d.width,d.height-.04,.13)
				var t: Transform3D = d.global_transform*Transform3D(Basis.IDENTITY,d.pivot.position)*Transform3D(Basis(Vector3.UP,direction*PI*.49*i/12),Vector3.ZERO)*d.collider.transform
				query.transform = t
				query.margin = .002
				query.exclude = [d.body.get_rid(),game.player.get_rid()]
				check(game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),"door swing must clear guards and walls: "+d.title+" sample "+str(i))
	# Check every threshold has support on both sides, and no overhead collision.
	for d in game.world.doors:
		for side in [-1,1]:
			for offset in [-d.width*.28,0.0,d.width*.28]:
				var pos: Vector3 = d.to_global(Vector3(offset,.15,side*.65))
				var query := PhysicsRayQueryParameters3D.create(pos+Vector3(0,.15,0),pos-Vector3(0,.65,0))
				query.exclude = [game.player.get_rid()]
				check(not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"door must have a floor on both sides: "+d.title)
	# Probe off-centre approaches and reverse turns where the user became trapped.
	for points in [
		[Vector3(-16.4,5.1,-4.25),Vector3(-15.4,5.1,-4.15),Vector3(-14.7,5.1,-3.7),Vector3(-14.1,5.1,-5.5),Vector3(-16.4,5.1,-4.25)],
		[Vector3(-16.4,5.1,15.3),Vector3(-14.5,5.1,15.0),Vector3(-14.5,5.1,13.9),Vector3(-14.5,5.1,15.0),Vector3(-16.4,5.1,15.3)]]:
		game.player.position = points[0]
		game.player.velocity = Vector3.ZERO
		for frame in range(8): await physics_frame
		for point in points.slice(1): check(await walk_to(point),"stair corner must allow off-centre movement and return")
	var gate = game.world.doors.filter(func(d): return d.title=="Vstupní brána")[0]
	game.player.position = Vector3(0,.1,16.4)
	game.player.velocity = Vector3.ZERO
	check(gate.toggle(game.player.position),"double gate must open as a pair")
	await create_timer(.8).timeout
	check(gate.opened and gate.partner.opened,"both gate leaves must finish opening")
	check(await walk_to(Vector3(0,.1,19.4)),"open double gate must be traversable")
	check(await walk_to(Vector3(0,.1,16.4)),"open double gate must allow return")
	check(gate.toggle(game.player.position),"double gate must close as a pair")
	await create_timer(.8).timeout
	check(not gate.opened and not gate.partner.opened,"both gate leaves must finish closing")
	game.controls.reset_touches()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: exploration, multitouch, controller mapping, animated doors, collision, gallery and three tower floors")
		quit(0)
	else:
		print("FAIL: ",failures)
		quit(1)
