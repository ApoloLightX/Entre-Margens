extends SceneTree
var game
var checks=0
var failures=[]
const RUPTURE=preload('res://action/ice_rupture.gd')
const PILOT=preload('res://action/environment_pilot.gd')
func _initialize():call_deferred('run')
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label);printerr('FAIL ',label)
func settle():
	for i in range(3):await process_frame
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game);await settle()
	game.start_new('Verificação');game.set_physics_process(false)
	var c=game.combat;var s=game.state
	for n in [0,1,3]:
		for reduced in [false,true]:
			c.reset();s.position=Vector2(500,500);s.technique='fratura';s.focus=100
			game.preferences.reduced_motion=reduced
			for i in range(n):c.spawn('crawler',s.position+Vector2(90+i*45,0),'qa')
			var original=[]
			for e in c.enemies:original.append(e.pos)
			c.effects.clear();c.cast()
			var fx=c.effects.filter(func(f):return f.kind=='fratura')
			check(fx.size()==1,'one rupture at target count '+str(n))
			check(c.effects.filter(func(f):return f.kind=='impact').is_empty(),'no circular hit overlays for Fratura')
			check(fx[0].impact==(original[0] if n else s.position+Vector2(205,0)),'impact belongs to nearest hit before recoil')
			check(s.focus==100-game.catalog.combat.techniques.fratura.cost,'focus cost unchanged')
			for i in range(n):
				check(c.enemies[i].pos==original[i],'visual does not move hit position')
				check(c.enemies[i].hp==c.enemies[i].max_hp-game.catalog.combat.techniques.fratura.damage,'damage unchanged')
				check(c.enemies[i].recoil==Vector2(185,0),'recoil unchanged')
			var snapshot=c.effects.duplicate(true);var nodes=get_node_count()
			for phase in [.05,.3,.6,.95]:
				fx[0].life=fx[0].max*(1-phase);game.world.ground_effects.queue_redraw();await settle()
			check(c.effects.size()==snapshot.size(),'render has no effect accumulation')
			check(get_node_count()<=nodes+n,'render has no per-fragment nodes')
			c.spell_cd=0;s.focus=100;c.cast()
			check(c.effects.filter(func(f):return f.kind=='fratura').size()==1,'recast replaces previous rupture')
			c.hit_stop=.2;c.tick(.7,Vector2.ZERO)
			check(c.effects.filter(func(f):return f.kind=='fratura').is_empty(),'rupture expires through hitstop')
	c.reset();s.position=Vector2(500,500);s.focus=100;s.technique='fratura';c.facing=Vector2.RIGHT
	c.spawn('crawler',Vector2(600,500),'qa');c.spawn('crawler',Vector2(910,500),'qa');c.spawn('crawler',Vector2(600,555),'qa');c.cast()
	check(c.enemies[1].hp==c.enemies[1].max_hp and c.enemies[2].hp==c.enemies[2].max_hp,'mechanical corridor boundaries unchanged')
	seed(983);var expected=randi();seed(983);var g=RUPTURE.geometry(Vector2(80,120),Vector2.RIGHT)
	check(randi()==expected,'cosmetic geometry leaves global RNG untouched')
	check(g==RUPTURE.geometry(Vector2(80,120),Vector2.RIGHT),'repeatable geometry')
	check(g.cracks.size()==5 and g.shards.size()==6,'bounded geometry')
	check(RUPTURE.shard_position(g.shards[0],.2,false)!=RUPTURE.shard_position(g.shards[0],.7,false),'shards travel')
	check(RUPTURE.shard_position(g.shards[0],.2,true)==RUPTURE.shard_position(g.shards[0],.7,true),'reduced motion suppresses trajectories')
	check(game.world.ground_effects.z_index>game.world.terrain.z_index and game.world.ground_effects.z_index<0,'rupture below actors and world telegraphs')
	for room in range(6):
		s.room=room;game.load_room();game.close_modal();await settle()
		var region=PILOT.region(game.current_room().id)
		for prop in game.world.props:
			check(prop.polished==region.has_point(prop.position),'pilot confined to authored sample')
		check(region.has_area()==(room in [0,1]),'only Porto and Vereda have pilot')
		check(c.effects.is_empty(),'scene change clears rupture')
	game.fall();game.resolve_fall();await settle()
	check(s.health>0 and c.effects.is_empty(),'restart clears transient presentation')
	print('POLISH 210 TESTS ',checks-failures.size(),'/',checks,' passed')
	game.sound.shutdown();await create_timer(.15).timeout;game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
