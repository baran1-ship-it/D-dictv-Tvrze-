extends RefCounted
static var groups: Dictionary = {}
static var cached: Dictionary = {}
static var uses: Dictionary = {}
static func ensure_loaded() -> void:
	if not groups.is_empty(): return
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/kit/fortress-kit.json"))
	var bytes := Marshalls.base64_to_raw(envelope.zlib_base64).decompress(int(envelope.length),FileAccess.COMPRESSION_DEFLATE)
	var data: Dictionary = JSON.parse_string(bytes.get_string_from_utf8())
	assert(int(data.count)==112 and str(data.generator).begins_with("Blender"))
	for asset in data.assets:
		if not groups.has(asset.group): groups[asset.group] = []
		groups[asset.group].append(asset)
static func emit(s: SurfaceTool, group: String, variant: int, transform: Transform3D, tint := Color.WHITE, phase := Vector2.ZERO, uv_scale := Vector2.ONE) -> void:
	ensure_loaded()
	var number := posmod(variant,groups[group].size())
	var asset: Dictionary = groups[group][number]
	uses[asset.name] = int(uses.get(asset.name,0))+1
	var mirrored := transform.basis.determinant()<0
	var damp := tint.r<.8
	var key := group+str(number)+str(mirrored)+str(damp)+str(uv_scale.snapped(Vector2.ONE*.01))
	if not cached.has(key):
		var source := SurfaceTool.new()
		source.begin(Mesh.PRIMITIVE_TRIANGLES)
		var shade := .9+float((number*7)%13)*.014
		var color := Color(shade,shade*(.98+float(number%4)*.008),shade*(.96+float(number%5)*.012))
		if damp: color *= .78
		var offset := Vector2((number%2)*.5,(number%4/2)*.5)+Vector2(.035,.035)
		if group in ["beam","plank"]: offset = Vector2(number*.17,number*.13)
		if group in ["tile","shingle"]: offset = Vector2((number%11+.23)/11.0,number*.13)
		if group in ["quoin","plaster"]: offset = Vector2.ZERO
		var order := [0,1,2] if mirrored else [0,2,1]
		for triangle in range(0,asset.rows.size(),3):
			for j in order:
				var row: Array = asset.rows[triangle+j]
				source.set_normal(Vector3(row[3],row[4],row[5]))
				source.set_color(color)
				source.set_uv(Vector2(row[6],row[7])*uv_scale+offset)
				source.add_vertex(Vector3(row[0],row[1],row[2]))
		source.index()
		cached[key] = source.commit()
	# Native append shares evaluated meshes; avoids interpreting each placed vertex.
	s.append_from(cached[key],0,transform)
static func block(group: String, variant: int, size: Vector3, grain := false, phase := Vector2.ZERO) -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	emit(s,group,variant,Transform3D(Basis.from_scale(size),Vector3.ZERO),Color.WHITE,phase,Vector2(.25,size.y*.7) if grain else Vector2.ONE)
	s.index()
	s.generate_tangents()
	return s.commit()
