extends Node2D
var game
var font=preload("res://assets/action/body.ttf")
const AMBER=Color("#efb76d")
const ICE=Color('#9edbdd')
const IVORY=Color('#eee5cc')
func _draw():
	if game==null:return
	for p in game.combat.projectiles:
		draw_line(p.pos-p.velocity.normalized()*16,p.pos,AMBER,5);draw_circle(p.pos,5,Color('#fff3cb'))
	for fx in game.combat.effects:
		var alpha=fx.life/fx.max
		match fx.kind:
			'spark':
				for i in range(7):
					var dir=Vector2.from_angle(i*TAU/7+fx.dir.angle())
					var p=fx.pos+dir*(1-alpha)*37
					draw_line(p,p-dir*8,Color(1,.88,.58,alpha),2)
			'text':draw_string(font,fx.pos+Vector2(0,-(1-alpha)*22),fx.text,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(1,.9,.67,alpha))
			'slash':
				var angle=fx.dir.angle();var sweep=angle-1.1+(1-alpha)*.8
				draw_arc(fx.pos,88 if fx.strong else 75,sweep,sweep+1.45,14,Color(IVORY,alpha),6 if fx.strong else 3)
				if fx.strong:draw_arc(fx.pos,82,sweep+.2,sweep+1.2,12,Color(AMBER,alpha*.65),2)
			'ring':draw_arc(fx.pos,fx.radius*(1-alpha*.5),0,TAU,48,Color(.5,.93,1,alpha),4)
			'cordao':
				var radius=fx.radius*(.55+.45*minf(1,(1-alpha)*3))
				draw_arc(fx.pos,radius,0,TAU,64,Color(ICE,alpha),3)
				for i in range(6):
					var angle=i*TAU/6+(1-alpha)*.12
					draw_arc(fx.pos,radius-9,angle,angle+.48,7,Color(ICE,alpha*.6),2)
					var v=Vector2.from_angle(angle);draw_line(fx.pos+v*(radius-5),fx.pos+v*(radius+7),Color(IVORY,alpha*.8),2)
			'dash':
				for side in [-1,1]:
					var p=fx.pos+fx.dir.orthogonal()*side*13
					draw_line(p-fx.dir*(10+(1-alpha)*40),p-fx.dir*(1-alpha)*16,Color(ICE,alpha*.6),2)
			'beam':
				var end=fx.pos+fx.dir*410;var side=fx.dir.orthogonal()
				draw_line(fx.pos,end,Color(AMBER,alpha*.10),28)
				draw_line(fx.pos,end,Color(IVORY,alpha),4)
				for i in range(1,7):
					var p=fx.pos+fx.dir*i*57
					var crack=PackedVector2Array([p-side*23-fx.dir*11,p-fx.dir*4,p+side*18+fx.dir*9])
					draw_polyline(crack,Color(IVORY,alpha*.72),2)
			'enemy_beam':
				draw_line(fx.pos,fx.pos+fx.dir*1100,Color(AMBER,alpha*.34),106)
				draw_line(fx.pos,fx.pos+fx.dir*1100,Color(IVORY,alpha),5)
			'danger':draw_arc(fx.pos,fx.radius,0,TAU,40,Color(1,.6,.3,alpha),5)
			'burst':
				for i in range(8):
					var p=fx.pos+Vector2.from_angle(i*TAU/8)*(1-alpha)*55
					draw_rect(Rect2(p,Vector2(4,4)),Color(.65,.87,.91,alpha))
