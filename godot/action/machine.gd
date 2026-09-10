extends Node2D
## Mechanical silhouettes with authored metal and crystal sprites.
var enemy:Dictionary={}
var clock=0.0
var animate=true
const ATLAS=preload('res://assets/sprites/tiles/dungeon.png')
func tile(rect:Rect2,pos:Vector2,size:Vector2,tint=Color.WHITE):
	draw_texture_rect_region(ATLAS,Rect2(pos-size/2,size),rect,tint)
func _process(dt):
	if enemy.is_empty():return
	if animate:clock+=dt
	position=enemy.pos.round();z_index=int(position.y);queue_redraw()
func _draw():
	if enemy.is_empty():return
	var boss=enemy.kind=='boss';var scale_value=2.3 if boss else 1.0
	var tint=Color('#cdb889') if enemy.flash<=0 else Color(1.9,1.8,1.6)
	var ready=enemy.state=='windup';var sway=sin(clock*9)*2.0
	var base=Vector2(0,-25-(sin(clock*4)*3 if enemy.kind=='ranged' else 0))
	draw_set_transform(Vector2.ZERO,0,Vector2(scale_value,scale_value*.35))
	draw_circle(Vector2(0,-4),30,Color(.01,.03,.04,.36))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*scale_value)
	for side in [-1,1]:
		for leg in range(2):
			var foot=Vector2(side*(35-leg*8),-3-leg*18+sway*side)
			var joint=base+Vector2(side*(21+leg*4),-5+leg*15)
			draw_polyline(PackedVector2Array([base+Vector2(side*10,0),joint,foot]),Color('#25353e'),8)
			draw_polyline(PackedVector2Array([base+Vector2(side*10,-2),joint-Vector2(0,2),foot]),tint,3)
			draw_rect(Rect2(foot-Vector2(5,1),Vector2(10,5)),Color('#25353e'))
	# Three metal-blade frames share a silhouette. Adjacent atlas cells are bombs.
	var frame=int(clock*(12 if ready else 3))%3
	tile(Rect2(256+frame*16,96,16,16),base,Vector2(70,70),tint)
	draw_circle(base,17,Color('#293d42'))
	draw_arc(base,19,0,TAU,12,tint,3)
	tile(Rect2(256+int(clock*5)%4*16,144,16,16),base,Vector2(34,34),Color('#ffb964') if ready else Color('#9bcdd9'))
	if enemy.kind=='ranged':
		var tip=base+enemy.direction*40
		draw_line(base+enemy.direction*19,tip,Color('#263a42'),12)
		draw_line(base+enemy.direction*19-Vector2(0,2),tip-Vector2(0,2),tint,5)
	if enemy.kind=='shield':
		var side=1 if enemy.direction.x>=0 else -1
		var shield=base+Vector2(side*29,2)
		var outline=PackedVector2Array([shield+Vector2(-13,-24),shield+Vector2(13,-24),shield+Vector2(17,6),shield+Vector2(0,30),shield+Vector2(-17,6)])
		draw_colored_polygon(outline,Color('#657577'));outline.append(outline[0]);draw_polyline(outline,tint,3)
		draw_line(shield-Vector2(0,18),shield+Vector2(0,19),Color('#96cbd0'),4)
	if boss:
		for i in range(3):
			var a=clock*.3+i*TAU/3;var p=base+Vector2(cos(a)*35,sin(a)*18-14)
			tile(Rect2(256+int(clock*8)%4*16,144,16,16),p,Vector2(18,18),Color('#c9f3ed'))
	draw_set_transform(Vector2.ZERO)
	if not boss:
		draw_rect(Rect2(-27,-62,54,6),Color('#162831'))
		draw_rect(Rect2(-27,-62,54*maxf(0,enemy.hp)/enemy.max_hp,6),Color('#dfb277'))
