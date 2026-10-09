extends RefCounted

# Subtract the tower envelope while preserving UVs, normals and vertex colours.
# The cut terminates in the masonry; no neighbouring roof can enter a tower room.
const MINIMUM := Vector3(7.64,7.98,-8.36)
const MAXIMUM := Vector3(17.36,14.4,1.36)

static func split(poly: Array, axis: int, limit: float, less: bool) -> Array:
	var out: Array = []
	if poly.is_empty(): return out
	for i in range(poly.size()):
		var a: Dictionary = poly[i]
		var b: Dictionary = poly[(i+1)%poly.size()]
		var da: float = (a.p[axis]-limit)*(1.0 if less else -1.0)
		var db: float = (b.p[axis]-limit)*(1.0 if less else -1.0)
		if da<=0: out.append(a)
		if (da<=0)!=(db<=0):
			var t := da/(da-db)
			out.append({"p":a.p.lerp(b.p,t),"n":a.n.lerp(b.n,t).normalized(),"uv":a.uv.lerp(b.uv,t),"c":a.c.lerp(b.c,t)})
	return out

static func outside(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		for i in range(vertices.size()): indices.append(i)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,indices.size(),3):
		var remaining: Array = []
		for j in range(3):
			var k := indices[i+j]
			remaining.append({"p":vertices[k],"n":normals[k],"uv":uvs[k],"c":colors[k] if not colors.is_empty() else Color.WHITE})
		for plane in [[0,MINIMUM.x,false],[0,MAXIMUM.x,true],[1,MINIMUM.y,false],[1,MAXIMUM.y,true],[2,MINIMUM.z,false],[2,MAXIMUM.z,true]]:
			var fragment := split(remaining,plane[0],plane[1],not plane[2])
			for triangle in range(1,fragment.size()-1):
				for v in [fragment[0],fragment[triangle],fragment[triangle+1]]:
					surface.set_normal(v.n)
					surface.set_uv(v.uv)
					surface.set_color(v.c)
					surface.add_vertex(v.p)
			remaining = split(remaining,plane[0],plane[1],plane[2])
			if remaining.is_empty(): break
	surface.index()
	return surface.commit()

static func beam_parts(a: Vector3, b: Vector3) -> Array:
	var entry := 0.0
	var leave := 1.0
	var delta := b-a
	for axis in range(3):
		if absf(delta[axis])<.0001:
			if a[axis]<MINIMUM[axis] or a[axis]>MAXIMUM[axis]: return [[a,b]]
		else:
			var t0 := (MINIMUM[axis]-a[axis])/delta[axis]
			var t1 := (MAXIMUM[axis]-a[axis])/delta[axis]
			entry = maxf(entry,minf(t0,t1))
			leave = minf(leave,maxf(t0,t1))
	if entry>=leave: return [[a,b]]
	var parts: Array = []
	if entry>.001: parts.append([a,a.lerp(b,entry)])
	if leave<.999: parts.append([a.lerp(b,leave),b])
	return parts
