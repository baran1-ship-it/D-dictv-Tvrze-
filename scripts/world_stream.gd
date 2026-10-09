extends Node3D

# Stable chunk IDs are independent of player saves. Builders may later be replaced
# by packed scenes supplied in signed, versioned content packages.
var definitions: Array = []
var loaded: Dictionary = {}
var build_chunk: Callable

func configure(builder: Callable) -> void:
	build_chunk = builder
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://content/world.json"))
	definitions = manifest.chunks

func update_position(position: Vector3) -> void:
	for definition in definitions:
		var center = Vector3(definition.center[0], 0, definition.center[1])
		var distance = Vector2(position.x - center.x, position.z - center.z).length()
		var id: String = definition.id
		if distance < float(definition.radius) + 90.0 and not loaded.has(id):
			var chunk = Node3D.new()
			chunk.name = id
			chunk.position = center
			add_child(chunk)
			build_chunk.call(chunk, definition.builder)
			loaded[id] = chunk
		elif distance > float(definition.radius) + 125.0 and loaded.has(id):
			loaded[id].queue_free()
			loaded.erase(id)
