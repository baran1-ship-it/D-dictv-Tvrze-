extends RefCounted
const Construction = preload("res://scripts/construction_mesh.gd")

# Closed circular voussoirs, staggered joints, 20 cm shell; crown 4.50 m.
static func make(center: Vector3, size: Vector2, across_x: bool) -> Dictionary:
	var span := size.x if across_x else size.y
	var length := size.y if across_x else size.x
	var u := Vector3.RIGHT if across_x else Vector3.BACK
	var axis := Vector3.BACK if across_x else Vector3.RIGHT
	var half := span*.5
	var rise := minf(1.40,half*.80)
	var radius := (half*half+rise*rise)/(2.0*rise)
	var circle_y := 4.50-radius
	var angle := asin(half/radius)
	var courses := maxi(12,int(ceil(span/.28)))
	var rows := maxi(1,int(ceil(length/.48)))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(center.x*131+center.z*193))+1403
	var weights: Array[float] = []
	var sum := 0.0
	for row in range(rows):
		var weight := rng.randf_range(.82,1.18)
		weights.append(weight)
		sum += weight
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cursor := -length*.5
	for row in range(rows):
		var z0 := cursor+.006
		cursor += length*weights[row]/sum
		var z1 := cursor-.006
		var angles: Array[float] = [-angle]
		var shift := rng.randf_range(-.18,.18)
		for course in range(1,courses): angles.append(-angle+(course+shift+rng.randf_range(-.27,.27))*2*angle/courses)
		angles.append(angle)
		for course in range(courses):
			var a := angles[course]+.0007
			var b := angles[course+1]-.0007
			var p: Array[Vector3] = []
			for z in [z0,z1]:
				for r in [radius,radius+.20]:
					for t in [a,b]: p.append(center+axis*z+u*(sin(t)*r)+Vector3.UP*(circle_y+cos(t)*r))
			var tint := rng.randf_range(.86,1.0)
			s.set_color(Color(tint,tint*.99,tint*.98))
			var tile := rng.randi_range(0,3)
			var phase := Vector2((tile%2)*.5+.04,(tile/2)*.5+.04)
			var mid := (a+b)*.5
			var radial := u*sin(mid)+Vector3.UP*cos(mid)
			Construction.quad(s,[p[0],p[1],p[5],p[4]],-radial,Vector2(.36,.36),phase)
			Construction.quad(s,[p[2],p[6],p[7],p[3]],radial,Vector2(.36,.36),phase)
			Construction.quad(s,[p[0],p[2],p[3],p[1]],-axis,Vector2(.12,.36),phase)
			Construction.quad(s,[p[4],p[5],p[7],p[6]],axis,Vector2(.12,.36),phase)
			Construction.quad(s,[p[0],p[4],p[6],p[2]],-(u*cos(a)-Vector3.UP*sin(a)),Vector2(.12,.36),phase)
			Construction.quad(s,[p[1],p[3],p[7],p[5]],u*cos(b)-Vector3.UP*sin(b),Vector2(.12,.36),phase)
	# A continuous mortar bed hides the slab through tiny joints.
	s.set_color(Color(.60,.59,.58))
	for course in range(courses):
		var a := -angle+course*2*angle/courses
		var b := -angle+(course+1)*2*angle/courses
		var p: Array = []
		for z in [-length*.5,length*.5]:
			for t in [a,b]: p.append(center+axis*z+u*sin(t)*(radius+.018)+Vector3.UP*(circle_y+cos(t)*(radius+.018)))
		Construction.quad(s,[p[0],p[1],p[3],p[2]],-(u*sin((a+b)*.5)+Vector3.UP*cos((a+b)*.5)),Vector2(.36,.36),Vector2(.04,.04))
	s.index()
	s.generate_tangents()
	return {"mesh":s.commit()}
