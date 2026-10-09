extends RefCounted
const Masonry = preload("res://scripts/masonry_mesh.gd")

# Every shingle has a projecting butt edge and thickness; adjoining rows overlap.
static func make(origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, size: Vector2, triangular := false) -> Dictionary:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(origin.x*193+origin.y*371+origin.z*947))+501
	var count := 0
	var rows := int(ceil(size.y/.235))
	for row in range(rows):
		var y := row*.235
		var x := -.20 if row%2 else 0.0
		while x<size.x:
			var width := rng.randf_range(.145,.23)
			var a := maxf(0,x+.004)
			var b := minf(size.x,x+width-.004)
			var top := minf(size.y,y+.43)
			var poly: Array = [Vector2(a,y),Vector2(b,y),Vector2(b,top),Vector2(a,top)]
			if triangular:
				poly = Masonry.clip(poly,Vector2(-1,size.x/(2*size.y)),0)
				poly = Masonry.clip(poly,Vector2(1,size.x/(2*size.y)),size.x)
			if poly.size()>=3:
				var face: Array[Vector3] = []
				var back: Array[Vector3] = []
				var uv: Array[Vector2] = []
				# Sample grain from inside one photographed plank, away from its seams.
				var strip := rng.randi_range(0,10)
				var phase := rng.randf()
				var shade := rng.randf_range(.72,1.0)
				var tint := Color(shade,shade*.98,shade*.94)
				var h := rng.randf_range(.026,.036)
				for p in poly:
					var d: float = h-.027*(p.y-y)/.43
					face.append(origin+u*p.x+v*p.y+normal*d)
					back.append(origin+u*p.x+v*p.y-normal*.002)
					uv.append(Vector2((strip+.23+(p.x-a)/width*.30)/11.0,phase+(p.y-y)*.6))
				for i in range(1,poly.size()-1):
					Masonry.triangle(s,face[0],face[i],face[i+1],[uv[0],uv[i],uv[i+1]],normal,tint)
					Masonry.triangle(s,back[0],back[i+1],back[i],[uv[0],uv[i+1],uv[i]],-normal,tint)
				for i in range(poly.size()):
					var n := (i+1)%poly.size()
					var side := (back[n]-back[i]).cross(normal).normalized()
					Masonry.triangle(s,back[i],back[n],face[n],[uv[i],uv[n],uv[n]],side,tint)
					Masonry.triangle(s,back[i],face[n],face[i],[uv[i],uv[n],uv[i]],side,tint)
				count += 1
			x += width
	s.index()
	s.generate_tangents()
	return {"mesh":s.commit(),"count":count}
