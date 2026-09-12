extends Node
## Composition root. Content, simulation, presentation, input and persistence are separate.
var catalog=preload('res://action/campaign.gd').new()
var state=preload('res://action/state.gd').new()
var saves=preload('res://action/save.gd').new()
var combat=preload('res://action/combat.gd').new()
var world
var hud
var touch
var sound
var camera:Camera2D
var modal=true
var pending_fall=false
var movement=Vector2.ZERO
var toast_text=''
var toast_timer=0.0
var auto_save=0.0
var room_banner=0.0
var checkpoint=Vector2.ZERO
var has_save=false
var session_active=false
var app_paused=false
var preferences=preload('res://action/preferences.gd').new()
func _ready():
	preferences.load_settings()
	combat.setup(self)
	world=preload('res://action/world.gd').new();world.game=self;add_child(world)
	camera=Camera2D.new();camera.position_smoothing_enabled=true;camera.position_smoothing_speed=7;world.add_child(camera)
	camera.zoom=Vector2.ONE*preferences.zoom
	sound=preload('res://action/audio.gd').new();sound.game=self;add_child(sound)
	var canvas=CanvasLayer.new();add_child(canvas)
	var vignette=ColorRect.new();vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shade=ShaderMaterial.new();shade.shader=preload('res://action/vignette.gdshader');vignette.material=shade
	canvas.add_child(vignette);vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud=preload('res://action/hud.gd').new();hud.game=self;canvas.add_child(hud)
	touch=preload('res://action/touch.gd').new();touch.game=self;canvas.add_child(touch)
	has_save=saves.load_into(state)
	load_room(false);hud.title()
	if '--action-smoke' in OS.get_cmdline_user_args():call_deferred('smoke')
func current_room()->Dictionary:return catalog.room(state.room)
func load_room(reset_position=true):
	combat.reset()
	var r=current_room()
	checkpoint=Vector2(r.spawn[0],r.spawn[1])
	if reset_position:state.position=checkpoint
	var bounds=Vector2(r.size[0],r.size[1]);state.position=state.position.clamp(Vector2(50,100),bounds-Vector2(50,80))
	if not walkable(state.position,19):state.position=checkpoint
	camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(bounds.x);camera.limit_bottom=int(bounds.y)
	camera.position=state.position;camera.reset_smoothing();room_banner=4
	world.refresh();sound.set_mood(state.anomaly,state.room==5)
	if state.room==5 and 'boss_start' in state.done and not 'regulador' in state.done:combat.start_boss()
func start_new(player_name:String):
	state.reset();state.name=player_name.strip_edges().left(24)
	if state.name=='':state.name='Viajante'
	state.started=true;session_active=true;load_room();close_modal();save_progress()
	toast('Mova-se pelo analógico. Aproxime-se de Dena e toque em CONVERSAR.')
func continue_game():
	state.started=true;session_active=true;close_modal();load_room(false)
	if state.ending!='':hud.epilogue()
func _physics_process(dt):
	toast_timer=maxf(0,toast_timer-dt);room_banner=maxf(0,room_banner-dt)
	if session_active and not app_paused and state.ending=='' and hud.page not in ['pause','settings','credits','help','title','new']:state.elapsed+=dt
	if not modal:
		movement=input_direction();combat.tick(dt,movement)
		if touch.attack_held:combat.attack()
		if pending_fall:resolve_fall()
		update_camera()
		camera.offset=Vector2(sin(Time.get_ticks_msec()*.09),cos(Time.get_ticks_msec()*.13))*combat.shake if not preferences.reduced_motion else Vector2.ZERO
		auto_save+=dt
		if auto_save>15:auto_save=0;save_progress()
	else:movement=Vector2.ZERO
	world.queue_redraw();touch.queue_redraw();hud.update_status()
func input_direction()->Vector2:
	var dir=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if touch.direction.length()>.1:dir=touch.direction
	if not Input.get_connected_joypads().is_empty():
		var joy=Input.get_connected_joypads()[0];var stick=Vector2(Input.get_joy_axis(joy,JOY_AXIS_LEFT_X),Input.get_joy_axis(joy,JOY_AXIS_LEFT_Y))
		if stick.length()>.2:dir=stick
	return dir.limit_length()
func update_camera():
	var target=state.position-Vector2(0,36)+combat.facing*22
	var distance=preferences.zoom
	if combat.boss_active:
		for e in combat.enemies:
			if e.kind=='boss':
				var top=minf(state.position.y-72,e.pos.y-150)
				var bottom=maxf(state.position.y+12,e.pos.y+18)
				var visible=get_viewport().get_visible_rect().size
				distance=clampf(minf((visible.y-210)/(bottom-top),(visible.x-140)/(absf(state.position.x-e.pos.x)+190)),.90,minf(distance,1.20))
				target=Vector2((state.position.x+e.pos.x)/2,(top+bottom)/2-48/distance)
				break
	camera.position=target
	camera.zoom=camera.zoom.lerp(Vector2.ONE*distance,.10)
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			back()
			return
		if modal:return
		match event.physical_keycode:
			KEY_J:combat.attack()
			KEY_K:combat.cast()
			KEY_SPACE:combat.dodge(input_direction())
			KEY_E:interact()
			KEY_Q:switch_technique()
			KEY_TAB:hud.diary()
			KEY_H:heal()
	if event is InputEventJoypadButton and event.pressed and not modal:
		match event.button_index:
			JOY_BUTTON_X:combat.attack()
			JOY_BUTTON_Y:combat.cast()
			JOY_BUTTON_A:combat.dodge(input_direction())
			JOY_BUTTON_B:interact()
			JOY_BUTTON_LEFT_SHOULDER:heal()
			JOY_BUTTON_RIGHT_SHOULDER:switch_technique()
			JOY_BUTTON_START:hud.pause_menu()
func walkable(pos:Vector2,radius:float)->bool:
	var r=current_room()
	if pos.x<40+radius or pos.y<90+radius or pos.x>r.size[0]-40-radius or pos.y>r.size[1]-45-radius:return false
	for p in r.props:
		if not p.solid:continue
		var half=float(p.size)*.24
		var collision=Rect2(Vector2(p.x-half,p.y-22),Vector2(half*2,35)).grow(radius)
		if collision.has_point(pos):return false
	return true
func safe_move(pos:Vector2,delta:Vector2,radius:float)->Vector2:
	# Substeps prevent dashes tunneling through thin footprints.
	var steps=maxi(1,int(ceil(delta.length()/12)))
	for i in range(steps):
		var step=delta/steps
		var x=pos+Vector2(step.x,0)
		if walkable(x,radius):pos=x
		var y=pos+Vector2(0,step.y)
		if walkable(y,radius):pos=y
	return pos
func move_player(delta:Vector2):state.position=safe_move(state.position,delta,19)
func nearest_object()->Dictionary:
	var closest={};var distance=100.0
	for o in current_room().objects:
		if o.kind=='ending' and not 'regulador' in state.done:continue
		var d=state.position.distance_to(catalog.point(o))
		if d<distance:distance=d;closest=o
	var exit_pos=Vector2(current_room().exit[0],current_room().exit[1])
	if state.position.distance_to(exit_pos)<105 and state.room<5:return {'kind':'exit','title':'Próxima passagem'}
	return closest
func nearby_threat()->bool:
	for e in combat.enemies:
		if e.pos.distance_to(state.position)<390:return true
	return false
func interact():
	var o=nearest_object()
	if o.is_empty():toast('Aproxime-se de uma pessoa, marca ou passagem.');return
	if nearby_threat():toast('Afaste as sentinelas antes de investigar.');return
	if o.kind=='exit':
		var missing=catalog.required_remaining(state.room,state.done)
		if not missing.is_empty():toast('Ainda há '+str(missing.size())+' ponto(s) marcado(s) para investigar. Abra o mapa.');return
		state.room+=1;load_room();save_progress();return
	if o.kind=='rest':
		checkpoint=state.position;state.health=state.max_health();state.focus=100;state.heals=maxi(state.heals,2)
		save_progress();hud.rest(o);sound.effect('chime');return
	if o.kind=='chest':
		if o.id in state.done:toast('Você já recolheu esta reserva.');return
		state.done.append(o.id);state.parts+=10;state.heals=mini(5,state.heals+1);save_progress()
		toast('+10 peças de cobre · +1 curativo');sound.effect('chime');return
	if o.kind=='ending':hud.ending_choice();return
	if o.kind=='puzzle' and not o.id in state.done:hud.puzzle(o);return
	if o.kind=='anomaly' and not o.id in state.done:
		state.anomaly=true;sound.set_mood(true,false)
	if o.kind=='note' and not o.id in state.evidence:state.evidence.append(o.id)
	if o.has('technique') and not o.technique in state.learned:
		state.learned.append(o.technique);state.technique=o.technique
	if not o.id in state.done:state.done.append(o.id)
	save_progress();hud.dialogue(o)
func puzzle_answer(o:Dictionary,index:int):
	if index!=int(o.solution):
		hud.dialogue({'title':'A pressão retorna','text':'O circuito recusa a ligação. A saída segura acompanha o contorno e evita alimentar o centro. Observe novamente as marcas. Nenhum recurso foi perdido.'})
		return
	if not o.id in state.done:state.done.append(o.id)
	state.parts+=5;save_progress();sound.effect('chime')
	hud.dialogue({'title':o.title,'text':o.success+'\n\n+5 peças de cobre. O próximo ponto aparece no mapa.'})
func anchor(id:String):
	if id in state.anchors:
		state.anchors.erase(id);state.anchor_records.erase(id)
	elif state.anchors.size()<3:
		state.anchors.append(id)
		var o=catalog.object_by_id(id)
		state.anchor_records[id]=o.get('altered',o.text) if state.anomaly else o.get('anchor_text',o.text)
	else:toast('Três âncoras ativas. Solte uma para proteger outro registro.');return
	save_progress();hud.diary()
func upgrade():
	var cost=20+state.upgrades*15
	if state.upgrades>=3:toast('Equipamento totalmente reforçado.');return
	if state.parts<cost:toast('Faltam peças: o reforço custa '+str(cost)+'.');return
	state.parts-=cost;state.upgrades+=1;state.health=state.max_health();save_progress();hud.rest({'title':'Equipamento reforçado'})
func heal():
	if state.heals<=0:toast('Sem curativos. Procure uma lanterna.');return
	if state.health>=state.max_health():return
	state.heals-=1;state.health=minf(state.max_health(),state.health+55);sound.effect('chime');save_progress()
func switch_technique():
	var available=[]
	for id in ['cordao','fratura','contrapeso']:
		if id in state.learned:available.append(id)
	if available.size()<2:toast('Uma segunda técnica aguarda na Galeria.');return
	var index=available.find(state.technique);state.technique=available[(index+1)%available.size()]
	toast('Técnica: '+state.technique.to_upper())
func fall():pending_fall=true
func resolve_fall():
	pending_fall=false;state.deaths+=1;state.position=checkpoint;state.health=state.max_health();state.focus=100;state.heals=maxi(state.heals,2)
	combat.reset();camera.position=state.position;camera.reset_smoothing();save_progress()
	hud.dialogue({'title':'A luz ainda está acesa','text':'Você recua até o último abrigo. Pistas, equipamentos e encontros concluídos foram preservados. Os mecanismos do confronto interrompido se reorganizaram.\n\nPode ativar "Combate acessível" no menu para reduzir o dano recebido. O final permanece o mesmo.'})
	if state.room==5 and 'boss_start' in state.done and not 'regulador' in state.done:combat.start_boss()
func finish(choice:String):
	state.ending=choice
	if not 'final_choice' in state.done:state.done.append('final_choice')
	save_progress();hud.epilogue()
func save_progress():
	if not state.started:return
	if saves.write(state):has_save=true
	else:toast('Não foi possível salvar. Mantenha o jogo aberto e verifique o espaço disponível.')
func back():
	if not modal:hud.pause_menu();return
	if hud.page=='title':return
	if hud.page=='settings' or hud.page=='credits' or hud.page=='help':
		if session_active:hud.pause_menu()
		else:hud.title()
	elif hud.page=='new':hud.title()
	elif hud.page=='dialogue':hud.continue_dialogue()
	elif hud.page=='epilogue':hud.title()
	elif session_active:close_modal()
func toast(message:String):toast_text=message;toast_timer=4.5
func close_modal():
	modal=false;hud.hide_panel();touch.release_all();camera.offset=Vector2.ZERO
func apply_preferences():
	camera.zoom=Vector2.ONE*preferences.zoom
	sound.apply_volumes();preferences.save_settings();hud.layout_controls();touch.layout_controls()
func _notification(what):
	if what==NOTIFICATION_APPLICATION_RESUMED:app_paused=false
	if what==NOTIFICATION_APPLICATION_PAUSED:
		app_paused=true
		if is_instance_valid(hud) and state.started:save_progress();hud.pause_menu()
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(hud):back()
func smoke():
	state.started=true;modal=false
	await get_tree().process_frame
	print('ACTION_SMOKE maps=',catalog.rooms.size(),' objects=',current_room().objects.size(),' UI=',hud.get_child_count())
	sound.shutdown()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()

func _exit_tree():
	combat.game=null
	preload('res://action/actor.gd').cache.clear()
	preload('res://action/icons.gd').cache.clear()
