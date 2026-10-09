extends RefCounted

# Irregular convex stones with closed bevelled sides, not a displaced wallpaper.
# Jittered Voronoi cells fill the mortar bed without a repeated tile layout.
static func clip(poly: Array, n: Vector2, limit: float) -> Array:
	var result: Array = []
	if poly.is_empty(): return result
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i+1)%poly.size()]
		var da := a.dot(n)-limit
		var db := b.dot(n)-limit
		if da<=0: result.append(a)
		if (da<=0)!=(db<=0): result.append(a.lerp(b,da/(da-db)))
	return result

static func triangle(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv: Array, normal: Vector3, tint: Color) -> void:
	var vertices := [a,b,c]
	var order := [0,2,1] if (b-a).cross(c-a).dot(normal)>0 else [0,1,2]
	for i in order:
		s.set_normal(normal)
		s.set_color(tint)
		s.set_uv(uv[i])
		s.add_vertex(vertices[i])

static func face(origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, size: Vector2, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var nx := maxi(1,int(ceil(size.x/.48)))
	var ny := maxi(1,int(ceil(size.y/.30)))
	var sites: Array[Vector2] = []
	for j in range(ny):
		for i in range(nx):
			sites.append(Vector2((i+.5+rng.randf_range(-.36,.36))*size.x/nx,(j+.5+rng.randf_range(-.32,.32))*size.y/ny))
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stones := 0
	for j in range(ny):
		for i in range(nx):
			var site := sites[j*nx+i]
			var poly: Array = [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]
			for y in range(maxi(0,j-2),mini(ny,j+3)):
				for x in range(maxi(0,i-2),mini(nx,i+3)):
					var other := sites[y*nx+x]
					if other==site: continue
					poly = clip(poly,other-site,(other.length_squared()-site.length_squared())*.5)
			if poly.size()<3: continue
			var phase := Vector2(rng.randf(),rng.randf())
			var depth := rng.randf_range(.075,.18)
			var tint := Color(rng.randf_range(.80,1.0),rng.randf_range(.81,1.0),rng.randf_range(.79,.96))
			var back: Array[Vector3] = []
			var rim: Array[Vector3] = []
			var front: Array[Vector3] = []
			var tex: Array[Vector2] = []
			for p in poly:
				var edge: Vector2 = site+(p-site)*.965
				back.append(origin+u*edge.x+v*edge.y-normal*.015)
				rim.append(origin+u*edge.x+v*edge.y+normal*depth*.45)
				var inset: Vector2 = site+(edge-site)*.83
				front.append(origin+u*inset.x+v*inset.y+normal*(depth+rng.randf_range(-.012,.012)))
				tex.append(edge*.65+phase)
			var center := origin+u*site.x+v*site.y+normal*(depth+.02)
			var rear := origin+u*site.x+v*site.y-normal*.015
			for k in range(poly.size()):
				var n := (k+1)%poly.size()
				var side := (rim[k]-back[k]).cross(back[n]-back[k]).normalized()
				if side.dot((rim[k]+rim[n])*.5-center)<0: side = -side
				triangle(s,back[k],back[n],rim[n],[tex[k],tex[n],tex[n]],side,tint)
				triangle(s,back[k],rim[n],rim[k],[tex[k],tex[n],tex[k]],side,tint)
				var bevel := ((front[k]-rim[k]).cross(rim[n]-rim[k])).normalized()
				if bevel.dot(normal)<0: bevel = -bevel
				triangle(s,rim[k],rim[n],front[n],[tex[k],tex[n],tex[n]],bevel,tint)
				triangle(s,rim[k],front[n],front[k],[tex[k],tex[n],tex[k]],bevel,tint)
				var fn := (front[k]-center).cross(front[n]-center).normalized()
				if fn.dot(normal)<0: fn = -fn
				triangle(s,center,front[k],front[n],[site*.65+phase,tex[k],tex[n]],fn,tint)
				triangle(s,rear,back[n],back[k],[site*.65+phase,tex[n],tex[k]],-normal,tint)
			stones += 1
	s.index()
	s.generate_tangents()
	return {"mesh":s.commit(),"stones":stones}
