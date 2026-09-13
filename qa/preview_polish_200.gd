extends SceneTree
## Engine capture with staged encounters and simulated touch; not device footage.
var game
var caption:Label
var elapsed=0.0
var active=false
var cues={}
var finish=false
func _initialize():call_deferred('run')
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.preferences.zoom=1.0;game.camera.zoom=Vector2.ONE;game.preferences.reduced_motion=false
	game.preferences.music_volume=.32;game.preferences.effects_volume=.85;game.sound.apply_volumes()
	var layer=CanvasLayer.new();root.add_child(layer)
	caption=Label.new();caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top=-42;caption.offset_bottom=-10;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override('font_size',16);caption.add_theme_color_override('font_color',Color('#f3fbff'))
	caption.add_theme_color_override('font_shadow_color',Color('#10232c'));caption.add_theme_constant_override('shadow_offset_x',2);caption.add_theme_constant_override('shadow_offset_y',2)
	layer.add_child(caption);caption.text='2.0-polish.2 · demonstração no motor, com comandos simulados'
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
func arena(technique:String):
	game.state.room=2;game.load_room();game.close_modal()
	game.state.position=Vector2(690,700);game.state.health=game.state.max_health();game.state.focus=100
	game.state.technique=technique;game.state.learned=['cordao','fratura','contrapeso']
	for room in game.catalog.rooms:
		for group in room.groups:
			if group.id not in game.state.cleared:game.state.cleared.append(group.id)
	game.combat.facing=Vector2.RIGHT
	game.combat.spawn('crawler',game.state.position+Vector2(125,-30),'preview')
	game.combat.spawn('shield',game.state.position+Vector2(165,35),'preview')
	game.combat.spawn('ranged',game.state.position+Vector2(315,-55),'preview')
	game.camera.position=game.state.position;game.camera.reset_smoothing();game.room_banner=0;game.toast_timer=0
func _process(dt):
	if not active:return false
	elapsed+=dt
	if cue('start',2):
		game.start_new('Viajante');game.toast_timer=0;game.room_banner=0
		caption.text='Câmera ampla · analógico e botões maiores';move(Vector2.RIGHT)
	if cue('walk_down',3.4):move(Vector2.DOWN)
	if cue('walk_stop',4.7):move(Vector2.ZERO)
	if cue('cordon',5.3):arena('cordao');caption.text='CORDÃO · cristalização no perímetro, centro livre'
	if cue('cast_cordon',6.2):tap('cast')
	if cue('attack_cordon',7.0):tap('attack')
	if cue('dodge_cordon',7.5):move(Vector2.LEFT);tap('dodge')
	if cue('stop_cordon',8.0):move(Vector2.ZERO)
	if cue('cast_cordon_again',9.2):tap('cast')
	if cue('fracture',10.8):arena('fratura');caption.text='FRATURA · fissura azul e fragmentos direcionais'
	if cue('cast_fracture',11.6):tap('cast')
	if cue('attack_fracture',12.4):tap('attack')
	if cue('dodge_fracture',12.8):move(Vector2.DOWN);tap('dodge')
	if cue('stop_fracture',13.3):move(Vector2.ZERO)
	if cue('cast_fracture_again',14.4):tap('cast')
	if cue('counter',16.1):arena('contrapeso');caption.text='CONTRAPESO · placas de gelo e resposta ao impacto'
	if cue('cast_counter',17.0):tap('cast')
	if cue('attack_counter',18.3):tap('attack')
	if cue('cancel_counter',19.2):tap('cast');tap('dodge')
	if cue('fight',21.0):arena('cordao');caption.text='Ataque + movimento com dois dedos · esquiva cancela o golpe';move(Vector2.RIGHT)
	if cue('hold_attack',21.4):
		var b=game.touch.buttons.attack;touch(2,Vector2(b.x,b.y),true)
	if cue('evade',22.6):tap('dodge')
	if cue('release',23.2):move(Vector2.ZERO)
	if cue('end_cast',24.0):tap('cast')
	if cue('end',25.8):caption.text='2.0-polish.2 · próxima etapa: seu teste no Android'
	if elapsed>=27.0 and not finish:
		finish=true;game.sound.shutdown();game.queue_free();quit()
	return false
