extends RefCounted

# Closed chamfered solids; tiny gaps and variation are geometry, not painted seams.
static func quad(s: SurfaceTool, points: Array, normal: Vector3, uv_scale := Vector2.ONE, phase := Vector2.ZERO) -> void:
	var order := [0,2,1,0,3,2] if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0 else [0,1,2,0,2,3]
	var uv := [Vector2.ZERO,Vector2(uv_scale.x,0),uv_scale,Vector2(0,uv_scale.y)]
	for i in order:
		s.set_normal(normal)
		s.set_uv(uv[i]+phase)
		s.add_vertex(points[i])

static func block(size: Vector3, bevel: float, grain := false, phase := Vector2.ZERO, irregularity := 0.0, random_seed := 0) -> ArrayMesh:
	var Kit = preload("res://scripts/blender_kit.gd")
	var variant := random_seed if random_seed!=0 else int(absf(size.x*631+size.y*193+size.z*317+phase.x*71))
	return Kit.block("plank" if grain and minf(size.x,size.z)<.12 else ("beam" if grain else "quoin"),variant,size,grain,phase)
