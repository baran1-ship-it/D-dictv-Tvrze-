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

static func face(origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, size: Vector2, seed_value: int, style := "curtain", paving := false, covered := false, interior := false, min_y := -100.0, triangular := false) -> Dictionary:
	var Kit = preload("res://scripts/blender_kit.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stones := 0
	var y := 0.0
	var row := 0
	while y<size.y-.004:
		var h := minf(rng.randf_range(.18,.29) if not paving else rng.randf_range(.32,.58),size.y-y)
		var x := 0.0
		while x<size.x-.004:
			var w := minf(rng.randf_range(.28,.63) if not paving else rng.randf_range(.38,.77),size.x-x)
			if x==0 and row%2: w *= .58
			var center := origin+u*(x+w*.5)+v*(y+h*.5)
			var allowed := true
			if paving and style=="path" and not yard_path(center): allowed = false
			if triangular and y+h>size.y*(1-absf((x+w*.5)/size.x*2-1))-w*size.y/size.x: allowed = false
			if covered and plaster_field(center,interior,min_y)<-.32: allowed = false
			if allowed and w>.018 and h>.018:
				var thickness := rng.randf_range(.035,.065) if not paving else .025
				var basis := Basis(u*w*.985,v*h*.97,normal*thickness)
				if paving:
					basis = Basis(normal,rng.randf_range(-.10,.10))*basis
					center += u*rng.randf_range(-.008,.008)+v*rng.randf_range(-.008,.008)
				var transform := Transform3D(basis,center+normal*(.008 if not paving else -.004))
				Kit.emit(surface,"paving" if paving else "rubble",rng.randi(),transform,Color.WHITE*(.75 if not paving and center.y<.55 else 1.0),Vector2.ZERO,Vector2(.42,.42))
				stones += 1
			x += w
		y += h
		row += 1
	if stones==0: return {"mesh":ArrayMesh.new(),"stones":0}
	surface.generate_normals()
	surface.index()
	surface.generate_tangents()
	return {"mesh":surface.commit(),"stones":stones}

static func plaster_field(p: Vector3, interior: bool, min_y: float) -> float:
	var field := sin(p.x*.51+p.z*.31)+.55*sin(p.x*1.31-p.z*.67+p.y*.47)+.35*cos(p.y*1.15+p.x*.74)+.09*sin(p.x*11+p.y*13+p.z*9)
	return maxf(maxf(field-(1.55 if interior else .95),(.38-p.y)*4),(min_y-p.y)*4)
static func plaster_depth(p: Vector3) -> float:
	return .035+.007*sin(p.x*4.7+p.y*3.5+p.z*4.1)+.003*sin(p.x*17+p.y*19+p.z*11)

# Routes follow gate, room entrances and the covered gallery; unused edges remain earth.
static func yard_path(p: Vector3) -> bool:
	var main := absf(p.x-.55*sin(p.z*.24))<1.55
	var east := absf(p.z-8.0)<1.2 and p.x>-.7
	var north := p.z<-5.0
	var entry := p.z>15.5 and absf(p.x)<3.1
	var stair := absf(p.z-14.5)<1.0 and p.x<-2
	var edge := absf(p.x)>16.7 or p.z>16.5
	return main or east or north or entry or stair or edge

# Volumetric lime shell with a backing, trowelled front and visible damage-edge returns.
static func plaster(origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, size: Vector2, interior := false, min_y := -100.0) -> ArrayMesh:
	var Kit = preload("res://scripts/blender_kit.gd")
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := maxi(1,int(ceil(size.x/.28)))
	var ny := maxi(1,int(ceil(size.y/.28)))
	for y in range(ny):
		for x in range(nx):
			var a := Vector2(float(x)/nx*size.x,float(y)/ny*size.y)
			var b := Vector2(float(x+1)/nx*size.x,float(y+1)/ny*size.y)
			var corners: Array = [Vector2(a.x,a.y),Vector2(b.x,a.y),Vector2(b.x,b.y),Vector2(a.x,b.y)]
			var poly: Array = []
			var values: Array = []
			for point in corners: values.append(plaster_field(origin+u*point.x+v*point.y,interior,min_y))
			for k in range(4):
				var j := (k+1)%4
				if values[k]<=0: poly.append(corners[k])
				if (values[k]<=0)!=(values[j]<=0): poly.append(corners[k].lerp(corners[j],values[k]/(values[k]-values[j])))
			if poly.size()<3: continue
			if poly.size()!=4 and (x+y)%3==0:
				Kit.emit(s,"plaster",x+y,Transform3D(Basis(u*.09,v*.07,normal*.026),origin+u*(a.x+b.x)*.5+v*(a.y+b.y)*.5+normal*.016))
			var front: Array = []
			var back: Array = []
			for point in poly:
				var p: Vector3 = origin+u*point.x+v*point.y
				front.append(p+normal*plaster_depth(p))
				back.append(p-normal*.025)
			var pos: Vector3 = origin+u*(a.x+b.x)*.5+v*(a.y+b.y)*.5
			var shade := .96+.03*sin(pos.x*.4+pos.z*.7)+.02*sin(pos.y*2+pos.x)
			var tint := Color(shade,shade*.995,shade*.98)
			for k in range(1,poly.size()-1):
				var n: Vector3 = (front[k]-front[0]).cross(front[k+1]-front[0]).normalized()
				if n.dot(normal)<0: n = -n
				triangle(s,front[0],front[k],front[k+1],[poly[0],poly[k],poly[k+1]],normal,tint)
				triangle(s,back[0],back[k+1],back[k],[poly[0],poly[k+1],poly[k]],-normal,tint)
			for k in range(poly.size()):
				var j := (k+1)%poly.size()
				var mid: Vector2 = (poly[k]+poly[j])*.5
				if absf(plaster_field(origin+u*mid.x+v*mid.y,interior,min_y))<.07 or mid.x<.001 or mid.y<.001 or mid.x>size.x-.001 or mid.y>size.y-.001:
					var n: Vector3 = (front[j]-front[k]).cross(normal).normalized()
					triangle(s,back[k],back[j],front[j],[poly[k],poly[j],poly[j]],n,tint*.88)
					triangle(s,back[k],front[j],front[k],[poly[k],poly[j],poly[k]],n,tint*.88)
	s.index()
	return s.commit()
