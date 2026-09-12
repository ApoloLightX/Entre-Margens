extends SceneTree
## Regression checks for mobile layout, navigation and presentation preferences.
## Use an isolated XDG_DATA_HOME: this script writes test saves/settings.
var game
var checks=0
var failures=[]
func _initialize():call_deferred('run')
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label);printerr('FAIL ',label)
func settle():
	await process_frame;await process_frame;await process_frame
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await settle();game.set_physics_process(false)
	game.start_new('Tela');game.set_physics_process(false)
	check(game.has_save,'new progress enables Continue immediately')
	game.hud.title();game.back();check(game.modal and game.hud.page=='title','Back on title cannot enter campaign')
	game.hud.settings_menu(true);game.back();check(game.hud.page=='title','Back returns title settings to title')
	game.continue_game();game.hud.pause_menu();game.hud.settings_menu();game.back();check(game.hud.page=='pause','Back returns in-game settings to pause')
	game.state.room=5;game.load_room();game.combat.reset();game.hud.dialogue({'title':'Teste','text':'Preparar','start_boss':true});game.back()
	check(game.combat.boss_active and game.combat.enemies.size()==1,'Android Back starts boss dialogue exactly once')
	game.state.room=0;game.load_room();game.close_modal()
	for dims in [Vector2i(960,540),Vector2i(1170,540),Vector2i(1200,540)]:
		root.size=dims;await settle();game.hud.layout_controls();await settle()
		var safe=game.preferences.safe_rect(root)
		print('LAYOUT ',root.get_visible_rect().size)
		for key in game.touch.buttons:
			var b=game.touch.buttons[key]
			check(safe.encloses(Rect2(Vector2(b.x-b.z,b.y-b.z),Vector2.ONE*b.z*2)),'touch inside safe area '+key+' '+str(dims))
		for b in game.hud.top_buttons:check(safe.encloses(b.get_global_rect()),'HUD button inside safe area '+b.text+' '+str(dims))
		game.hud.title();await settle()
		check(safe.encloses(game.hud.main_menu_card.get_global_rect()),'main menu card inside safe area '+str(dims))
		for b in game.hud.main_menu_card.find_children('*','Button',true,false):check(safe.encloses(b.get_global_rect()),'main menu action '+b.text+' '+str(dims))
		game.preferences.large_text=true
		for page in ['settings_menu','new_game','help_menu','diary','pause_menu','map_menu']:
			game.hud.call(page);await settle()
			check(safe.encloses(game.hud.panel.get_global_rect()),'large-text modal '+page+' '+str(dims))
			check(safe.encloses(game.hud.footer.get_global_rect()),'large-text fixed footer '+page+' '+str(dims))
	game.preferences.zoom=1.8;game.preferences.music_volume=0;game.preferences.effects_volume=.3;game.preferences.reduced_motion=true;game.apply_preferences()
	var saved=load('res://action/preferences.gd').new();saved.load_settings()
	check(is_equal_approx(saved.zoom,1.8) and saved.reduced_motion,'camera and motion preferences persist')
	check(is_zero_approx(saved.music_volume) and is_equal_approx(saved.effects_volume,.3),'music and effects volumes persist independently')
	game.state.elapsed=123.0;game.state.anchors=['lior'];game.apply_preferences()
	check(game.state.elapsed==123.0 and game.state.anchors==['lior'],'presentation settings preserve progress')
	root.size=Vector2i(960,540);await settle()
	game.state.room=5;game.load_room();game.close_modal();game.state.position=Vector2(680,790);game.combat.start_boss()
	for i in range(80):game.update_camera()
	game.camera.reset_smoothing();await settle()
	var boss=game.combat.enemies[0]
	var transform=game.world.get_global_transform_with_canvas()
	var head=transform*(boss.pos-Vector2(0,150));var feet=transform*game.state.position
	check(head.y>=140,'boss framing keeps the upper silhouette below the boss HUD')
	check(feet.y<=root.get_visible_rect().size.y-45,'boss framing keeps player feet inside the view')
	check(is_equal_approx(game.preferences.zoom,1.8),'temporary boss framing preserves the preferred camera scale')
	game.sound.effect('hit');game.sound.effect('cordao');game.sound.effect('fratura')
	check(game.sound.players[0].playing and game.sound.players[1].playing and game.sound.players[2].playing,'combat sound files play')
	print('PRESENTATION TESTS ',checks-failures.size(),'/',checks,' passed')
	game.sound.shutdown();await create_timer(.15).timeout
	game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
