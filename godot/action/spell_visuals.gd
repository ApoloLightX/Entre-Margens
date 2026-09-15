extends RefCounted
## Presentation only: all layers share the combat effect's lifetime and source.
const EDGE=Color('#17384d')
const CORDON=Color('#bceeff')
const WHITE=Color('#f3fbff')
const BLUE=Color('#3d88c7')
const BLUE_CORE=Color('#9bd8ff')
const SILVER=Color('#b8cfd5')
var glow:GradientTexture2D
func _init():
	var gradient=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.25,.65,1])
	gradient.colors=PackedColorArray([Color(1,1,1,.8),Color(1,1,1,.45),Color(1,1,1,.12),Color(1,1,1,0)])
	glow=GradientTexture2D.new();glow.width=64;glow.height=64;glow.gradient=gradient
	glow.fill=GradientTexture2D.FILL_RADIAL;glow.fill_from=Vector2(.5,.5);glow.fill_to=Vector2(1,.5)
func halo(canvas:Node2D,p:Vector2,size:Vector2,tint:Color):
	canvas.draw_texture_rect(glow,Rect2(p-size*.5,size),false,tint)
func facet(canvas:Node2D,p:Vector2,ray:Vector2,length:float,width:float,tint:Color):
	var side=ray.orthogonal()
	var tip=p+ray*length;var root=p-ray*length*.45
	canvas.draw_colored_polygon(PackedVector2Array([tip,p-side*width,root,p+side*width]),Color(EDGE,tint.a*.8))
	canvas.draw_colored_polygon(PackedVector2Array([tip,p,root,p+side*width]),tint)
	canvas.draw_line(root,tip,Color(WHITE,tint.a*.75),1.0)
func paint(canvas:Node2D,fx:Dictionary,reduced:bool):
	var alpha=clampf(float(fx.life)/float(fx.max),0,1)
	var phase=1-alpha
	match fx.kind:
		'cordao':cordon(canvas,fx,phase,alpha,reduced)
		'contrapeso':counterweight(canvas,fx,phase,alpha,reduced)
func cordon(c:Node2D,fx:Dictionary,phase:float,alpha:float,reduced:bool):
	var radius=float(fx.radius)
	var pulse=1.0 if reduced else .85+.15*sin(phase*PI)
	# Light lives at the perimeter; the center stays open for silhouettes.
	for i in range(12):
		var ray=Vector2.from_angle(i*TAU/12+.16)
		var p=fx.pos+ray*radius
		halo(c,p,Vector2(62,44),Color(CORDON,alpha*.34*pulse))
	c.draw_arc(fx.pos,radius,0,TAU,64,Color(EDGE,alpha*.8),6)
	c.draw_arc(fx.pos,radius,0,TAU,64,Color(CORDON,alpha*.68),2)
	var close=clampf(phase*4,0,1)
	for i in range(12):
		var angle=i*TAU/12+.16
		var ray=Vector2.from_angle(angle)
		var lift=0.0 if reduced else sin(close*PI/2)*12
		var p=fx.pos+ray*(radius+(0 if reduced else (1-close)*16))-Vector2(0,lift)
		facet(c,p,Vector2.UP.rotated(ray.x*.35),10+close*6,4,Color(CORDON,alpha*.9))
		c.draw_arc(fx.pos,radius,angle-.08,angle+.08,6,Color(WHITE,alpha),3)
		if not reduced:
			var drift=fx.pos+ray*(radius-8+phase*20)-Vector2(0,phase*(18+i%3*6))
			c.draw_rect(Rect2(drift,Vector2(2,3)),Color(WHITE,alpha*.7))
func counterweight(c:Node2D,fx:Dictionary,phase:float,alpha:float,reduced:bool):
	var center:Vector2=fx.pos+Vector2(0,-42)
	var settle=1.0 if reduced else clampf(phase*6,0,1)
	var shell=PackedVector2Array([Vector2(-24,-8),Vector2(-33,-43),Vector2(-20,-77),Vector2(0,-91),Vector2(20,-77),Vector2(33,-43),Vector2(24,-8),Vector2(0,5)])
	for i in range(shell.size()):shell[i]+=fx.pos
	var closed=shell.duplicate();closed.append(shell[0])
	halo(c,center,Vector2(82,112),Color(SILVER,alpha*.3))
	c.draw_colored_polygon(shell,Color(SILVER,alpha*.07))
	c.draw_polyline(closed,Color(EDGE,alpha*.9),6)
	c.draw_polyline(closed,Color(SILVER,alpha*.9),2)
	for side in [-1,1]:
		for i in range(3):
			var offset=0.0 if reduced else (1-settle)*side*12
			var p=fx.pos+Vector2(side*(24-i*3)+offset,-22-i*24)
			facet(c,p,Vector2(side*.3,-1),15,5,Color(WHITE,alpha*.82))
			if not reduced:
				var glint=p+Vector2(0,sin(phase*TAU+i)*6)
				halo(c,glint,Vector2(18,30),Color(WHITE,alpha*.32))
	c.draw_line(fx.pos+Vector2(-21,3),fx.pos+Vector2(21,3),Color(WHITE,alpha*.75),2)
