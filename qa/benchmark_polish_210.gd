extends SceneTree
var game
func _initialize():call_deferred('run')
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame;game.start_new('Viajante');game.set_physics_process(false)
	game.preferences.reduced_motion=true;game.camera.zoom=Vector2.ONE
	var results=[]
	for room in [0,1]:
		for enabled in [false,true,false,true]:
			game.world.environment_polish=enabled;game.state.room=room;game.load_room();game.close_modal()
			game.state.position=Vector2(650,530) if room==0 else Vector2(900,510)
			game.camera.position=game.state.position;game.camera.reset_smoothing();game.room_banner=0;game.toast_timer=0;game.hud.update_status()
			for i in range(10):await process_frame
			var samples=[];var calls=[]
			for i in range(60):
				var start=Time.get_ticks_usec();await process_frame
				samples.append((Time.get_ticks_usec()-start)/1000.0)
				calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			samples.sort();calls.sort()
			results.append({'room':room,'pilot':enabled,'median_frame_ms':samples[30],'p95_frame_ms':samples[57],'draw_calls':calls[30],'nodes':get_node_count()})
	var f=FileAccess.open('/tmp/entre-benchmark.json',FileAccess.WRITE);f.store_string(JSON.stringify(results,'  '));f.close()
	game.sound.shutdown();game.queue_free();await process_frame;quit()
