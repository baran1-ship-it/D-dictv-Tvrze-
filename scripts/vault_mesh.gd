extends RefCounted
const Construction = preload("res://scripts/construction_mesh.gd")

# Segmental barrel vault: wedge-shaped voussoirs follow a circular intrados.
# Crown is exactly 4.50 m above the ground floor; shell is 20 cm thick.
static func make(center: Vector3, size: Vector2, across_x: bool) -> Dictionary:
	var span := size.x if across_x else size.y
	var length := size.y if across_x else size.x
	var u := Vector3.RIGHT if across_x else Vector3.BACK
	var axis := Vector3.BACK if across_x else Vector3.RIGHT
	var half := span*.5
	var rise := 1.40
	var radius := (half*half+rise*rise)/(2.0*rise)
	var circle_y := 4.50-radius
	var angle := asin(half/radius)
	var courses := maxi(16,int(ceil(span/.28)))
	var rows := maxi(1,int(ceil(length/.48)))
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rows):
		var z0 := -length*.5+row*length/rows+.006
		var z1 := -length*.5+(row+1)*length/rows-.006
		for course in range(courses):
			var a := -angle+course*2.0*angle/courses+.0007
			var b := -angle+(course+1)*2.0*angle/courses-.0007
			var p: Array[Vector3] = []
			for z in [z0,z1]:
				for r in [radius,radius+.20]:
					for t in [a,b]:
						p.append(center+axis*z+u*(sin(t)*r)+Vector3.UP*(circle_y+cos(t)*r))
			var tint := .88+float((row*7+course*13)%11)*.011
			s.set_color(Color(tint,tint*.99,tint*.96))
			var mid := (a+b)*.5
			var radial := u*sin(mid)+Vector3.UP*cos(mid)
			Construction.quad(s,[p[0],p[1],p[5],p[4]],-radial,Vector2(.4,.48))
			Construction.quad(s,[p[2],p[6],p[7],p[3]],radial,Vector2(.4,.48))
			Construction.quad(s,[p[0],p[2],p[3],p[1]],-axis)
			Construction.quad(s,[p[4],p[5],p[7],p[6]],axis)
			Construction.quad(s,[p[0],p[4],p[6],p[2]],-(u*cos(a)-Vector3.UP*sin(a)))
			Construction.quad(s,[p[1],p[3],p[7],p[5]],u*cos(b)-Vector3.UP*sin(b))
	s.index()
	return {"mesh":s.commit()}
