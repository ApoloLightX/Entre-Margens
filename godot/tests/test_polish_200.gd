extends SceneTree
var game
var checks=0
var failures=[]
func _initialize():call_deferred('run')
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label);printerr('FAIL ',label)
func settle():
	for i in range(4):await process_frame
func press(index:int,pos:Vector2,down:bool):
	var e=InputEventScreenTouch.new();e.index=index;e.position=pos;e.pressed=down;game.touch._input(e)
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game);await settle()
	game.set_physics_process(false);game.start_new('Verificação');game.set_physics_process(false)
	for dims in [Vector2i(960,540),Vector2i(1170,540),Vector2i(1200,540),Vector2i(2772,1280)]:
		root.size=dims;await settle()
		var safe=game.preferences.safe_rect(root)
		for technique in ['cordao','fratura','contrapeso']:
			game.state.technique=technique;game.hud.update_status();await settle()
			for b in game.hud.top_buttons:
				check(safe.encloses(b.get_global_rect()),'top action remains safe '+technique+' '+str(dims))
		var t=game.touch
		var jr=t.joystick_radius+t.JOYSTICK_HIT_PADDING
		check(safe.encloses(Rect2(t.origin-Vector2.ONE*jr,Vector2.ONE*jr*2)),'joystick hit area stays inside safe bounds '+str(dims))
		for key in t.buttons:
			var b=t.buttons[key];var radius=b.z+t.ACTION_HIT_PADDING
			check(safe.encloses(Rect2(Vector2(b.x,b.y)-Vector2.ONE*radius,Vector2.ONE*radius*2)),'full hit area remains inside safe bounds '+key+' '+str(dims))
		var at=t.buttons.attack;var cast=t.buttons.cast;var dodge=t.buttons.dodge
		check(Vector2(at.x,at.y).distance_to(Vector2(cast.x,cast.y))-(at.z+cast.z+2*t.ACTION_HIT_PADDING)>=7.9,'horizontal hit areas have a genuine gap '+str(dims))
		check(Vector2(at.x,at.y).distance_to(Vector2(dodge.x,dodge.y))-(at.z+dodge.z+2*t.ACTION_HIT_PADDING)>=7.9,'vertical hit areas have a genuine gap '+str(dims))
		game.combat.reset();press(1,t.origin+Vector2(32,0),true)
		press(2,Vector2(at.x,at.y),true);check(t.move_finger==1 and t.attack_held,'larger controls preserve independent fingers '+str(dims))
		press(2,Vector2(at.x,at.y),false);check(t.move_finger==1 and not t.attack_held,'action release preserves movement '+str(dims));t.release_all()
		press(3,(Vector2(at.x,at.y)+Vector2(cast.x,cast.y))/2,true)
		check(t.action_fingers.is_empty(),'gap does not select adjacent action '+str(dims));t.release_all()
	game.state.learned=['cordao','fratura','contrapeso']
	for reduced in [false,true]:
		game.preferences.reduced_motion=reduced
		for technique in game.state.learned:
			game.combat.reset();game.state.technique=technique;game.state.focus=100
			game.combat.cast();var effects=game.combat.effects
			check(effects.filter(func(fx):return fx.get('source','')==technique).size()==1,'one lifetime for all layers '+technique+' reduced='+str(reduced))
			var count=effects.size();game.world.foreground.queue_redraw();await settle()
			check(game.combat.effects.size()==count,'drawing creates no combat effects '+technique)
			if technique=='contrapeso':
				game.combat.dodge(Vector2.LEFT)
				check(game.combat.effects.filter(func(fx):return fx.get('source','')=='contrapeso').is_empty(),'dodge removes shell and all attached layers')
			game.combat.tick_effects(3)
			check(game.combat.effects.is_empty(),'all visual layers expire '+technique)
	print('POLISH 200 TESTS ',checks-failures.size(),'/',checks,' passed')
	game.sound.shutdown();await create_timer(.15).timeout;game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
