extends AnimatedSprite2D
## CC0 Shade sprites: eight directions, four walk and four sword frames.
## The sprite owns presentation only. Feet and hitboxes remain in combat state.
var style='traveller'
var pose='idle'
var direction=0
static var cache:Dictionary={}
const SEQUENCES={'idle':[0,1],'walk':[2,3,4,5],'attack':[6,7,8,9],'brace':[10,11],'cast':[12,13,14,15],'hurt':[18],'dodge':[2,3,4,5]}
func configure(id:String):
	style=id;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if not cache.has(id):
		var sheet=load('res://assets/sprites/characters/'+id+'.png')
		var frames=SpriteFrames.new();frames.remove_animation('default')
		for anim in SEQUENCES:
			for row in range(8):
				var key=anim+str(row);frames.add_animation(key)
				frames.set_animation_speed(key,8 if anim=='walk' else (2 if anim=='idle' else 16))
				frames.set_animation_loop(key,anim in ['idle','walk','dodge'])
				for col in SEQUENCES[anim]:
					var atlas=AtlasTexture.new();atlas.atlas=sheet;atlas.region=Rect2(col*32,row*32,32,32);frames.add_frame(key,atlas)
		cache[id]=frames
	sprite_frames=cache[id];offset=Vector2(0,-9);scale=Vector2(3,3)
	var shadow=Polygon2D.new();var outline=PackedVector2Array()
	for i in range(20):outline.append(Vector2(cos(i*TAU/20)*6.5,sin(i*TAU/20)*2.3))
	shadow.polygon=outline;shadow.position.y=-2;shadow.color=Color(.02,.055,.07,.28);shadow.show_behind_parent=true;add_child(shadow)
	play('idle0')
func present(feet:Vector2,facing:Vector2,kind:String,progress=-1.0,flash=false):
	position=feet.round();z_index=int(feet.y)
	if style=='traveller' and get_parent()!=null:
		var g=get_parent().get('game')
		if g!=null and g.combat.guard_time>0:
			kind='brace';var duration=maxf(.01,float(g.catalog.combat.techniques.contrapeso.duration));progress=clampf(1-g.combat.guard_time/duration,0,1)
	# Atlas rows run S, SE, E, NE, N, NW, W, SW.
	direction=posmod(int(round((PI/2-facing.angle())/(PI/4))),8)
	var key=kind+str(direction)
	if animation!=key:play(key)
	if progress>=0:
		pause();frame=mini(sprite_frames.get_frame_count(key)-1,int(progress*sprite_frames.get_frame_count(key)))
	elif not is_playing():play(key)
	modulate=Color(1.65,1.25,.95) if flash else Color.WHITE
	offset=Vector2(0,-9);rotation=0;scale=Vector2(3,3)
	var pose_t=clampf(progress if progress>=0 else 0.0,0,1);var pulse=sin(pose_t*PI)
	if kind=='attack':
		scale=Vector2(3.0+.18*pulse,3.0-.08*pulse);rotation=facing.x*.055*pulse;offset+=facing*2.5*pulse
	elif kind=='cast':
		scale=Vector2(3.0+.07*pulse,3.0+.11*pulse);offset.y-=3.0*pulse
	elif kind=='hurt':
		scale=Vector2(3.16,2.78);offset-=facing*3.0;rotation=-facing.x*.065
	elif kind=='dodge':
		scale=Vector2(3.25,2.65);rotation=facing.x*.12;offset-=facing*2.0
	elif kind=='brace':
		scale=Vector2(3.08,2.92);offset.y+=1.0
