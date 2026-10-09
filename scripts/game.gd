extends Node3D
const Fortress = preload("res://scripts/fortress_builder.gd")
const Controls = preload("res://scripts/exploration_controls.gd")
var player: CharacterBody3D
var camera: Camera3D
var world: Node3D
var aim: RayCast3D
var controls: Control
var hud: Label
var hint: Label
var hand: Node3D
var palm: Node3D
var forearm: MeshInstance3D
var pitch := 0.0
var using_door := false
var target_door: Node3D
var message_time := 0.0
var clock := 0.0

func _ready() -> void:
	setup_environment()
	world = Fortress.new()
	add_child(world)
	world.build()
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0,.12,12)
	player.floor_snap_length = .35
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .3
	capsule.height = 1.76
	shape.shape = capsule
	shape.position.y = .88
	player.add_child(shape)
	add_child(player)
	camera = Camera3D.new()
	camera.position.y = 1.63
	camera.fov = 72
	camera.near = .05
	camera.far = 140
	player.add_child(camera)
	aim = RayCast3D.new()
	aim.target_position = Vector3(0,0,-2.8)
	aim.add_exception(player)
	camera.add_child(aim)
	create_hand()
	create_ui()
	if not controls.touch_visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	announce("Prozkoumej tvrz. Zaměř dveře a použij DVEŘE nebo A na ovladači.",8)

func setup_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("557eaa")
	sky_mat.sky_horizon_color = Color("a6bdcc")
	sky_mat.sky_curve = .12
	sky_mat.ground_bottom_color = Color("5b6052")
	sky_mat.ground_horizon_color = Color("c3c9c4")
	sky.sky_material = sky_mat
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	settings.ambient_light_energy = .35
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.fog_enabled = true
	settings.fog_light_color = Color("bac3c1")
	settings.fog_density = .0014
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46,-32,0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = .8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = .04
	add_child(sun)

func create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	controls = Controls.new()
	layer.add_child(controls)
	controls.look_requested.connect(look)
	controls.use_requested.connect(interact)
	controls.pause_changed.connect(func(value: bool):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value or controls.touch_visible else Input.MOUSE_MODE_CAPTURED)
	hud = Label.new()
	hud.position = Vector2(24,20)
	hud.add_theme_font_size_override("font_size",20)
	hud.add_theme_color_override("font_color",Color("eee6ce"))
	hud.add_theme_color_override("font_shadow_color",Color(0,0,0,.8))
	hud.add_theme_constant_override("shadow_offset_x",2)
	hud.add_theme_constant_override("shadow_offset_y",2)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(24,88)
	hint.size = Vector2(860,70)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size",18)
	hint.add_theme_color_override("font_shadow_color",Color(0,0,0,.8))
	hint.add_theme_constant_override("shadow_offset_x",2)
	hint.add_theme_constant_override("shadow_offset_y",2)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hint)
	var cross := Label.new()
	cross.text = "·"
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.add_theme_font_size_override("font_size",26)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cross)

func announce(text: String, duration := 3.0) -> void:
	hint.text = text
	message_time = duration

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not controls.paused:
		look(event.relative*.0022)
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not controls.paused:
		if not controls.touch_visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			interact()

func look(amount: Vector2) -> void:
	if using_door or controls.paused:
		return
	player.rotation.y -= amount.x
	pitch = clampf(pitch-amount.y,-1.28,1.28)
	camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if controls.paused:
		player.velocity = Vector3.ZERO
		return
	var keys := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var input: Vector2 = (keys+controls.movement()).limit_length() if not using_door else Vector2.ZERO
	var direction: Vector3 = player.transform.basis*Vector3(input.x,0,input.y)
	player.velocity.x = direction.x*3.3
	player.velocity.z = direction.z*3.3
	if player.is_on_floor():
		player.velocity.y = -.5
	else:
		player.velocity.y -= 18*delta
	if player.is_on_floor() and direction.length()>.1 and player.test_move(player.transform,direction*.14):
		var raised := player.transform
		raised.origin.y += .23
		if not player.test_move(player.transform,Vector3(0,.23,0)) and not player.test_move(raised,direction*.25):
			player.position.y += .23
	player.move_and_slide()
	if player.position.y < -5:
		player.position = Vector3(0,.12,12)
	clock += delta
	var bob := sin(clock*8)*.015*input.length() if player.is_on_floor() else 0.0
	camera.position.y = lerpf(camera.position.y,1.63+bob,delta*10)
	update_target()
	if message_time>0:
		message_time -= delta
		if message_time<=0:
			hint.text = ""

func update_target() -> void:
	target_door = null
	if aim.is_colliding():
		var node = aim.get_collider()
		if node.has_meta("door"):
			target_door = node.get_meta("door")
	var place := "Nádvoří"
	for room in world.rooms:
		if room.rect.has_point(Vector2(player.position.x,player.position.z)):
			place = room.name
			break
	if place=="Věž":
		var floor := clampi(int((player.position.y+.15)/3.6),0,3)
		place += " · "+("přízemí" if floor==0 else str(floor)+". patro")
	hud.text = "DĚDICTVÍ TVRZE\n"+place
	controls.can_use = is_instance_valid(target_door) and not target_door.busy
	controls.use_label = "ZAVŘÍT" if is_instance_valid(target_door) and target_door.opened else "OTEVŘÍT"
	if is_instance_valid(target_door):
		hud.text += "\n"+target_door.title+" · "+("A" if controls.gamepad>=0 and not controls.touch_visible else "DVEŘE" if controls.touch_visible else "E")
	controls.queue_redraw()

func interact() -> void:
	if controls.paused or using_door:
		return
	aim.force_raycast_update()
	update_target()
	if not is_instance_valid(target_door):
		announce("Přistup ke dveřím a zaměř je.")
		return
	var door: Node3D = target_door
	if door.busy:
		return
	if camera.global_position.distance_to(door.grasp_position(camera.global_position))>1.35:
		announce("Přistup ještě blíž k madlu dveří.")
		return
	if door.opened and door.blocked_by(player.global_position):
		announce("Ustup z průchodu, aby šly dveře zavřít.")
		return
	using_door = true
	var grasp: Vector3 = door.grasp_position(camera.global_position)
	var target := camera.to_local(grasp)
	var rest := Vector3(.42,-.5,-.24)
	hand.position = rest
	hand.visible = true
	var tween := create_tween()
	tween.tween_property(hand,"position",target,.27).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		palm.rotation.x = -.2
		door.toggle(player.global_position))
	tween.tween_interval(.33)
	tween.tween_property(hand,"position",rest,.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		hand.visible = false
		palm.rotation.x = 0
		using_door = false)

func create_hand() -> void:
	hand = Node3D.new()
	camera.add_child(hand)
	hand.visible = false
	palm = Node3D.new()
	hand.add_child(palm)
	var skin: Material = world.mats.skin
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color("655447")
	leather.roughness = .95
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = .075
	shape.height = .16
	mesh.mesh = shape
	mesh.scale = Vector3(.95,.46,1.35)
	mesh.material_override = skin
	palm.add_child(mesh)
	for i in range(4):
		var finger := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = .013
		capsule.height = .095-float(abs(1-i))*.008
		finger.mesh = capsule
		finger.material_override = skin
		finger.rotation.x = PI/2-.25
		finger.position = Vector3(-.045+i*.029,-.008,-.09)
		palm.add_child(finger)
	var thumb := MeshInstance3D.new()
	var thumb_mesh := CapsuleMesh.new()
	thumb_mesh.radius = .019
	thumb_mesh.height = .08
	thumb.mesh = thumb_mesh
	thumb.material_override = skin
	thumb.rotation = Vector3(.65,0,-.75)
	thumb.position = Vector3(.065,-.02,-.012)
	palm.add_child(thumb)
	forearm = MeshInstance3D.new()
	var sleeve := CylinderMesh.new()
	sleeve.top_radius = .055
	sleeve.bottom_radius = .065
	sleeve.height = .45
	sleeve.radial_segments = 16
	forearm.mesh = sleeve
	forearm.material_override = leather
	hand.add_child(forearm)

func _process(_delta: float) -> void:
	if is_instance_valid(hand) and hand.visible:
		var elbow := Vector3(.30,-.48,-.48)
		var wrist := hand.position+Vector3(0,0,.08)
		var length := wrist.distance_to(elbow)
		forearm.global_transform = camera.global_transform*Transform3D(Basis(Quaternion(Vector3.UP,(wrist-elbow).normalized())).scaled(Vector3(1,length/.45,1)),(wrist+elbow)*.5)
