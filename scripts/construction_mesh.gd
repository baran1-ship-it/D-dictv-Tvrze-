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
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := size.x*.5
	var y := size.y*.5
	var z := size.z*.5
	var b := minf(bevel,minf(x,minf(y,z))*.8)
	var ring := [Vector2(-x+b,-z),Vector2(x-b,-z),Vector2(x,-z+b),Vector2(x,z-b),Vector2(x-b,z),Vector2(-x+b,z),Vector2(-x,z-b),Vector2(-x,-z+b)]
	if irregularity>0:
		var random := RandomNumberGenerator.new()
		random.seed = random_seed
		for i in range(ring.size()):
			var point: Vector2 = ring[i]
			point += Vector2(random.randf_range(-irregularity,irregularity)*size.x,random.randf_range(-irregularity,irregularity)*size.z)
			ring[i] = point
	var top: Array = []
	var bottom: Array = []
	for p in ring:
		top.append(Vector3(p.x,y-b,p.y))
		bottom.append(Vector3(p.x,-y+b,p.y))
	for i in range(8):
		var j := (i+1)%8
		var n := Vector3((ring[i]+ring[j]).x,0,(ring[i]+ring[j]).y).normalized()
		quad(s,[bottom[i],bottom[j],top[j],top[i]],n,Vector2(ring[i].distance_to(ring[j])*.7,size.y*.7) if grain else Vector2.ONE, phase)
		var ti := Vector3(ring[i].x*.98,y,ring[i].y*.98)
		var tj := Vector3(ring[j].x*.98,y,ring[j].y*.98)
		var bi := Vector3(ti.x,-y,ti.z)
		var bj := Vector3(tj.x,-y,tj.z)
		quad(s,[top[i],top[j],tj,ti],(n+Vector3.UP).normalized())
		quad(s,[bottom[j],bottom[i],bi,bj],(n+Vector3.DOWN).normalized())
		for side in [-1,1]:
			var center := Vector3(0,side*y,0)
			var a := Vector3(ti.x,side*y,ti.z)
			var c := Vector3(tj.x,side*y,tj.z)
			var norm: Vector3 = Vector3.UP*side
			var vertices := [center,c,a] if (c-center).cross(a-center).dot(norm)<0 else [center,a,c]
			for v in vertices:
				s.set_normal(norm)
				s.set_uv(Vector2(v.x/size.x+.5,v.z/size.z+.5))
				s.add_vertex(v)
	s.index()
	return s.commit()
