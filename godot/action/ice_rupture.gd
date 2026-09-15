extends RefCounted
## Ground-only presentation. Geometry is allocated once per cast, never in combat RNG.
const EDGE=Color('#24465a')
const BLUE=Color('#568bac')
const CORE=Color('#b4dcec')
static func geometry(center:Vector2,direction:Vector2)->Dictionary:
	var rng=RandomNumberGenerator.new()
	rng.seed=int(center.x)*73856093 ^ int(center.y)*19349663
	var outline=PackedVector2Array();var cracks=[];var shards=[]
	for i in range(10):
		var angle=float(i)*TAU/10+rng.randf_range(-.16,.16)
		var p=Vector2.from_angle(angle)*rng.randf_range(23,35)
		outline.append(Vector2(p.x,p.y*.58))
	for angle in [-2.78,-1.52,-.43,.68,2.12]:
		var ray=Vector2.from_angle(angle+direction.angle()+rng.randf_range(-.18,.18))
		var length=rng.randf_range(43,66);var points=PackedVector2Array([Vector2.ZERO])
		for j in range(1,4):
			var p=ray*length*j/3.0+ray.orthogonal()*rng.randf_range(-7,7)
			points.append(Vector2(p.x,p.y*.65))
		cracks.append(points)
	for i in range(6):
		var ray=Vector2.from_angle(float(i)*TAU/6+rng.randf_range(-.35,.35))
		shards.append({'ray':ray,'speed':rng.randf_range(26,47),'lift':rng.randf_range(12,24),'size':rng.randf_range(3,6),'spin':rng.randf_range(-2.2,2.2)})
	return {'outline':outline,'cracks':cracks,'shards':shards}
static func tapered(c:Node2D,a:Vector2,b:Vector2,wa:float,wb:float,color:Color):
	if a.distance_squared_to(b)<.01:return
	var side=(b-a).normalized().orthogonal()
	c.draw_colored_polygon(PackedVector2Array([a+side*wa,b+side*wb,b-side*wb,a-side*wa]),color)
static func shard_position(shard:Dictionary,t:float,reduced:bool)->Vector2:
	var ray:Vector2=shard.ray
	if reduced:return Vector2(ray.x*20,ray.y*12)
	var p=ray*(8+shard.speed*(1-pow(1-t,2)))
	return Vector2(p.x,p.y*.6-sin(t*PI)*shard.lift)
static func paint(c:Node2D,fx:Dictionary,reduced:bool):
	var phase=clampf(1-float(fx.life)/float(fx.max),0,1)
	var opacity=1-smoothstep(.53,1.0,phase)
	var opened=1.0 if reduced else smoothstep(0,.24,phase)
	var center:Vector2=fx.get('impact',fx.pos+fx.dir*205)
	# Legacy QA fixtures can supply an effect without the cached geometry.
	var g:Dictionary=fx.get('geometry',{})
	if g.is_empty():g=geometry(center,fx.dir)
	var outline=PackedVector2Array();var inner=PackedVector2Array()
	for p in g.outline:
		outline.append(center+p*(.65+.35*opened)+Vector2(0,2))
		inner.append(center+p*(.48+.35*opened))
	c.draw_colored_polygon(outline,Color(EDGE,opacity*.72))
	c.draw_colored_polygon(inner,Color(BLUE,opacity*.66))
	# Five broken plates, separated by the darker crushed center.
	for i in range(0,10,2):
		var a:Vector2=g.outline[i];var b:Vector2=g.outline[(i+1)%10]
		c.draw_colored_polygon(PackedVector2Array([center+a*opened,center+b*opened,center+(a+b)*.21]),Color(CORE,opacity*(.38 if i%4 else .65)))
	var growth=1.0 if reduced else smoothstep(.05,.43,phase)
	for points in g.cracks:
		for j in range(3):
			var progress=clampf(growth*3-j,0,1)
			if progress<=0:continue
			var a:Vector2=center+points[j];var b:Vector2=center+points[j].lerp(points[j+1],progress)
			tapered(c,a,b,2.9-j*.85,maxf(.12,2.0-j*.9),Color(EDGE,opacity*.83))
			if j<2:c.draw_line(a+Vector2(0,-1),b+Vector2(0,-1),Color(CORE,opacity*.48),1)
	# A restrained broken seam communicates direction without a glowing beam.
	var delta:Vector2=center-fx.pos
	for i in range(1,6):
		if float(i)/7>growth:continue
		var a:Vector2=fx.pos+delta*float(i)/7+fx.dir.orthogonal()*(-3 if i%2 else 4)
		c.draw_line(a,a+delta/16+fx.dir.orthogonal()*4,Color(EDGE,opacity*.42),1)
	if phase<.12 or phase>.83:return
	var t=clampf((phase-.12)/.71,0,1)
	for shard in g.shards:
		var p:Vector2=center+shard_position(shard,t,reduced)
		var ray:Vector2=shard.ray.rotated(0 if reduced else t*shard.spin)
		var side=ray.orthogonal();var size:float=shard.size
		var a=opacity*(1-smoothstep(.58,1.0,t))
		c.draw_colored_polygon(PackedVector2Array([p+ray*size,p+side*size*.55,p-ray*size*.7]),Color(CORE,a))
		c.draw_line(p-ray*size*.7,p+side*size*.55,Color(EDGE,a*.8),1)
