extends Node2D
## Authored CC0 terrain and sprites; combat coordinates remain authoritative.
var game
var clock=0.0
var snow:Array=[]
var props:Array=[]
var residents:Array=[]
var machines:Dictionary={}
var player
var foreground
var route:Array=[]
var tracks:Array=[]
var last_step=Vector2.ZERO
var terrain:ColorRect
const FLOOR=preload('res://assets/sprites/tiles/dungeon.png')
const SNOW=preload('res://assets/sprites/tiles/snow.png')
const OVER=preload('res://assets/sprites/tiles/overworld.png')
const ICE=Color('#9bcfce')
const GOLD=Color('#e5b77a')
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	terrain=ColorRect.new();terrain.mouse_filter=Control.MOUSE_FILTER_IGNORE;terrain.z_index=-4000
	var mat=ShaderMaterial.new();mat.shader=preload('res://action/terrain.gdshader');mat.set_shader_parameter('paving',FLOOR);terrain.material=mat;add_child(terrain)
	player=preload('res://action/actor.gd').new();player.configure('traveller');add_child(player)
	foreground=preload('res://action/effects.gd').new();foreground.game=game;foreground.z_index=4000;add_child(foreground)
func refresh():
	for n in props+residents:n.queue_free()
	for n in machines.values():n.queue_free()
	props.clear();residents.clear();machines.clear();snow.clear();tracks.clear();route.clear()
	var r=game.current_room();last_step=game.state.position
	route.append(Vector2(r.spawn[0],r.spawn[1]))
	for o in r.objects:
		if o.id in r.required:route.append(Vector2(o.x,o.y))
	route.append(Vector2(r.exit[0],r.exit[1]))
	terrain.size=Vector2(r.size[0],r.size[1]);terrain.material.set_shader_parameter('world_size',terrain.size)
	var points=PackedVector2Array(route);points.resize(16)
	terrain.material.set_shader_parameter('route',points);terrain.material.set_shader_parameter('route_count',mini(route.size(),16))
	terrain.material.set_shader_parameter('outdoor',r.floor=='snow' or game.state.room==0);terrain.material.set_shader_parameter('archive',game.state.room==3)
	var rng=RandomNumberGenerator.new();rng.seed=470+game.state.room
	for i in range(85):snow.append(Vector3(rng.randf_range(-900,900),rng.randf_range(-500,500),rng.randf_range(.3,1)))
	for p in r.props:add_prop(p)
	# Border decoration is outside the traversable bounds.
	for i in range(0,int(r.size[0]),110):
		add_prop({'tile':2 if r.floor=='snow' else 3,'x':i+45,'y':83,'size':150,'solid':false})
		add_prop({'tile':2 if r.floor=='snow' else 3,'x':i+75,'y':r.size[1]+40,'size':170,'solid':false})
	for i in range(150,int(r.size[1]),130):
		add_prop({'tile':2 if r.floor=='snow' else 9,'x':-12,'y':i,'size':180,'solid':false})
		add_prop({'tile':2 if r.floor=='snow' else 9,'x':r.size[0]+20,'y':i+55,'size':180,'solid':false})
	for o in r.objects:
		if o.get('npc',false):
			var n=preload('res://action/actor.gd').new();n.configure('dena' if 'dena' in o.id else ('sena' if 'sena' in o.id else 'lior'));n.set_meta('source',o);add_child(n);residents.append(n)
func add_prop(p:Dictionary):
	var n=preload('res://action/scenery.gd').new();n.data=p;n.cold=game.current_room().floor=='snow';n.position=Vector2(p.x,p.y).round();n.z_index=int(p.y);add_child(n);props.append(n)
func _process(dt):
	if game==null or player==null:return
	var c=game.combat
	var frozen=game.modal or game.app_paused or c.hit_stop>0
	var animate=not frozen and not game.preferences.reduced_motion
	if animate:clock+=dt
	for prop in props:prop.animate=animate
	var pose='idle';var progress=-1.0
	if not game.modal:
		if c.dodge_time>0:pose='dodge';progress=1-c.dodge_time/.25
		elif c.attack_flash>0:pose='attack';progress=1-c.attack_flash/.34
		elif c.spell_flash>0:pose='cast';progress=1-c.spell_flash/.35
		elif c.hurt_time>0:pose='hurt'
		elif game.movement.length()>.1:pose='walk'
	player.present(game.state.position,c.facing,pose,progress,c.hurt_time>0)
	player.z_index=4001 if not c.enemies.is_empty() else int(game.state.position.y)
	if frozen:player.pause()
	for n in residents:
		var d=n.get_meta('source');var p=Vector2(d.x,d.y)
		var facing=(game.state.position-p).normalized() if game.state.position.distance_to(p)<170 else Vector2.DOWN
		n.present(p,facing,'idle')
		if frozen:n.pause()
	var alive=[]
	for e in c.enemies:
		var id=e.visual_id;alive.append(id)
		if not machines.has(id):
			var n=preload('res://action/machine.gd').new();n.enemy=e;add_child(n);machines[id]=n
		machines[id].animate=animate
	for id in machines.keys():
		if not id in alive:machines[id].queue_free();machines.erase(id)
	if not game.modal and game.state.position.distance_to(last_step)>24:
		tracks.append({'pos':game.state.position,'time':clock,'dir':c.facing,'side':1 if tracks.size()%2 else -1})
		last_step=game.state.position
		if tracks.size()>28:tracks.pop_front()
	foreground.queue_redraw();queue_redraw()
func tile_at(tex:Texture2D,src:Rect2,dest:Rect2,tint=Color.WHITE):draw_texture_rect_region(tex,dest,src,tint)
func road_distance(p:Vector2)->float:
	var d=9999.0
	for i in range(route.size()-1):d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,route[i],route[i+1])))
	return d
func warning_dashes(a:Vector2,b:Vector2,color:Color,width=2.0,segments=12,duty=.48):
	var step=(b-a)/float(segments)
	for i in range(segments):
		var start=a+step*i;draw_line(start,start+step*duty,color,width)
func light_pool(p:Vector2,radius:float,strength=1.0):
	draw_set_transform(p,0,Vector2(1,.55))
	for ring in range(3,0,-1):draw_circle(Vector2.ZERO,radius*ring/3,Color(1,.70,.35,.025*strength))
	draw_set_transform(Vector2.ZERO)
func _draw():
	if game==null or game.camera==null:return
	var r=game.current_room();var center=game.camera.get_screen_center_position()
	var size=get_viewport_rect().size/game.camera.zoom
	var view=Rect2(center-size/2,size).grow(60)
	for prop in r.props:
		var p=Vector2(prop.x,prop.y)
		if not view.grow(100).has_point(p):continue
		if int(prop.tile) in [0,8]:
			var width=roundf(float(prop.size)/48)*48
			for side in [-1,1]:light_pool(p+Vector2(side*width*.28,-24),54,.8)
		elif int(prop.tile)==13:light_pool(p,86,1.3)
	for object in r.objects:
		if object.kind=='rest':light_pool(Vector2(object.x,object.y),80,1.2)
	var last=Vector2(r.spawn[0],r.spawn[1])
	for o in r.objects:
		if o.kind not in ['puzzle','anomaly','ending']:continue
		var p=Vector2(o.x,o.y)
		draw_polyline(PackedVector2Array([last,Vector2(p.x,last.y),p]),Color('#364952'),9)
		draw_polyline(PackedVector2Array([last+Vector2(0,-2),Vector2(p.x,last.y-2),p]),Color('#a58b68'),3)
		last=p
	for footprint in tracks:
		var alpha=maxf(0,1-(clock-footprint.time)/8.0)*.20
		var p=footprint.pos+footprint.dir.orthogonal()*footprint.side*7
		draw_line(p,p-footprint.dir*6,Color(.13,.24,.3,alpha),3)
	for e in game.combat.enemies:
		if e.state!='windup':continue
		var progress=clampf(1-e.timer/maxf(.01,e.windup_duration),0,1)
		var warning=Color('#efaa70');var edge=Color('#162b34');var glow=.35+progress*.42
		if e.kind=='boss' and e.pattern==1:
			draw_circle(e.aim,155,Color(warning,.018+.025*progress));draw_arc(e.aim,155,0,TAU,64,Color(edge,.68),5);draw_arc(e.aim,155,0,TAU,64,Color(warning,glow),2)
			var inner=155*(.18+.82*progress);draw_arc(e.aim,inner,0,TAU,48,Color(warning,.46+.30*progress),2)
		elif e.kind=='boss' and e.pattern==2:
			var rays=game.combat.fan_directions(e);var fan=PackedVector2Array([e.pos])
			for ray in rays:fan.append(e.pos+ray*530)
			draw_colored_polygon(fan,Color(warning,.012+.018*progress))
			for ray in rays:
				warning_dashes(e.pos+ray*34,e.pos+ray*530,Color(warning,.24+.30*progress),1.5,10,.38)
				var mark=e.pos+ray*(80+progress*320);draw_line(mark-ray*7,mark+ray*8,Color(warning,.86),3)
		elif e.kind=='ranged' or (e.kind=='boss' and e.pattern==0):
			var end=e.pos+e.direction*(1100 if e.kind=='boss' else 500);var width=106.0 if e.kind=='boss' else 10.0;var side=e.direction.orthogonal()*width/2
			if e.kind=='boss':draw_line(e.pos,end,Color(warning,.018+.025*progress),width)
			for sign in [-1,1]:
				draw_line(e.pos+side*sign,end+side*sign,Color(edge,.62),5);draw_line(e.pos+side*sign,end+side*sign,Color(warning,.58+.22*progress),2)
			warning_dashes(e.pos+e.direction*24,end,Color(warning,.34+.28*progress),2,14,.42)
			var tip=e.pos.lerp(end,.10+progress*.56);draw_polyline(PackedVector2Array([tip-e.direction*12+e.direction.orthogonal()*9,tip,tip-e.direction*12-e.direction.orthogonal()*9]),Color(warning,.9),3)
		else:
			var radius=float(e.spec.reach)+12
			draw_circle(e.pos,radius,Color(warning,.016+.020*progress));draw_arc(e.pos,radius,0,TAU,40,Color(edge,.68),5)
			for q in range(4):draw_arc(e.pos,radius,q*PI/2+.10,q*PI/2+1.08,10,Color(warning,.48+.30*progress),2)
			draw_arc(e.pos,radius+4,-PI/2,-PI/2+TAU*progress,40,Color(warning,.9),3)
	for o in r.objects:
		if not view.has_point(Vector2(o.x,o.y)):continue
		if o.kind=='ending' and not 'regulador' in game.state.done:continue
		var done=o.id in game.state.done
		if done and o.kind not in ['rest','note']:continue
		var p=Vector2(o.x,o.y)
		if not o.get('npc',false):
			if o.kind=='chest':tile_at(FLOOR,Rect2(320,272,16,16),Rect2(p-Vector2(24,40),Vector2(48,48)),Color('#d9b287'))
			elif o.kind=='rest':tile_at(FLOOR,Rect2(256+int(clock*8)%8*16,0,16,16),Rect2(p-Vector2(24,55),Vector2(48,48)))
		var marker=p-Vector2(0,68)
		draw_colored_polygon(PackedVector2Array([marker+Vector2(0,-6),marker+Vector2(5,0),marker+Vector2(0,6),marker-Vector2(5,0)]),ICE if done else GOLD)
	if game.state.room<5:
		var p=Vector2(r.exit[0],r.exit[1]);var ready=game.catalog.required_remaining(game.state.room,game.state.done).is_empty()
		draw_arc(p,32,0,TAU,32,ICE if ready else Color('#a88e6c'),3)
		draw_polyline(PackedVector2Array([p+Vector2(-7,-12),p+Vector2(7,0),p+Vector2(-7,12)]),ICE,3)
	if game.preferences.reduced_motion:return
	for flake in snow:
		if r.weather<=0:break
		var p=center+Vector2(wrapf(flake.x+clock*15*flake.z,-900,900),wrapf(flake.y+clock*20*flake.z,-500,500))
		draw_rect(Rect2(p,Vector2(2,2)),Color(.9,.95,.97,flake.z*.55*r.weather))
