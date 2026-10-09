extends Node3D

const SaveStore = preload("res://scripts/save_store.gd")
const WorldStream = preload("res://scripts/world_stream.gd")
var player: CharacterBody3D
var camera: Camera3D
var world: Node3D
var sun: DirectionalLight3D
var hud: Label
var message: Label
var aim: RayCast3D
var pitch := 0.0
var score := 0
var shots := 0
var day := 1
var forge_level := 0
var charge := 0.0
var charging := false
var arrows: Array = []
var stream_clock := 0.0
var move_touch := -1
var look_touch := -1
var move_origin := Vector2.ZERO
var stick := Vector2.ZERO
var interaction_nodes: Dictionary = {}
var forge_upgrade: Node3D

func _ready() -> void:
	setup_inputs()
	var environment = WorldEnvironment.new()
	var settings = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("8bafc0")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("ccd9dc")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color("ffe1af")
	sun.shadow_enabled = true
	add_child(sun)
	world = WorldStream.new()
	add_child(world)
	world.configure(build_chunk)
	world.update_position(Vector3.ZERO)
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1, 9)
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	player.add_child(shape)
	add_child(player)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 75
	camera.far = 500
	player.add_child(camera)
	aim = RayCast3D.new()
	aim.target_position = Vector3(0, 0, -3.2)
	camera.add_child(aim)
	create_bow()
	create_ui()
	var saved = SaveStore.read_save()
	if not saved.is_empty():
		day = int(saved.get("day", 1))
		score = int(saved.get("score", 0))
		shots = int(saved.get("shots", 0))
		forge_level = int(saved.get("forge_level", 0))
		player.position = Vector3(12, 4.3, 8)
	refresh_forge()
	announce("Vítej na tvrzi. Prozkoumej místnosti, zkus luk a ulož hru spánkem.")
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_inputs() -> void:
	for entry in [["forward", KEY_W], ["back", KEY_S], ["left", KEY_A], ["right", KEY_D], ["interact", KEY_E]]:
		if not InputMap.has_action(entry[0]):
			InputMap.add_action(entry[0])
			var event = InputEventKey.new()
			event.physical_keycode = entry[1]
			InputMap.action_add_event(entry[0], event)

func material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func box(parent: Node3D, location: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.position = location
	var mesh = MeshInstance3D.new()
	var geometry = BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = material(color)
	node.add_child(mesh)
	if solid:
		var collider = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		node.add_child(collider)
	parent.add_child(node)
	return node

func interactable(parent: Node3D, id: String, title: String, pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var node = box(parent, pos, size, color)
	node.set_meta("interaction", id)
	node.set_meta("title", title)
	interaction_nodes[id] = node
	return node

func room(parent: Node3D, center: Vector3, size: Vector3, title: String) -> void:
	var stone = Color("777567")
	box(parent, center + Vector3(0, -0.15, 0), Vector3(size.x, 0.3, size.z), Color("938779"))
	box(parent, center + Vector3(0, size.y / 2, -size.z / 2), Vector3(size.x, size.y, 0.5), stone)
	for side in [-1, 1]:
		box(parent, center + Vector3(side * size.x / 2, size.y / 2, 0), Vector3(0.5, size.y, size.z), stone)
		box(parent, center + Vector3(side * (size.x / 4 + 0.65), size.y / 2, size.z / 2), Vector3(size.x / 2 - 1.3, size.y, 0.5), stone)
	box(parent, center + Vector3(0, size.y - 0.25, size.z / 2), Vector3(2.6, 0.5, 0.5), stone)
	box(parent, center + Vector3(0, size.y + 0.15, 0), Vector3(size.x + 0.6, 0.3, size.z + 0.6), Color("4a3b30"))
	var label = Label3D.new()
	label.text = title
	label.font_size = 45
	label.pixel_size = 0.009
	label.position = center + Vector3(0, 2.8, size.z / 2 + 0.3)
	parent.add_child(label)

func fire(parent: Node3D, pos: Vector3) -> void:
	box(parent, pos, Vector3(0.6, 0.25, 0.6), Color("ff9b32"), false)
	var light = OmniLight3D.new()
	light.position = pos + Vector3(0, 0.5, 0)
	light.light_color = Color("ffac59")
	light.light_energy = 2
	light.omni_range = 5
	parent.add_child(light)

func build_chunk(chunk: Node3D, kind: String) -> void:
	if kind == "landscape":
		box(chunk, Vector3(0, -0.6, 0), Vector3(160, 1, 160), Color("67754a"))
		for i in range(24):
			var x = float((i * 37) % 145) - 72
			var z = float((i * 53) % 145) - 72
			box(chunk, Vector3(x, 2, z), Vector3(0.6, 4, 0.6), Color("5e4834"))
			box(chunk, Vector3(x, 5, z), Vector3(4, 5, 4), Color("3f593a"), false)
		return
	box(chunk, Vector3(0, -0.4, 0), Vector3(160, 0.8, 160), Color("667346"))
	box(chunk, Vector3(0, -0.08, 0), Vector3(36, 0.15, 36), Color("a19478"))
	for x in [-18, 18]:
		box(chunk, Vector3(x, 2.5, 0), Vector3(0.8, 5, 36), Color("777c70"))
	box(chunk, Vector3(0, 2.5, -18), Vector3(36, 5, 0.8), Color("777c70"))
	for x in [-10, 10]:
		box(chunk, Vector3(x, 2.5, 18), Vector3(16, 5, 0.8), Color("777c70"))
	interactable(chunk, "gate", "Brána — krajina v příštím rozšíření", Vector3(0, 2, 18), Vector3(4, 4, 0.6), Color("493728"))
	for i in range(19):
		for z in [-18, 18]:
			box(chunk, Vector3(-18 + i * 2, 5.4, z), Vector3(0.9, 0.8, 0.9), Color("777c70"))
	room(chunk, Vector3(-11, 0, -10), Vector3(10, 4, 10), "KOVÁRNA")
	interactable(chunk, "forge", "Kovárna — vylepšit dílnu", Vector3(-13, 0.7, -12), Vector3(1.7, 1.4, 1.2), Color("45464a"))
	box(chunk, Vector3(-8, 0.7, -13), Vector3(2, 1.4, 1.5), Color("55463d"))
	fire(chunk, Vector3(-8, 1.5, -13))
	forge_upgrade = box(chunk, Vector3(-12, 0.6, -8), Vector3(3, 1.2, 1), Color("725034"))
	room(chunk, Vector3(1, 0, -11), Vector3(10, 4, 8), "KUCHYŇ")
	interactable(chunk, "kitchen", "Ohniště — prohlédnout", Vector3(3, 0.5, -13), Vector3(2, 1, 1.5), Color("65605b"))
	fire(chunk, Vector3(3, 1.1, -13))
	box(chunk, Vector3(-1, 0.7, -12), Vector3(2.5, 1.4, 1), Color("705337"))
	room(chunk, Vector3(12, 0, -10), Vector3(8, 4, 12), "HODOVNÍ SÍŇ")
	box(chunk, Vector3(12, 0.9, -10), Vector3(2.5, 0.25, 5), Color("705337"))
	for x in [10, 14]:
		box(chunk, Vector3(x, 0.45, -10), Vector3(0.6, 0.9, 5), Color("5c432f"))
	interactable(chunk, "hearth", "Krb", Vector3(12, 0.8, -15), Vector3(3, 1.6, 1), Color("59534c"))
	fire(chunk, Vector3(12, 0.4, -14.3))
	room(chunk, Vector3(12, 4, 8), Vector3(8, 4, 8), "LOŽNICE")
	for i in range(16):
		box(chunk, Vector3(12, (i + 1) * 0.25 - 0.125, 18 - i * 0.4), Vector3(1.8, 0.25, 0.5), Color("817b6e"))
	box(chunk, Vector3(9, 3.9, 8), Vector3(3, 0.2, 2), Color("817b6e"))
	interactable(chunk, "bed", "Postel — spát a uložit", Vector3(13, 4.4, 7), Vector3(1.8, 0.8, 2.7), Color("8c684c"))
	box(chunk, Vector3(13, 4.85, 6.2), Vector3(1.6, 0.2, 0.6), Color("d1c5a4"), false)
	interactable(chunk, "chest", "Truhla", Vector3(10, 4.4, 6), Vector3(1.3, 0.8, 0.8), Color("59402d"))
	for i in range(3):
		var target = interactable(chunk, "target_" + str(i), "Terč", Vector3(-12 + i * 5, 1.7, 4 - i * 2), Vector3(1.5, 1.5, 0.2), Color("beac7b"))
		target.set_meta("target", true)
		for ring in range(3):
			var disk = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.57 - ring * 0.17
			sphere.height = sphere.radius * 2
			disk.mesh = sphere
			disk.scale.z = 0.06
			disk.position.z = 0.14 + ring * 0.04
			disk.material_override = material([Color("693f32"), Color("d6c99e"), Color("9c392b")][ring])
			target.add_child(disk)
		box(chunk, target.position + Vector3(0, -1, 0), Vector3(0.15, 1.5, 0.15), Color("5b432d"))

func refresh_forge() -> void:
	if is_instance_valid(forge_upgrade):
		forge_upgrade.visible = forge_level > 0
		forge_upgrade.process_mode = Node.PROCESS_MODE_INHERIT if forge_level > 0 else Node.PROCESS_MODE_DISABLED
		for child in forge_upgrade.get_children():
			if child is CollisionShape3D:
				child.set_deferred("disabled", forge_level == 0)

func create_bow() -> void:
	for i in range(9):
		var t = float(i) / 8.0
		var segment = box(camera, Vector3(0.4 + sin(t * PI) * 0.17, -0.4 + t * 0.8, -0.65), Vector3(0.035, 0.12, 0.035), Color("71502e"), false)
		segment.rotation.z = cos(t * PI) * -0.45

func create_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 23)
	layer.add_child(hud)
	message = Label.new()
	message.position = Vector2(24, 105)
	message.add_theme_font_size_override("font_size", 19)
	layer.add_child(message)
	var cross = Label.new()
	cross.text = "+"
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layer.add_child(cross)
	var help = Label.new()
	help.text = "WASD pohyb · myš rozhled · E použít · podrž levé tlačítko: luk · Esc uvolní myš\nDotyk: levá část pohyb · pravá část rozhled · tlačítka AKCE / LUK"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.offset_left = 24
	help.offset_top = -65
	layer.add_child(help)
	for index in range(2):
		var button = Button.new()
		button.text = "AKCE" if index == 0 else "LUK"
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		button.offset_left = -140
		button.offset_top = -230 + index * 90
		button.offset_right = -30
		button.offset_bottom = -160 + index * 90
		layer.add_child(button)
		if index == 0:
			button.pressed.connect(interact)
		else:
			button.button_down.connect(func(): charging = true)
			button.button_up.connect(release_arrow)

func announce(text: String) -> void:
	message.text = text

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative * 0.0025)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			charging = true
		else:
			release_arrow()
	if event.is_action_pressed("interact"):
		interact()
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and move_touch == -1:
				move_touch = event.index
				move_origin = event.position
			elif look_touch == -1:
				look_touch = event.index
		else:
			if event.index == move_touch:
				move_touch = -1
				stick = Vector2.ZERO
			if event.index == look_touch:
				look_touch = -1
	if event is InputEventScreenDrag:
		if event.index == move_touch:
			stick = ((event.position - move_origin) / 75.0).limit_length()
		elif event.index == look_touch:
			look(event.relative * 0.004)

func look(delta: Vector2) -> void:
	player.rotation.y -= delta.x
	pitch = clampf(pitch - delta.y, -1.35, 1.35)
	camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	var input = Input.get_vector("left", "right", "forward", "back") + stick
	input = input.limit_length()
	var direction = player.transform.basis * Vector3(input.x, 0, input.y)
	player.velocity.x = direction.x * 4.0
	player.velocity.z = direction.z * 4.0
	if not player.is_on_floor():
		player.velocity.y -= 20 * delta
	else:
		player.velocity.y = -0.5
	# A small step assist makes the tower staircase usable by a capsule.
	if player.is_on_floor() and direction.length() > 0.1 and player.test_move(player.transform, direction * 0.2):
		var raised = player.transform
		raised.origin.y += 0.3
		if not player.test_move(player.transform, Vector3(0, 0.3, 0)) and not player.test_move(raised, direction * 0.3):
			player.position.y += 0.3
	player.move_and_slide()
	if player.position.y < -10:
		player.position = Vector3(0, 1, 9)
	if charging:
		charge = minf(charge + delta, 1.5)
	update_arrows(delta)
	stream_clock += delta
	if stream_clock > 0.5:
		world.update_position(player.position)
		stream_clock = 0
	var prompt = ""
	if aim.is_colliding():
		var node = aim.get_collider()
		if node.has_meta("title"):
			prompt = "\n[E / AKCE] " + str(node.get_meta("title"))
	hud.text = "DĚDICTVÍ TVRZE  ·  Den %d\nZásahy %d / %d  ·  Kovárna %d/1  ·  Nátah %d %%" % [day, score, shots, forge_level, int(charge / 1.5 * 100)] + prompt

func release_arrow() -> void:
	if not charging:
		return
	charging = false
	if charge < 0.15:
		charge = 0
		return
	var arrow = box(self, camera.global_position - camera.global_basis.z * 0.6, Vector3(0.025, 0.025, 0.7), Color("493326"), false)
	arrow.global_basis = camera.global_basis
	arrows.append({"node": arrow, "velocity": -camera.global_basis.z * (12 + charge * 20), "life": 0.0})
	shots += 1
	charge = 0

func update_arrows(delta: float) -> void:
	for i in range(arrows.size() - 1, -1, -1):
		var arrow = arrows[i]
		arrow.life += delta
		arrow.velocity.y -= 9.8 * delta
		var start: Vector3 = arrow.node.position
		var end: Vector3 = start + arrow.velocity * delta
		var query = PhysicsRayQueryParameters3D.create(start, end)
		query.exclude = [player.get_rid()]
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			if hit.collider.has_meta("target"):
				score += 1
				announce("Zásah! Celkem %d. Postup uložíš v posteli ve věži." % score)
			arrow.node.queue_free()
			arrows.remove_at(i)
		elif arrow.life > 8:
			arrow.node.queue_free()
			arrows.remove_at(i)
		else:
			arrow.node.position = end
			arrow.node.look_at(end + arrow.velocity.normalized())

func interact() -> void:
	aim.force_raycast_update()
	if not aim.is_colliding():
		announce("Přistup blíž a zaměř předmět.")
		return
	var node = aim.get_collider()
	match str(node.get_meta("interaction", "")):
		"bed":
			var next_day = day + 1
			var error = SaveStore.write_save({"day": next_day, "score": score, "shots": shots, "forge_level": forge_level})
			if error == OK:
				day = next_day
				announce("Vyspal ses do rána. Den %d — hra uložena." % day)
			else:
				announce("Uložení selhalo; den se neposunul.")
		"forge":
			if forge_level == 0:
				forge_level = 1
				refresh_forge()
				announce("Dílna má nový pracovní stůl. Změnu uložíš spánkem.")
			else:
				announce("Základní dílna je hotová. Řemeslný postup přijde v další verzi.")
		"gate": announce("Za branou bude navazující otevřený svět. V prototypu je brána uzavřená.")
		"kitchen": announce("Kuchyň je připravena. Vaření přijde po ověření základního prototypu.")
		"hearth": announce("Oheň hřeje hodovní síň.")
		"chest": announce("Tvoje truhla. Inventář bude součástí další etapy.")
