extends RefCounted

const PATH = "user://sleep_save.json"
const SCHEMA = 1

static func read_save() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not value is Dictionary or value.get("schema", 0) != SCHEMA:
		return {}
	return value

static func write_save(state: Dictionary) -> Error:
	var payload = state.duplicate(true)
	payload["schema"] = SCHEMA
	var file = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload))
	file.close()
	# Keep the previous sleep as a recovery copy.
	if FileAccess.file_exists(PATH):
		var backup_error = DirAccess.copy_absolute(PATH, PATH + ".bak")
		if backup_error != OK:
			return backup_error
	return DirAccess.rename_absolute(PATH + ".tmp", PATH)
