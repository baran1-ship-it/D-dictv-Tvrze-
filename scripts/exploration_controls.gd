extends Control

signal use_requested
signal look_requested(amount: Vector2)
signal pause_changed(value: bool)

var move_finger := -1
var look_finger := -1
var origin := Vector2.ZERO
var touch_move := Vector2.ZERO
var pad_move := Vector2.ZERO
var pad_look := Vector2.ZERO
var gamepad := -1
var paused := false
var touch_visible := true
var can_use := false
var use_label := "OTEVŘÍT"
var touches: Dictionary = {}
const DEAD_ZONE := 0.18
const LOOK_SPEED := 2.1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_visible = DisplayServer.is_touchscreen_available() or OS.has_feature("android")
	Input.joy_connection_changed.connect(_connection_changed)
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		gamepad = pads[0]
	queue_redraw()

func _connection_changed(device: int, connected: bool) -> void:
	if connected:
		gamepad = device
	elif gamepad == device:
		gamepad = -1
		pad_move = Vector2.ZERO
		pad_look = Vector2.ZERO
		var pads := Input.get_connected_joypads()
		if not pads.is_empty():
			gamepad = pads[0]
		else:
			touch_visible = DisplayServer.is_touchscreen_available() or OS.has_feature("android")
	queue_redraw()

func filtered(value: Vector2) -> Vector2:
	var length := value.length()
	if length <= DEAD_ZONE:
		return Vector2.ZERO
	return value.normalized() * clampf((length - DEAD_ZONE) / (1.0 - DEAD_ZONE), 0.0, 1.0)

func movement() -> Vector2:
	if paused:
		return Vector2.ZERO
	return (touch_move + pad_move).limit_length()

func joystick_center() -> Vector2:
	return Vector2(135, size.y - 135)

func use_center() -> Vector2:
	return Vector2(size.x - 115, size.y - 120)

func pause_rect() -> Rect2:
	return Rect2(size.x - 92, 20, 70, 62)

func resume_rect() -> Rect2:
	return Rect2(size * 0.5 - Vector2(155, 38), Vector2(310, 76))

func toggle_pause() -> void:
	paused = not paused
	reset_touches()
	pause_changed.emit(paused)
	queue_redraw()

func reset_touches() -> void:
	move_finger = -1
	look_finger = -1
	touch_move = Vector2.ZERO
	touches.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_touches()
		pad_move = Vector2.ZERO
		pad_look = Vector2.ZERO
		if not paused and is_inside_tree():
			paused = true
			pause_changed.emit(true)
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		gamepad = event.device
		if absf(event.axis_value) > 0.22:
			touch_visible = false
	if event is InputEventJoypadButton:
		gamepad = event.device
		touch_visible = false
		if event.pressed:
			if event.button_index == JOY_BUTTON_START or (paused and event.button_index == JOY_BUTTON_B):
				toggle_pause()
			elif event.button_index == JOY_BUTTON_A:
				if paused:
					toggle_pause()
				else:
					use_requested.emit()
		get_viewport().set_input_as_handled()
		queue_redraw()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_E and not paused:
			use_requested.emit()
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		touch_visible = true
		if event.pressed:
			if paused:
				if resume_rect().has_point(event.position):
					toggle_pause()
			elif pause_rect().has_point(event.position):
				toggle_pause()
			elif event.position.distance_to(use_center()) < 65:
				touches[event.index] = "use"
				use_requested.emit()
			elif event.position.distance_to(joystick_center()) < 110 and move_finger == -1:
				move_finger = event.index
				origin = joystick_center()
				touch_move = ((event.position - origin) / 78.0).limit_length()
				touches[event.index] = "move"
			elif event.position.x > size.x * 0.35 and look_finger == -1:
				look_finger = event.index
				touches[event.index] = "look"
		else:
			if event.index == move_finger:
				move_finger = -1
				touch_move = Vector2.ZERO
			if event.index == look_finger:
				look_finger = -1
			touches.erase(event.index)
		get_viewport().set_input_as_handled()
		queue_redraw()
	if event is InputEventScreenDrag:
		if not paused:
			if event.index == move_finger:
				touch_move = ((event.position - origin) / 78.0).limit_length()
			elif event.index == look_finger:
				look_requested.emit(event.relative * 0.003)
		get_viewport().set_input_as_handled()
		queue_redraw()

func _process(delta: float) -> void:
	if gamepad >= 0:
		pad_move = filtered(Vector2(Input.get_joy_axis(gamepad, JOY_AXIS_LEFT_X), Input.get_joy_axis(gamepad, JOY_AXIS_LEFT_Y)))
		pad_look = filtered(Vector2(Input.get_joy_axis(gamepad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(gamepad, JOY_AXIS_RIGHT_Y)))
		if not paused and pad_look.length() > 0:
			look_requested.emit(pad_look * LOOK_SPEED * delta)

func centered_text(text: String, center: Vector2, color: Color, font_size := 19) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, center - Vector2(width * 0.5, -6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var pale := Color("eee3c7")
	if paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.025, 0.02, 0.85))
		centered_text("DĚDICTVÍ TVRZE", size * 0.5 - Vector2(0, 125), pale, 28)
		centered_text("Dotyk: levý joystick · tažení vpravo · dveře", size * 0.5 - Vector2(0, 78), pale, 19)
		centered_text("Xbox: levá / pravá páčka · A dveře · Menu pauza", size * 0.5 + Vector2(0, 94), pale, 19)
		draw_style_box(pause_style(), resume_rect())
		centered_text("POKRAČOVAT  /  A", size * 0.5, pale, 22)
		return
	if touch_visible:
		var center := joystick_center()
		draw_circle(center, 95, Color(0.09, 0.07, 0.045, 0.28))
		draw_arc(center, 95, 0, TAU, 64, Color(0.95, 0.88, 0.72, 0.5), 2, true)
		draw_circle(center + touch_move * 66, 32, Color(0.93, 0.85, 0.67, 0.58))
		centered_text("POHYB", center + Vector2(0, 119), pale, 16)
		var use := use_center()
		draw_circle(use, 62, Color(0.1, 0.08, 0.045, 0.6))
		draw_arc(use, 62, 0, TAU, 48, pale if can_use else Color(0.65, 0.61, 0.52, 0.6), 2, true)
		centered_text(use_label if can_use else "DVEŘE", use, pale if can_use else Color("c2b7a0"), 18)
		draw_style_box(pause_style(), pause_rect())
		centered_text("Ⅱ", pause_rect().get_center(), pale, 23)

func pause_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.085, 0.05, 0.7)
	style.set_corner_radius_all(12)
	return style
