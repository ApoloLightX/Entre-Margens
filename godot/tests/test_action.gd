extends SceneTree
var game
var count=0
var failures:Array=[]
func check(condition:bool,message:String):
	count+=1
	if not condition:failures.append(message);printerr('FAIL ',message)
func _initialize():call_deferred('run')
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start_new('Teste');game.set_physics_process(false)
	var c=game.combat;var state=game.state;var catalog=game.catalog
	check(catalog.rooms.size()==6,'six authored rooms')
	var ids=[];var groups=0;var waves=0
	for ri in range(catalog.rooms.size()):
		state.room=ri;game.load_room()
		var r=game.current_room()
		check(game.walkable(state.position,19),'room spawn traversable '+r.id)
		for o in r.objects:
			check(not o.id in ids,'unique object '+o.id);ids.append(o.id)
			var accessible=false
			for j in range(16):
				var pos=Vector2(o.x,o.y)+Vector2.from_angle(j*TAU/16)*78
				if game.walkable(pos,19):accessible=true
			check(accessible,'interactable reachable '+o.id)
			if o.kind=='puzzle':check(o.solution>=0 and o.solution<o.options.size(),'valid puzzle '+o.id)
		for id in r.required:check(id in ids or not catalog.object_by_id(id).is_empty() or id=='regulador','valid objective '+id)
		groups+=r.groups.size()
		for g in r.groups:
			waves+=1+(1 if g.has('reinforcements') else 0)
			for kind in g.kinds:check(catalog.combat.enemies.has(kind),'known enemy '+kind)
	check(groups==16 and waves==24,'16 encounters / 24 waves')
	var circuit=load('res://action/circuit.gd')
	check(circuit.connected(circuit.SOLVED),'circuit solved route is valid')
	for seed_value in range(3):check(not circuit.connected(circuit.initial(seed_value)),'circuit starts unsolved')
	var pipe=3
	for i in range(4):pipe=circuit.rotate(pipe)
	check(pipe==3,'four rotations restore pipe')
	var broken=circuit.SOLVED.duplicate();broken[2]=3
	check(not circuit.connected(broken),'circuit rejects broken route')
	state.room=0;game.load_room();state.position=Vector2(760,700);c.reset()
	c.facing=Vector2.LEFT;c.spawn('crawler',state.position+Vector2(-65,0),'test');var enemy=c.enemies[0];var hp=enemy.hp
	c.attack();check(enemy.hp==hp,'melee anticipation precedes contact');c.tick(.081,Vector2.ZERO);check(enemy.hp<hp,'melee follows facing left')
	var after=enemy.hp;c.attack();check(enemy.hp==after,'melee cooldown stops duplicate input')
	c.reset();c.spawn('shield',state.position+Vector2(65,0),'test');enemy=c.enemies[0];enemy.direction=Vector2.LEFT;c.facing=Vector2.RIGHT
	c.attack();c.tick(.081,Vector2.ZERO);check(enemy.hp>enemy.max_hp-10,'front shield blocks')
	c.attack_cd=0;c.hit_stop=0;enemy.direction=Vector2.RIGHT;hp=enemy.hp;c.attack();c.tick(.081,Vector2.ZERO);check(hp-enemy.hp>=18,'flanking bypasses shield')
	state.focus=100;state.technique='fratura';c.spell_cd=0;c.cast();check(enemy.state=='recover','fracture breaks posture')
	check(state.focus==68,'spell consumes external configured focus')
	c.reset();state.technique='fratura';state.focus=100;c.facing=Vector2.RIGHT
	c.spawn('crawler',state.position+Vector2(210,0),'line');c.spawn('crawler',state.position+Vector2(0,210),'off_line')
	c.cast();check(c.enemies[0].hp<c.enemies[0].max_hp and c.enemies[1].hp==c.enemies[1].max_hp,'fracture line differs from radius')
	c.reset();state.technique='cordao';state.focus=100;c.projectile(state.position+Vector2(90,0),Vector2.LEFT*250,10);c.cast();check(c.projectiles.is_empty(),'cordon removes nearby projectile')
	c.reset();state.learned=['cordao','fratura','contrapeso'];state.technique='contrapeso';state.focus=100;state.health=state.max_health();hp=state.health
	c.cast();check(c.guard_ready and c.guard_time>0,'counterweight opens a short one-hit guard window')
	check(state.focus==76,'counterweight consumes configured focus')
	var braced_position=state.position;c.tick(.10,Vector2.RIGHT);check(state.position==braced_position,'counterweight stance holds position during its active window')
	c.hurt(30);check(state.health==hp and not c.guard_ready and c.guard_time==0,'timed counterweight absorbs exactly one impact')
	check(state.focus>90 and state.focus<91 and not c.effects.filter(func(fx):return fx.kind=='contrapeso_break').is_empty(),'successful counterweight returns focus and shows compact feedback')
	c.invulnerable=0;c.hurt(10);check(state.health<hp,'counterweight cannot absorb a second impact')
	c.reset();state.technique='contrapeso';state.focus=100;state.health=state.max_health();hp=state.health;c.cast();c.tick(.60,Vector2.ZERO);c.invulnerable=0;c.hurt(10)
	check(state.health<hp and not c.guard_ready,'expired counterweight does not become passive invulnerability')
	c.reset();state.technique='contrapeso';state.focus=100;c.cast();c.dodge(Vector2.LEFT)
	check(c.guard_time==0 and not c.guard_ready and c.effects.filter(func(fx):return fx.get('source','')=='contrapeso').is_empty(),'dodge cancels counterweight cleanly')
	state.learned=['cordao','fratura','contrapeso'];state.technique='cordao';game.switch_technique();check(state.technique=='fratura','technique cycle reaches fracture')
	game.switch_technique();check(state.technique=='contrapeso','technique cycle reaches counterweight')
	game.switch_technique();check(state.technique=='cordao','technique cycle wraps to cordon')
	var dena_lesson=catalog.object_by_id('soleira_dena');check(dena_lesson.get('technique','')=='contrapeso','counterweight is learned from an existing authored stop without adding an encounter')
	c.reset();state.health=state.max_health();hp=state.health;c.dodge(Vector2.LEFT);c.hurt(30);check(state.health==hp,'dodge invulnerability')
	c.invulnerable=0;state.assist=true;c.hurt(20);check(is_equal_approx(state.health,hp-11),'accessible combat reduces damage')
	c.reset();state.assist=false;state.health=state.max_health();hp=state.health;c.projectile(state.position-Vector2(100,0),Vector2(12000,0),12);c.tick(1.0/60,Vector2.ZERO)
	check(state.health<hp,'swept projectile collision catches fast projectiles')
	c.reset();var old=state.position;game.move_player(Vector2(-9000,0));check(state.position.x>=59,'dash substeps respect world bounds')
	state.room=1;game.load_room();state.position=Vector2(930,450);c.tick(.01,Vector2.ZERO)
	check('v2' in c.triggered,'proximity activates encounter')
	for e in c.enemies:e.hp=0
	c.tick(.01,Vector2.ZERO);check('v2' in c.reinforced and not 'v2' in state.cleared,'reinforcement precedes completion')
	for e in c.enemies:e.hp=0
	c.tick(.01,Vector2.ZERO);check('v2' in state.cleared,'second wave completes encounter')
	state.room=0;game.load_room();state.evidence=['lior'];state.anchors=[];state.anchor_records={};state.anomaly=false;game.anchor('lior');var anchored=state.anchor_records.lior
	state.anomaly=true;game.hud.diary();check(state.anchor_records.lior==anchored,'anchored snapshot survives anomaly')
	game.anchor('lior');game.anchor('lior');check(state.anchor_records.lior!=anchored,'late reanchor cannot recover erased text')
	state.learned=['cordao','fratura','contrapeso'];state.technique='contrapeso';state.started=true
	check(game.saves.write(state),'atomic save writes')
	var recovered=load('res://action/state.gd').new();check(game.saves.load_into(recovered),'save loads')
	check(recovered.anchor_records.lior==state.anchor_records.lior and recovered.technique=='contrapeso','save preserves anchors and new technique')
	var corrupt=state.pack();corrupt.room=90;check(not game.saves.valid(corrupt),'reject out of range room')
	corrupt=state.pack();corrupt.anchor_records=[];check(not game.saves.valid(corrupt),'reject wrong dictionary type')
	check(game.saves.write(state),'second atomic save creates backup')
	var f=FileAccess.open(game.saves.PATH,FileAccess.WRITE);f.store_string('truncated');f.close()
	check(game.saves.load_into(recovered),'corrupt main save falls back to backup')
	state.room=5;game.load_room();c.start_boss();check(c.enemies.size()==1 and c.boss_active,'boss starts once')
	c.start_boss();check(c.enemies.size()==1,'boss cannot duplicate')
	var boss=c.enemies[0];var before=boss.hp;c.damage(boss,100,false);check(is_equal_approx(before-boss.hp,12),'boss armor closes outside recovery');boss.state='recover';before=boss.hp;c.damage(boss,100,false);check(is_equal_approx(before-boss.hp,100),'boss recovery opens damage window');boss.hp=700;c.tick(.01,Vector2.ZERO);check(boss.phase==1,'boss second phase')
	boss.hp=300;c.tick(.01,Vector2.ZERO);check(boss.phase==2,'boss third phase')
	boss.hp=0;c.tick(.01,Vector2.ZERO);check('regulador' in state.done and not c.boss_active,'boss defeat opens choice')
	game.finish('isolar');check(state.ending=='isolar' and 'final_choice' in state.done,'isolation ending completes')
	game.finish('contorno');check(state.ending=='contorno','maintenance ending completes')
	state.room=0;state.ending='';game.load_room();game.close_modal()
	var touch=game.touch
	var press=InputEventScreenTouch.new();press.index=4;press.position=touch.origin+Vector2(31,0);press.pressed=true;touch._input(press)
	check(touch.direction.x>.3,'touch movement')
	press=InputEventScreenTouch.new();press.index=5;press.position=Vector2(touch.buttons.attack.x,touch.buttons.attack.y);press.pressed=true;touch._input(press)
	check(touch.attack_held and touch.move_finger==4,'touch movement and attack simultaneous')
	press.pressed=false;touch._input(press);check(not touch.attack_held and touch.direction.x>.3,'releasing attack preserves movement')
	game.hud.pause_menu();check(touch.direction==Vector2.ZERO,'modal releases held controls')
	# Layout checks run with the real Godot text/layout engine, even in headless mode.
	for screen in ['title','diary','map_menu','pause_menu','help_menu','epilogue']:
		game.hud.call(screen)
		await process_frame
		await process_frame
		check(game.hud.panel.get_global_rect().end.y<=game.preferences.safe_rect(root).end.y,'modal footer inside viewport '+screen)
		check(game.hud.footer.get_global_rect().end.y<=game.preferences.safe_rect(root).end.y,'footer visible '+screen)
	game.hud.circuit(catalog.object_by_id('galeria_a'))
	await process_frame;await process_frame
	check(game.hud.panel.get_global_rect().end.y<=game.preferences.safe_rect(root).end.y,'circuit layout fits viewport')
	game.hud.new_game();await process_frame;await process_frame
	check(game.hud.panel.get_global_rect().end.y<=game.preferences.safe_rect(root).end.y,'name entry layout fits viewport')
	print('ACTION TESTS ',count-failures.size(),'/',count,' passed')
	for message in failures:print('FAILED: ',message)
	game.sound.shutdown();await create_timer(.15).timeout
	game.queue_free();await process_frame
	quit(0 if failures.is_empty() else 1)
