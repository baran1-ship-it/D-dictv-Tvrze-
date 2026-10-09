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

static func face(origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, size: Vector2, seed_value: int, style := "curtain", paving := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spacing := Vector2(.43,.29) if style=="curtain" else Vector2(.60,.39)
	if style=="palace": spacing = Vector2(.37,.28)
	if paving: spacing = Vector2(.38,.31) if style=="path" else Vector2(.56,.44)
	var nx := maxi(1,int(ceil(size.x/spacing.x)))
	var ny := maxi(1,int(ceil(size.y/spacing.y)))
	var sites: Array[Vector2] = []
	for j in range(ny):
		for i in range(nx):
			sites.append(Vector2((i+.5+rng.randf_range(-.44,.44))*size.x/nx,(j+.5+rng.randf_range(-.44,.44))*size.y/ny))
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
			if paving:
				var world := origin+u*site.x+v*site.y
				if not yard_path(world): continue
			var phase := Vector2(rng.randf(),rng.randf())
			var depth := rng.randf_range(.014,.038) if not paving else rng.randf_range(.008,.022)
			var shade := rng.randf_range(.83,1.0)
			var tint := Color(shade,shade*rng.randf_range(.96,1.01),shade*rng.randf_range(.91,.98))
			if not paving and origin.y+site.y<.48: tint *= .76
			var back: Array[Vector3] = []
			var rim: Array[Vector3] = []
			var front: Array[Vector3] = []
			var tex: Array[Vector2] = []
			for p in poly:
				var edge: Vector2 = site+(p-site)*rng.randf_range(.95,.975)
				back.append(origin+u*edge.x+v*edge.y-normal*.015)
				rim.append(origin+u*edge.x+v*edge.y+normal*depth*.45)
				var inset: Vector2 = site+(edge-site)*.91
				front.append(origin+u*inset.x+v*inset.y+normal*(depth+rng.randf_range(-.012,.012)))
				tex.append(edge*.65+phase)
			var center := origin+u*site.x+v*site.y+normal*(depth+.007)
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
	if stones==0: return {"mesh":ArrayMesh.new(),"stones":0}
	s.index()
	s.generate_tangents()
	return {"mesh":s.commit(),"stones":stones}

# Routes follow gate, room entrances and the covered gallery; unused edges remain earth.
static func yard_path(p: Vector3) -> bool:
	var main := absf(p.x-.55*sin(p.z*.24))<1.55
	var east := absf(p.z-8.0)<1.2 and p.x>-.7
	var north := p.z<-5.0
	var entry := p.z>15.5 and absf(p.x)<3.1
	var stair := absf(p.z-14.5)<1.0 and p.x<-2
	var edge := absf(p.x)>16.7 or p.z>16.5
	return main or east or north or entry or stair or edge

# One spatial damage field across adjacent wall pieces avoids rectangular plaster stickers.
static func plaster(origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, size: Vector2, interior := false) -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := maxi(1,int(ceil(size.x/.23)))
	var ny := maxi(1,int(ceil(size.y/.23)))
	for y in range(ny):
		for x in range(nx):
			var a := Vector2(float(x)/nx*size.x,float(y)/ny*size.y)
			var b := Vector2(float(x+1)/nx*size.x,float(y+1)/ny*size.y)
			var corners: Array = [Vector2(a.x,a.y),Vector2(b.x,a.y),Vector2(b.x,b.y),Vector2(a.x,b.y)]
			var poly: Array = []
			var values: Array = []
			for point in corners:
				var p: Vector3 = origin+u*point.x+v*point.y
				var field := sin(p.x*.51+p.z*.31)+.55*sin(p.x*1.31-p.z*.67+p.y*.47)+.35*cos(p.y*1.15+p.x*.74)+.12*sin(p.x*11+p.y*13+p.z*9)
				values.append(maxf(field-(1.75 if interior else .95),(.55-p.y)*4))
			for k in range(4):
				var next := (k+1)%4
				if values[k]<=0: poly.append(corners[k])
				if (values[k]<=0)!=(values[next]<=0): poly.append(corners[k].lerp(corners[next],values[k]/(values[k]-values[next])))
			if poly.size()<3: continue
			for k in range(1,poly.size()-1):
				triangle(s,origin+u*poly[0].x+v*poly[0].y,origin+u*poly[k].x+v*poly[k].y,origin+u*poly[k+1].x+v*poly[k+1].y,[poly[0],poly[k],poly[k+1]],normal,Color.WHITE)
	s.index()
	return s.commit()
