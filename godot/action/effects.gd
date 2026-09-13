extends Node2D
var game
var spell_visuals=preload('res://action/spell_visuals.gd').new()
var font=preload("res://assets/action/body.ttf")
const AMBER=Color("#efb76d")
const ICE=Color('#9edbdd')
const IVORY=Color('#eee5cc')
const FROST_EDGE=Color('#17384d')
const CORDON_ICE=Color('#bceeff')
const CORDON_CORE=Color('#f3fbff')
const FRACTURE_BLUE=Color('#3d88c7')
const FRACTURE_CORE=Color('#9bd8ff')
const COUNTER_ICE=Color('#edf5f5')
const COUNTER_SILVER=Color('#b8cfd5')
const HIT_EDGE=Color('#142a33')
const HIT_CORE=Color('#fff0c9')
const METAL=Color('#b8c3c1')
const HOSTILE=Color('#efaa70')
func _draw():
	if game==null:return
	for p in game.combat.projectiles:
		draw_line(p.pos-p.velocity.normalized()*16,p.pos,AMBER,5);draw_circle(p.pos,5,Color('#fff3cb'))
	for fx in game.combat.effects:
		var alpha=fx.life/fx.max;var phase=1-alpha
		match fx.kind:
			'spark':
				for i in range(7):
					var dir=Vector2.from_angle(i*TAU/7+fx.dir.angle())
					var p=fx.pos+dir*phase*37
					draw_line(p,p-dir*8,Color(1,.88,.58,alpha),2)
			'impact':
				var hit_dir=fx.get('dir',Vector2.RIGHT);var heavy=fx.get('heavy',false);var ice=fx.get('tone','metal')=='ice'
				var edge=FROST_EDGE if ice else HIT_EDGE;var core=FRACTURE_CORE if ice else HIT_CORE;var radius=(10.0 if heavy else 7.0)+phase*(22.0 if heavy else 15.0)
				draw_arc(fx.pos,radius,hit_dir.angle()-1.15,hit_dir.angle()+1.15,18,Color(edge,alpha*.86),6 if heavy else 4)
				draw_arc(fx.pos,radius,hit_dir.angle()-.95,hit_dir.angle()+.95,16,Color(core,alpha),3 if heavy else 2)
				var shard_count=7 if heavy else 5
				for i in range(shard_count):
					var spread=(float(i)/(shard_count-1)-.5)*1.9;var ray=hit_dir.rotated(spread);var p=fx.pos+ray*(6+phase*(32 if heavy else 23))
					draw_line(p-ray*7,p+ray*(5 if heavy else 3),Color(core,alpha*.88),2)
			'deflect':
				var block_dir=fx.get('dir',Vector2.RIGHT);var br=19+phase*15
				draw_arc(fx.pos,br,block_dir.angle()-1.35,block_dir.angle()+1.35,20,Color(FROST_EDGE,alpha*.9),6)
				draw_arc(fx.pos,br,block_dir.angle()-1.18,block_dir.angle()+1.18,18,Color(IVORY,alpha),2)
				for i in range(4):
					var ray=block_dir.rotated((i-1.5)*.42);var p=fx.pos+ray*(14+phase*25);draw_line(p-ray*5,p+ray*6,Color(HIT_CORE,alpha*.9),2)
			'spawn':
				var rr=30+phase*16;draw_arc(fx.pos+Vector2(0,-24),rr,0,TAU,32,Color(HIT_EDGE,alpha*.72),4)
				for i in range(4):
					var ray=Vector2.from_angle(i*PI/2+PI/4);var a=fx.pos+Vector2(0,-24)+ray*(rr+8);draw_line(a,a-ray*(10+phase*8),Color(METAL,alpha*.72),2)
			'text':
				var text_pos=fx.pos+Vector2(0,-phase*22);var box=text_pos+Vector2(-28,0)
				for shadow in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
					draw_string(font,box+shadow,fx.text,HORIZONTAL_ALIGNMENT_CENTER,56,17,Color(.015,.035,.045,alpha*.92))
				draw_string(font,box,fx.text,HORIZONTAL_ALIGNMENT_CENTER,56,17,Color(1,.9,.67,alpha))
			'status':
				if fx.status=='shield':
					var status_pos=fx.pos
					var outer=PackedVector2Array([status_pos+Vector2(-8,-7),status_pos+Vector2(8,-7),status_pos+Vector2(7,3),status_pos+Vector2(0,10),status_pos+Vector2(-7,3)])
					var inner=PackedVector2Array([status_pos+Vector2(-5,-4),status_pos+Vector2(5,-4),status_pos+Vector2(4,2),status_pos+Vector2(0,7),status_pos+Vector2(-4,2)])
					draw_colored_polygon(outer,Color(.015,.035,.045,alpha*.95));draw_colored_polygon(inner,Color(ICE,alpha))
			'slash':
				var angle=fx.dir.angle();var sweep=angle-1.1+phase*.8
				draw_arc(fx.pos,88 if fx.strong else 75,sweep,sweep+1.45,14,Color(IVORY,alpha),6 if fx.strong else 3)
				if fx.strong:draw_arc(fx.pos,82,sweep+.2,sweep+1.2,12,Color(AMBER,alpha*.65),2)
			'cordao':
				spell_visuals.paint(self,fx,game.preferences.reduced_motion)
			'dash':
				for side in [-1,1]:
					var p=fx.pos+fx.dir.orthogonal()*side*13
					draw_line(p-fx.dir*(12+phase*46),p-fx.dir*phase*15,Color(FROST_EDGE,alpha*.42),5)
					draw_line(p-fx.dir*(10+phase*40),p-fx.dir*phase*16,Color(ICE,alpha*.72),2)
				for i in range(3):
					var q=fx.pos-fx.dir*(14+phase*(22+i*13));var side=fx.dir.orthogonal()*(8+i*3);draw_line(q-side,q+side,Color(CORDON_CORE,alpha*(.30-i*.06)),1)
			'fratura':
				spell_visuals.paint(self,fx,game.preferences.reduced_motion)
			'contrapeso':
				spell_visuals.paint(self,fx,game.preferences.reduced_motion)
			'contrapeso_break':
				var center=fx.pos+Vector2(0,-42)
				for i in range(10):
					var ray=Vector2.from_angle(i*TAU/10+.08);var side=ray.orthogonal();var p=center+ray*(18+phase*48)
					var shard=PackedVector2Array([p+ray*9,p-side*4,p-ray*6,p+side*4])
					draw_colored_polygon(shard,Color(COUNTER_ICE,alpha*.95));draw_line(p-ray*6,p+ray*9,Color(FROST_EDGE,alpha*.72),1)
				for side in [-1,1]:draw_line(center+Vector2(side*7,-18),center+Vector2(side*28,-34),Color(COUNTER_SILVER,alpha*.72),3)
			'enemy_beam':
				var beam_end=fx.pos+fx.dir*1100;draw_line(fx.pos,beam_end,Color(HIT_EDGE,alpha*.28),112);draw_line(fx.pos,beam_end,Color(HOSTILE,alpha*.18),100);draw_line(fx.pos,beam_end,Color(IVORY,alpha),5)
			'danger':
				draw_arc(fx.pos,fx.radius,0,TAU,40,Color(HIT_EDGE,alpha*.82),7);draw_arc(fx.pos,fx.radius,0,TAU,40,Color(HOSTILE,alpha),3)
			'burst':
				var center=fx.pos+Vector2(0,-18);draw_circle(center,12+phase*16,Color(FROST_EDGE,alpha*.18));draw_arc(center,14+phase*18,0,TAU,24,Color(ICE,alpha*.65),2)
				for i in range(10):
					var ray=Vector2.from_angle(i*TAU/10+.12);var side=ray.orthogonal();var p=center+ray*(8+phase*(44+(i%3)*8));var size=7+(i%2)*3
					var shard=PackedVector2Array([p+ray*size,p-side*3,p-ray*(size*.65),p+side*3]);draw_colored_polygon(shard,Color(ICE if i%3==0 else METAL,alpha*.84));draw_line(p-ray*4,p+ray*size,Color(HIT_EDGE,alpha*.55),1)
