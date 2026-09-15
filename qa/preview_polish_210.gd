extends SceneTree
## Staged engine demonstration with simulated touch and native audio; not a device playtest.
var game
var caption:Label
var elapsed=0.0
var active=false
var cues={}
func _initialize():call_deferred('run')
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.preferences.zoom=1;game.camera.zoom=Vector2.ONE;game.preferences.reduced_motion=false
	game.preferences.music_volume=.32;game.preferences.effects_volume=.85;game.sound.apply_volumes()
	var layer=CanvasLayer.new();root.add_child(layer)
	caption=Label.new();caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top=-42;caption.offset_bottom=-10;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override('font_size',16);caption.add_theme_color_override('font_color',Color('#f3fbff'))
	caption.add_theme_color_override('font_shadow_color',Color('#10232c'));caption.add_theme_constant_override('shadow_offset_x',2);caption.add_theme_constant_override('shadow_offset_y',2)
	layer.add_child(caption);caption.text='2.1-polish.1 · demonstração no motor · comandos simulados'
	game.start_new('Viajante')
	for room in game.catalog.rooms:
		for group in room.groups:
			if group.id not in game.state.cleared:game.state.cleared.append(group.id)
	active=true
func cue(key:String,at:float)->bool:
	if elapsed<at or cues.has(key):return false
	cues[key]=true;return true
func touch(index:int,p:Vector2,down:bool):
	var e=InputEventScreenTouch.new();e.index=index;e.position=p;e.pressed=down;game.touch._input(e)
func tap(action:String):
	var b=game.touch.buttons[action];touch(2,Vector2(b.x,b.y),true);touch(2,Vector2(b.x,b.y),false)
func move(dir:Vector2):
	game.touch.release_all()
	if not dir.is_zero_approx():touch(1,game.touch.origin+dir*game.touch.joystick_radius*.7,true)
func sample(room:int,enabled:bool):
	move(Vector2.ZERO);game.world.environment_polish=enabled;game.state.room=room;game.load_room();game.close_modal()
	game.set_physics_process(false)
	game.state.position=Vector2(450,520) if room==0 else Vector2(900,510)
	game.camera.position=Vector2(450,420) if room==0 else Vector2(900,430);game.camera.reset_smoothing();game.room_banner=0;game.toast_timer=0;game.hud.update_status()
func arena(technique:String,count:int):
	sample(1,true);game.set_physics_process(true);game.state.position=Vector2(820,590)
	game.state.health=game.state.max_health();game.state.focus=100;game.state.technique=technique;game.state.learned=['cordao','fratura','contrapeso']
	game.combat.facing=Vector2.RIGHT
	for i in range(count):game.combat.spawn('crawler' if i<2 else 'ranged',game.state.position+Vector2(140+i*52,0 if i<2 else 22),'preview')
	game.camera.position=game.state.position;game.camera.reset_smoothing()
func _process(dt):
	if not active:return false
	elapsed+=dt
	if cue('village_before',.2):sample(0,false);caption.text='VILA · antes · mesma câmera e mesmos objetos'
	if cue('village_after',3.0):sample(0,true);caption.text='VILA · piloto · copa, beiral, janelas e sombras'
	if cue('combat_before',6.0):sample(1,false);caption.text='VEREDA · antes · piso e cenário originais'
	if cue('combat_after',8.8):sample(1,true);caption.text='VEREDA · piloto · variação sutil do piso e contato'
	if cue('solo',11.6):arena('fratura',1);caption.text='FRATURA · impacto no chão · 1 inimigo'
	if cue('solo_cast',12.0):tap('cast')
	if cue('solo_again',14.5):arena('fratura',1)
	if cue('solo_cast2',14.9):tap('cast')
	if cue('crowd',17):arena('fratura',3);caption.text='FRATURA · 3 inimigos · uma ruptura por uso'
	if cue('crowd_cast',17.4):tap('cast');move(Vector2.DOWN)
	if cue('crowd_stop',17.8):move(Vector2.ZERO)
	if cue('crowd_attack',18.4):move(Vector2.RIGHT);tap('attack')
	if cue('crowd_dodge',19.0):tap('dodge')
	if cue('crowd_stop2',19.4):move(Vector2.ZERO)
	if cue('crowd_cast2',20.0):tap('cast')
	if cue('cordon',22.0):arena('cordao',3);caption.text='CORDÃO · identidade preservada · sem cratera'
	if cue('cordon_cast',22.5):tap('cast')
	if cue('counter',25.0):arena('contrapeso',3);caption.text='CONTRAPESO · defesa junto ao corpo'
	if cue('counter_cast',25.8):tap('cast')
	if cue('fight',28.0):arena('fratura',3);caption.text='Movimento, ataque e esquiva · dois dedos';move(Vector2.RIGHT)
	if cue('hold',28.4):
		var b=game.touch.buttons.attack;touch(2,Vector2(b.x,b.y),true)
	if cue('evade',29.0):tap('dodge')
	if cue('stop',29.6):move(Vector2.ZERO)
	if cue('last_cast',30):tap('cast')
	if cue('end',32):caption.text='2.1-polish.1 · avaliar impacto e pilotos no POCO F7'
	if elapsed>=34:
		active=false;game.sound.shutdown();game.queue_free();quit()
	return false
