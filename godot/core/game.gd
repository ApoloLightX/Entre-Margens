extends Node
## Composition root and command routing, not implementations of domain rules.
const Catalog=preload("res://core/catalog.gd")
const State=preload("res://core/state.gd")
const Inventory=preload("res://systems/inventory.gd")
const Farming=preload("res://systems/farming.gd")
const Economy=preload("res://systems/economy.gd")
const Relationships=preload("res://systems/relationships.gd")
const Quests=preload("res://systems/quests.gd")
const Memory=preload("res://systems/memory.gd")
const Clock=preload("res://systems/clock.gd")
const Foraging=preload("res://systems/foraging.gd")
const SaveService=preload("res://systems/save_service.gd")
const World=preload("res://scenes/world.gd")
const HUD=preload("res://scenes/hud.gd")
const TouchControls=preload("res://scenes/touch_controls.gd")
const Ambient=preload("res://systems/ambient_audio.gd")
const Abilities=preload("res://systems/abilities.gd")
const Enemies=preload("res://systems/enemies.gd")
const Combat=preload("res://systems/combat.gd")
var catalog=Catalog.new()
var state=State.new()
var inventory=Inventory.new(state,catalog)
var farming=Farming.new(state,catalog,inventory)
var economy=Economy.new(state,catalog,inventory)
var relationships=Relationships.new(state,catalog)
var quests=Quests.new(state,catalog,inventory)
var memory=Memory.new(state,inventory)
var clock=Clock.new(state)
var foraging=Foraging.new(state,inventory,memory,catalog)
var saves=SaveService.new()
var world:Node2D
var ui:CanvasLayer
var audio:Node
var abilities=Abilities.new()
var enemies=Enemies.new(state)
var combat=Combat.new(state,abilities,enemies)
var touch_controls:Node2D
var app_suspended=false

func _ready() -> void:
	assert(catalog.validate().is_empty())
	configure_input()
	world=World.new();world.game=self;add_child(world)
	enemies.reset_zone()
	ui=HUD.new();ui.game=self;add_child(ui)
	audio=Ambient.new();audio.game=self;add_child(audio)
	touch_controls=TouchControls.new();touch_controls.game=self;ui.add_child(touch_controls)
	get_tree().auto_accept_quit=false
	world.update_npcs(0)
	ui.show_title()
	if "--capture" in OS.get_cmdline_user_args():
		call_deferred("capture")
	if "--smoke" in OS.get_cmdline_user_args():
		call_deferred("smoke")

func configure_input() -> void:
	var mappings={"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"attack":[KEY_K,KEY_ENTER],"journal":[KEY_J],"inventory":[KEY_I],"pause":[KEY_ESCAPE],"cast":[KEY_SPACE,KEY_1]}
	for action in mappings:
		if not InputMap.has_action(action):InputMap.add_action(action)
		for key in mappings[action]:
			var e=InputEventKey.new();e.physical_keycode=key;InputMap.action_add_event(action,e)
	for entry in [["interact",JOY_BUTTON_A],["journal",JOY_BUTTON_Y],["pause",JOY_BUTTON_B],["inventory",JOY_BUTTON_START],["cast",JOY_BUTTON_X]]:
		var e=InputEventJoypadButton.new();e.button_index=entry[1];InputMap.action_add_event(entry[0],e)
	for entry in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0]]:
		var e=InputEventJoypadMotion.new();e.axis=entry[1];e.axis_value=entry[2];InputMap.action_add_event(entry[0],e)

func _process(delta:float) -> void:
	if app_suspended or ui==null or ui.is_open() or not state.data.started:return
	var movement=Input.get_vector("move_left","move_right","move_up","move_down")
	if touch_controls!=null:movement=(movement+touch_controls.direction).limit_length(1.0)
	world.move_player(movement,delta)
	combat.tick(delta);enemies.tick(delta,world.player())
	if state.data.health<=0:state.data.health=100;ui.toast("Você recuou para a margem.")
	if clock.advance(delta):sleep_day()

func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if ui.mode in ["title","creation","intro"]: return
		if ui.is_open():ui.close()
		else:ui.show_pause()
	elif event.is_action_pressed("cast") and ui.mode=="fishing":finish_fishing(state.data.zone=="cave",false)
	elif event.is_action_pressed("attack") and not ui.is_open() and state.data.started:attack()
	elif event.is_action_pressed("cast") and not ui.is_open() and state.data.started:cast_ability()
	elif not ui.is_open() and state.data.started:
		if event.is_action_pressed("journal"):ui.show_journal()
		elif event.is_action_pressed("inventory"):ui.show_inventory()
		elif event.is_action_pressed("interact"):interact()
		elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			var near:Dictionary=world.nearest()
			if not near.is_empty() and Vector2(near.pos[0],near.pos[1]).distance_to(world.get_global_mouse_position())<55:interact()

func show_menu(id:String) -> void:
	if not state.data.started or ui.mode in ["title","creation"]:return
	match id:
		"journal":ui.show_journal()
		"inventory":ui.show_inventory()
		_:ui.show_pause()

func new_game(name_value:String,pronouns:String,origin:String,color:int,hair:int) -> void:
	state.reset()
	state.data.name=name_value if name_value!="" else "Viajante"
	state.data.pronouns=pronouns;state.data.origin=origin;state.data.color=color;state.data.hair=hair;state.data.started=true
	world.npc_positions.clear();world.update_npcs(0)
	ui.show_intro()
	# Explicit new game creation is the replacement boundary for this prototype's one slot.
	save_game()

func change_zone(zone:String) -> void:
	state.data.zone=zone
	state.data.position=[640,560]
	enemies.reset_zone()
	ui.close()

func return_village() -> void:
	var old:String=state.data.zone
	state.data.zone="village"
	state.data.position=[218,295] if old=="house" else [825,260] if old=="shop" else [1110,215]

func interact() -> void:
	var t:Dictionary=world.nearest()
	if t.is_empty():ui.toast("Aproxime-se de uma pessoa ou objeto para interagir.");return
	match t.kind:
		"npc":ui.show_dialogue(t.id)
		"plot":ui.toast(farming.interact(t.id))
		"forage":ui.toast(foraging.gather(t.id,t.item,int(t.amount)))
		"building":
			match t.id:
				"house":change_zone("house")
				"shop":change_zone("shop")
				"archive":ui.begin("archive","Arquivo da Margem","Cópias, relatos e trabalho de conferir") ;ui.add_text("Os relatos da crise de Iqaluit falam da cooperação entre Inuit, Tenhujin e Jaci. Há versões diferentes sobre quem tornou a aliança possível. Lior deixou uma nota na margem: uma cópia pode preservar tanto um testemunho quanto um erro.\n\nNa vila, a história ainda está sendo escrita. Lior trabalha entre o arquivo e a praça.");ui.back()
				"cafe":ui.begin("cafe","Mesa Baixa");ui.add_text("Há caldo e conversa no salão. Procure Ivo junto à mesa ou à cozinha para saber o que falta hoje. Você pode preparar caldo na bancada de casa.");ui.back()
		"object":
			match t.id:
				"exit":return_village()
				"heat":ui.toast(farming.heat_action())
				"sign":ui.toast(memory.sign())
				"fish","cavefish":ui.show_fishing(t.id=="cavefish")
				"cave":change_zone("cave")
				"trade":ui.show_shop()
				"bench":ui.show_crafting()
				"journal":ui.show_journal()
				"regulator":ui.show_regulator()
				"bed":
					ui.begin("sleep","Encerrar o dia?","Leitos úmidos crescem de acordo com calor. O circuito ligado consome 1 musgo.")
					ui.add_text("Você pode dormir cedo. A vila continuará amanhã; contratos e provas ficam registrados.")
					ui.add_button("Dormir e salvar",sleep_day)
					ui.back()

func attack() -> void:
	var d=Input.get_vector("move_left","move_right","move_up","move_down")
	if d.length()<0.1:d=Vector2.RIGHT
	var message=combat.basic_attack(d)
	if message!="":ui.toast(message)

func cast_ability(id:String="") -> void:
	var chosen=id if id!="" else state.data.ability
	ui.toast(combat.cast(chosen))

func sleep_day() -> void:
	farming.overnight()
	clock.new_day()
	var message=memory.overnight()
	state.data.zone="house";state.data.position=[450,470]
	world.npc_positions.clear();world.update_npcs(0)
	ui.close()
	if save_game():ui.toast(message)

func finish_fishing(cave:bool,automatic:bool) -> void:
	if ui.mode!="fishing":return
	var success=automatic or (ui.fishing_bar.value>=30 and ui.fishing_bar.value<=75)
	ui.close()
	ui.toast(foraging.fish(success,cave))

func resolve_mystery(choice:String) -> void:
	var before:String=state.data.ending
	var message=memory.resolve(choice)
	if before=="" and state.data.ending!="":
		quests.claim("memory")
		save_game()
		ui.begin("ending","A margem continua","Primeiro arco concluído • +40 fichas • a vila permanece jogável")
		ui.add_text(message,24)
		ui.add_text("Você não explicou o mundo inteiro. Aprendeu a conferir uma diferença com quem mora aqui. Amanhã ainda haverá caldo, leitos para cuidar e coisas para descobrir.")
		ui.add_text("Este é o encerramento do recorte 0.2. O mistério completo da Trama e os romances estão planejados no GDD, ainda não implementados.",16)
		ui.back()
	else:ui.toast(message)

func save_game() -> bool:
	var ok=saves.save_state(state)
	ui.toast("Vida na margem salva." if ok else saves.last_error)
	return ok

func load_game() -> void:
	if saves.load_state(state):
		world.npc_positions.clear();world.update_npcs(0);ui.close();ui.toast(saves.last_error if saves.last_error!="" else "Bem-vinde de volta à margem.")
	else:ui.toast(saves.last_error)

func objective_text() -> String:
	if state.data.ending!="":return "Arco concluído • continue cultivando, pescando e conhecendo seus vizinhos."
	if state.data.anomaly:return "Algo mudou no cais. Compare placa + leitura da galeria; faça um estojo, ancore uma prova e volte ao regulador."
	if not state.data.repaired:return "Primeiro cuidado: 3 fibras + 2 pedras na calha. Raízes toleram frio; fungos precisam do circuito aquecido."
	return "Uma vida por construir • converse com os vizinhos, cuide dos leitos e registre o que encontrar."

func smoke() -> void:
	state.data.started=true
	for zone in ["village","house","shop","cave"]:
		state.data.zone=zone
		world.queue_redraw()
		await get_tree().process_frame
	for id in ["dena","ivo","sena","lior","tovan","neri"]:
		ui.show_dialogue(id)
		await get_tree().process_frame
	ui.show_inventory();await get_tree().process_frame
	ui.show_shop();await get_tree().process_frame
	ui.show_crafting();await get_tree().process_frame
	ui.show_journal();await get_tree().process_frame
	ui.show_regulator();await get_tree().process_frame
	ui.show_fishing(false);await get_tree().process_frame
	ui.show_pause();await get_tree().process_frame
	ui.close()
	print("SCENE_SMOKE_OK")
	get_tree().quit()

func capture() -> void:
	state.data.started=true
	state.data.minute=700.0
	ui.close()
	for zone in ["village","house","shop","cave"]:
		state.data.zone=zone
		state.data.position=[350,470] if zone=="village" else [570,480]
		world.queue_redraw()
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/em_"+zone+".png")
	ui.show_journal()
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/em_journal.png")
	ui.show_title()
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/em_title.png")
	get_tree().quit()

func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED:
		app_suspended=true
		if touch_controls!=null:touch_controls.reset()
		if state!=null and state.data.started:saves.save_state(state)
	elif what==NOTIFICATION_APPLICATION_RESUMED:
		app_suspended=false
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if ui!=null:
			if ui.mode=="creation":ui.creation_back()
			elif ui.mode in ["title","intro"]:return
			elif ui.is_open():ui.close()
			else:ui.show_pause()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		if state!=null and state.data.started:saves.save_state(state)
		get_tree().quit()
