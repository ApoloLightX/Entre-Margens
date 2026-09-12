extends SceneTree
var game
var output_dir=ProjectSettings.globalize_path('res://../qa/review_captures')
func _initialize():call_deferred('run')
func rect_text(r:Rect2)->String:return '%.2f,%.2f,%.2f,%.2f'%[r.position.x,r.position.y,r.size.x,r.size.y]
func settle():
	for i in range(5):await process_frame
func shot(label:String,dims:Vector2i):
	root.size=dims
	await settle()
	game.hud.update_status();game.touch.queue_redraw()
	await settle();await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.get_texture().get_image().save_png(output_dir.path_join(label+'.png'))
	var safe=game.preferences.safe_rect(root);var core=game.hud.gameplay_core_rect()
	print('QA|',label,'|window=',dims,'|visible=',root.get_visible_rect().size,'|safe=',rect_text(safe),'|core=',rect_text(core),'|status=',rect_text(game.hud.status_block.get_global_rect()),'|heal=',rect_text(game.hud.heal_button.get_global_rect()),'|top=',rect_text(game.hud.top_action_bar.get_global_rect()),'|context=',rect_text(game.hud.context_box.get_global_rect()),'|joy=',rect_text(game.hud.joystick_anchor.get_global_rect()),'|grid=',rect_text(game.hud.action_grid.get_global_rect()))
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await settle();game.set_physics_process(false);game.preferences.reduced_motion=true;game.preferences.zoom=1.45
	game.start_new('QA');game.set_physics_process(false);game.state.position=Vector2(490,600);game.camera.position=game.state.position;game.camera.reset_smoothing();game.toast_timer=0;game.room_banner=0;game.close_modal()
	await shot('landscape_16_9',Vector2i(960,540))
	await shot('landscape_19_5_9',Vector2i(1170,540))
	await shot('landscape_20_9',Vector2i(1200,540))
	await shot('portrait_stress',Vector2i(540,960))
	game.sound.shutdown();await create_timer(.1).timeout;game.queue_free();await process_frame;quit()
