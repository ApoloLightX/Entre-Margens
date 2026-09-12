extends SceneTree
## Regression for the active Android action UI: touch controls and modal actions stay reachable.
var checks=0
var failures=0
var game
func check(value:bool,message:String)->void:
	checks+=1
	if value:print('PASS: '+message)
	else:failures+=1;printerr('FAIL: '+message)
func settle()->void:
	for n in range(3):await process_frame
func check_touch_matches_anchors(label:String)->void:
	var expected_origin=game.hud.joystick_anchor.get_global_rect().get_center()
	check(game.touch.origin.distance_to(expected_origin)<.05,'joystick follows HUD anchor '+label)
	var anchors={'attack':game.hud.attack_anchor,'cast':game.hud.cast_anchor,'dodge':game.hud.dodge_anchor}
	for action in anchors:
		var expected=anchors[action].get_global_rect().get_center()
		var actual=game.touch.buttons[action]
		check(Vector2(actual.x,actual.y).distance_to(expected)<.05,'touch '+action+' follows HUD anchor '+label)
func check_gameplay_core_clear(label:String)->void:
	var core=game.hud.gameplay_core_rect()
	var persistent=[game.hud.status_block.get_global_rect(),game.hud.heal_button.get_global_rect(),game.hud.top_action_bar.get_global_rect(),game.hud.context_box.get_global_rect(),game.hud.joystick_anchor.get_global_rect(),game.hud.action_grid.get_global_rect()]
	for rect in persistent:check(not rect.intersects(core),'persistent HUD stays outside Gameplay Core '+label)
func _initialize()->void:call_deferred('run')
func run()->void:
	check(int(ProjectSettings.get_setting('display/window/handheld/orientation',-1))==0,'Android orientation remains landscape-only')
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await settle();game.set_physics_process(false);game.start_new('Tela');game.set_physics_process(false)
	# Landscape-only targets: 16:9, 19.5:9 and 20:9.
	for dims in [Vector2i(960,540),Vector2i(1170,540),Vector2i(1200,540)]:
		root.size=dims;await settle();game.hud.layout_controls();await settle();check_touch_matches_anchors(str(dims));check_gameplay_core_clear(str(dims))
		var safe=game.preferences.safe_rect(root)
		for key in game.touch.buttons:
			var b=game.touch.buttons[key];var circle=Rect2(Vector2(b.x-b.z,b.y-b.z),Vector2.ONE*b.z*2)
			check(safe.encloses(circle),'touch '+key+' stays in safe area '+str(dims))
		for button in game.hud.top_buttons:check(safe.encloses(button.get_global_rect()),'top action stays in safe area '+str(dims))
		check(safe.encloses(game.hud.context_box.get_global_rect()),'interaction dock stays in safe area '+str(dims))
		check(game.hud.context_box.get_global_rect().end.y<=safe.end.y,'interaction dock remains bottom anchored '+str(dims))
		for page in ['new_game','help_menu','settings_menu','pause_menu']:
			game.hud.call(page);await settle()
			check(safe.encloses(game.hud.panel.get_global_rect()),'modal panel fits '+page+' '+str(dims))
			check(safe.encloses(game.hud.footer.get_global_rect()),'fixed modal actions fit '+page+' '+str(dims))
		game.close_modal()
	# Rapid aspect changes must converge without touch.gd owning a resize callback.
	for dims in [Vector2i(960,540),Vector2i(1200,540),Vector2i(540,960),Vector2i(1170,540),Vector2i(960,540)]:
		root.size=dims;await settle();check_touch_matches_anchors('dynamic '+str(dims));check_gameplay_core_clear('dynamic '+str(dims))
	root.size=Vector2i(960,540);await settle();game.close_modal()
	var origin=game.touch.origin
	var move=InputEventScreenTouch.new();move.index=1;move.position=origin+Vector2(35,0);move.pressed=true;game.touch._input(move)
	var attack=game.touch.buttons.attack;var press=InputEventScreenTouch.new();press.index=2;press.position=Vector2(attack.x,attack.y);press.pressed=true;game.touch._input(press)
	check(game.touch.move_finger==1 and game.touch.attack_held,'movement and attack retain independent touch ownership')
	var release=InputEventScreenTouch.new();release.index=2;release.position=press.position;release.pressed=false;game.touch._input(release)
	check(game.touch.move_finger==1 and not game.touch.attack_held,'releasing action does not release movement')
	game.touch.release_all()
	print('RESULT: %d MOBILE UI checks, %d failures' % [checks,failures])
	game.queue_free();await process_frame;quit(1 if failures else 0)
