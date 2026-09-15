extends SceneTree
var game
func _initialize():call_deferred('run')
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.start_new('Viajante');game.set_physics_process(false)
	game.preferences.zoom=1;game.preferences.reduced_motion=true;game.camera.zoom=Vector2.ONE
	for room in [0,1]:
		for enabled in [false,true]:
			game.world.environment_polish=enabled;game.state.room=room;game.load_room();game.close_modal()
			game.state.position=Vector2(450,410) if room==0 else Vector2(900,425)
			game.camera.position=game.state.position;game.camera.reset_smoothing()
			game.state.position+=Vector2(0,100)
			game.room_banner=0;game.toast_timer=0;game.world.clock=0;game.hud.update_status()
			for i in range(5):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png('/tmp/entre-'+str(room)+('-after' if enabled else '-before')+'.png')
	game.state.room=1;game.load_room();game.close_modal();game.set_physics_process(false)
	game.state.position=Vector2(830,490);game.state.technique='fratura';game.state.focus=100
	game.combat.spawn('crawler',Vector2(970,490),'capture');game.combat.effects.clear();game.combat.cast()
	game.camera.position=Vector2(940,490);game.camera.reset_smoothing();game.room_banner=0;game.toast_timer=0
	game.preferences.reduced_motion=false;game.hud.update_status()
	for phase in [.07,.25,.48,.75,.94]:
		for fx in game.combat.effects:
			if fx.kind=='fratura':fx.life=fx.max*(1-phase)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('/tmp/entre-fracture-'+str(phase)+'.png')
	game.sound.shutdown();game.queue_free();await process_frame;quit()
