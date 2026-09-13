extends SceneTree
## Run with isolated XDG_DATA_HOME: this test writes settings and campaign saves.
var game
var checks=0
var failures=[]
func _initialize():call_deferred('run')
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label);printerr('FAIL ',label)
func settle():
	for i in range(4):await process_frame
func run():
	var prefs=preload('res://action/preferences.gd')
	var cfg=ConfigFile.new()
	cfg.set_value('view','zoom',1.45);cfg.set_value('audio','music',.23);cfg.set_value('audio','effects',.67)
	cfg.set_value('view','reduced_motion',true);cfg.set_value('view','large_text',true)
	cfg.set_value('other','keep','yes');cfg.save(prefs.PATH)
	var p=prefs.new();p.load_settings()
	check(is_equal_approx(p.zoom,1.0),'legacy camera becomes wider')
	check(is_equal_approx(p.music_volume,.23) and is_equal_approx(p.effects_volume,.67),'audio preferences survive migration')
	check(p.reduced_motion and p.large_text,'accessibility preferences survive migration')
	cfg.load(prefs.PATH)
	check(cfg.get_value('other','keep')=='yes','unrelated setting survives')
	check(cfg.get_value('view','camera_revision')==1,'migration persists immediately')
	p.zoom=1.2;p.save_settings();p.load_settings();check(is_equal_approx(p.zoom,1.2),'later user choice survives restart')
	p.zoom=.9;p.save_settings();p.load_settings();check(is_equal_approx(p.zoom,.9),'wide end of slider persists')
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game);await settle()
	game.set_physics_process(false);game.start_new('Câmera');game.set_physics_process(false)
	game.state.elapsed=91;game.state.anchors=['lior'];game.save_progress()
	var before=FileAccess.get_sha256('user://entre_margens_action_v4.json')
	game.preferences.zoom=1.0;game.apply_preferences()
	check(game.state.elapsed==91 and game.state.anchors==['lior'],'camera preserves current progress')
	check(before==FileAccess.get_sha256('user://entre_margens_action_v4.json'),'camera does not rewrite campaign file')
	game.preferences.large_text=false
	for dims in [Vector2i(960,540),Vector2i(1170,540),Vector2i(1200,540),Vector2i(2772,1280)]:
		root.size=dims;await settle()
		var visible=root.get_visible_rect().size
		var wider=visible/game.preferences.zoom;var old=visible/1.45
		check(wider.x/old.x>1.449 and wider.y/old.y>1.449,'45 percent more view '+str(dims))
		for room in range(6):
			game.state.room=room;game.load_room();game.close_modal()
			var bounds=Vector2(game.current_room().size[0],game.current_room().size[1])
			for pos in [Vector2(60,105),bounds/2,bounds-Vector2(60,85)]:
				game.state.position=pos
				for i in range(80):game.update_camera()
				game.camera.reset_smoothing();await settle()
				var view=Rect2(game.camera.get_screen_center_position()-wider/2,wider)
				check(Rect2(Vector2(-1,-1),bounds+Vector2(2,2)).encloses(view),'room limits '+str(room)+' '+str(pos)+' '+str(dims))
		game.state.room=5;game.load_room();game.close_modal();game.state.position=Vector2(680,790);game.combat.start_boss()
		for i in range(80):game.update_camera()
		game.camera.reset_smoothing();await settle()
		var transform=game.world.get_global_transform_with_canvas()
		var head=transform*(game.combat.enemies[0].pos-Vector2(0,150));var feet=transform*game.state.position
		check(head.y>=140 and feet.y<=visible.y-45,'boss and player framing '+str(dims))
		check(is_equal_approx(game.preferences.zoom,1.0),'boss preserves camera choice '+str(dims))
	print('CAMERA TESTS ',checks-failures.size(),'/',checks,' passed')
	game.sound.shutdown();await create_timer(.15).timeout;game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
