extends RefCounted

# Texture coordinates, height and geometry use the same metric projection.
# The surface relief is baked in the mesh; no tessellation shader is required.
static func sample_height(img: Image, uv: Vector2) -> float:
	var x := fposmod(uv.x,1.0)*img.get_width()
	var y := fposmod(uv.y,1.0)*img.get_height()
	var ix := int(x)%img.get_width()
	var iy := int(y)%img.get_height()
	var a := img.get_pixel(ix,iy).r
	var b := img.get_pixel((ix+1)%img.get_width(),iy).r
	var c := img.get_pixel(ix,(iy+1)%img.get_height()).r
	var d := img.get_pixel((ix+1)%img.get_width(),(iy+1)%img.get_height()).r
	return lerpf(lerpf(a,b,x-floorf(x)),lerpf(c,d,x-floorf(x)),y-floorf(y))

static func make(origin: Vector3, axis_u: Vector3, axis_v: Vector3, normal: Vector3, size: Vector2, image: Image, period: float, depth: float, spacing: float, triangle := false) -> Dictionary:
	var nx := maxi(1,int(ceil(size.x/spacing)))
	var ny := maxi(1,int(ceil(size.y/spacing)))
	var points := PackedVector3Array()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var eps := .018
	for j in range(ny+1):
		var v := float(j)/ny*size.y
		for i in range(nx+1):
			var u := float(i)/nx*size.x
			if triangle:
				u = size.x*.5+(u-size.x*.5)*(1.0-v/size.y)
			var base := origin+axis_u*u+axis_v*v
			var uv := Vector2(base.dot(axis_u),-base.dot(axis_v))/period
			var h := sample_height(image,uv)
			var hu := (sample_height(image,uv+Vector2(eps/period,0))-sample_height(image,uv-Vector2(eps/period,0)))*depth/(2*eps)
			var hv := (sample_height(image,uv-Vector2(0,eps/period))-sample_height(image,uv+Vector2(0,eps/period)))*depth/(2*eps)
			var p := base+normal*(h-.5)*depth
			surface.set_normal((normal-axis_u*hu-axis_v*hv).normalized())
			surface.set_uv(uv)
			surface.add_vertex(p)
			points.append(p)
	var cells := 0
	for j in range(ny):
		for i in range(nx):
			var a := j*(nx+1)+i
			var b := a+1
			var d := a+nx+1
			var c := d+1
			for ids in [[a,b,c],[a,c,d]]:
				var cross := (points[ids[1]]-points[ids[0]]).cross(points[ids[2]]-points[ids[0]])
				if cross.length_squared()<.000000001:
					continue
				var order := [0,2,1] if cross.dot(normal)>0 else [0,1,2]
				for index in order:
					surface.add_index(ids[index])
			cells += 1
	surface.generate_tangents()
	return {"mesh":surface.commit(),"cells":cells}
