extends SceneTree
## Behavioral checks for impact, cancellation, warnings and mobile feedback.
## Run with an isolated XDG_DATA_HOME; setup writes a temporary campaign save.
var game
var count=0
var failures=[]
func _initialize():call_deferred('run')
func check(ok:bool,label:String):
	count+=1
	if not ok:failures.append(label);printerr('FAIL ',label)
func fresh():
	game.combat.reset();game.state.position=Vector2(760,700)
	game.state.health=120;game.state.focus=100;game.state.assist=false;game.pending_fall=false
func touch_event(index:int,p:Vector2,pressed:bool):
	var event=InputEventScreenTouch.new();event.index=index;event.position=p;event.pressed=pressed;game.touch._input(event)
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame;game.set_physics_process(false);game.start_new('Verificação');game.set_physics_process(false)
	game.state.muted=true
	for room in game.catalog.rooms:
		for group in room.groups:game.state.cleared.append(group.id)
	var c=game.combat;var s=game.state
	fresh();c.spawn('crawler',s.position+Vector2(65,0),'check');var e=c.enemies[0];var hp=e.hp
	c.attack();c.tick(.02,Vector2.ZERO);c.dodge(Vector2.LEFT);c.tick(.12,Vector2.ZERO)
	check(e.hp==hp,'dodge cancels the pending contact without dealing damage')
	check(c.attack_flash==0 and not c.strike_pending,'dodge removes the attack pose and pending strike')
	check(s.position.x<760,'cancelled attack does not block dodge movement')
	fresh();c.spawn('crawler',s.position+Vector2(65,0),'check');c.attack();c.tick(.081,Vector2.ZERO)
	check(c.hit_stop>0,'landed hit starts a brief impact pause')
	var at=s.position;c.dodge(Vector2.LEFT);c.tick(1.0/60,Vector2.ZERO)
	check(s.position.x<at.x and c.hit_stop==0,'dodge moves on the next tick during impact pause')
	check(c.effects.filter(func(fx):return fx.kind=='slash').is_empty(),'cancelled slash does not linger through dodge')
	hp=s.health;c.hurt(30);check(s.health==hp,'cancelled dodge retains invulnerability')
	fresh();c.spawn('crawler',s.position+Vector2(65,0),'check');e=c.enemies[0];at=e.pos
	c.damage(e,1,true,150)
	for i in range(12):c.tick(1.0/60,Vector2.ZERO)
	check(e.pos.x>at.x+5 and e.pos.x<at.x+30,'light knockback separates the target without throwing it across the arena')
	fresh();s.position=Vector2(130,700);c.spawn('crawler',Vector2(61,700),'check');e=c.enemies[0];c.damage(e,1,true,210)
	for i in range(18):c.tick(1.0/60,Vector2.ZERO)
	check(e.pos.x>=60 and game.walkable(e.pos,20),'knockback cannot cross the room boundary')
	var obstacle={}
	for prop in game.current_room().props:
		if prop.solid:obstacle=prop;break
	fresh();var edge=float(obstacle.x)+float(obstacle.size)*.24+20
	s.position=Vector2(edge+80,obstacle.y);c.spawn('crawler',Vector2(edge+2,obstacle.y),'check');e=c.enemies[0];c.damage(e,1,true,210)
	for i in range(18):c.tick(1.0/60,Vector2.ZERO)
	check(e.pos.x>=edge and game.walkable(e.pos,20),'knockback stops at a solid prop footprint')
	fresh();c.spawn('shield',s.position+Vector2(65,0),'check');e=c.enemies[0];e.direction=Vector2.LEFT;c.facing=Vector2.RIGHT;c.attack();c.tick(.081,Vector2.ZERO)
	check(e.recoil.is_zero_approx(),'front-facing shield resists ordinary knockback')
	fresh()
	for i in range(3):c.spawn('shield',s.position+Vector2(65,0),'stack')
	for shield in c.enemies:shield.direction=Vector2.LEFT
	c.facing=Vector2.RIGHT;c.attack();c.tick(.081,Vector2.ZERO)
	var statuses=c.effects.filter(func(fx):return fx.kind=='status' and fx.get('status','')=='shield')
	check(statuses.size()==3,'three nearby shields use one compact status marker per enemy')
	var status_positions=statuses.map(func(fx):return fx.pos)
	check(status_positions.duplicate().size()==3 and status_positions[0]!=status_positions[1] and status_positions[1]!=status_positions[2],'nearby shield markers are offset instead of stacked')
	check(c.effects.filter(func(fx):return fx.kind=='text' and fx.text=='ESCUDO').is_empty(),'shield feedback no longer duplicates status text')
	var numbers=c.effects.filter(func(fx):return fx.kind=='text' and fx.text.is_valid_int())
	check(numbers.size()==3 and numbers[0].pos!=numbers[1].pos and numbers[1].pos!=numbers[2].pos,'simultaneous damage numbers use separate lanes')
	game.world._process(0)
	check(game.world.player.z_index>game.world.foreground.z_index,'player keeps visual priority while combat effects and enemies are active')
	fresh();s.technique='fratura';s.learned=['cordao','fratura'];c.spawn('crawler',s.position+Vector2(90,0),'stack');c.spawn('crawler',s.position+Vector2(115,16),'stack');c.spawn('crawler',s.position+Vector2(140,-16),'stack')
	c.effects.append({'kind':'ring','pos':s.position,'radius':140.0,'life':.4,'max':.4})
	c.effects.append({'kind':'beam','source':'fratura','pos':s.position,'dir':Vector2.RIGHT,'life':.2,'max':.2})
	c.facing=Vector2.RIGHT;c.cast()
	check(c.effects.filter(func(fx):return fx.kind=='ring').is_empty(),'Fratura removes deprecated ring instances before presenting')
	check(c.effects.filter(func(fx):return fx.kind=='fratura' and fx.get('source','')=='fratura').size()==1,'Fratura keeps a single ice-crack presentation even against three enemies')
	c.spell_cd=0;s.focus=100;c.cast()
	check(c.effects.filter(func(fx):return fx.kind=='fratura' and fx.get('source','')=='fratura').size()==1,'recasting Fratura replaces its previous presentation instead of stacking it')
	fresh();s.learned=['cordao','fratura','contrapeso']
	for i in range(3):c.spawn('shield',s.position+Vector2(85+i*34,(i-1)*24),'ice_sequence')
	s.technique='cordao';s.focus=100;c.cast();check(c.effects.filter(func(fx):return fx.kind=='cordao' and fx.get('source','')=='cordao').size()==1,'Cordon uses one dedicated crystalline perimeter with three enemies present')
	c.spell_cd=0;s.focus=100;s.technique='fratura';c.facing=Vector2.RIGHT;c.cast();check(c.effects.filter(func(fx):return fx.kind=='fratura' and fx.get('source','')=='fratura').size()==1,'Fracture uses one dedicated crack effect in the same crowded fight')
	c.spell_cd=0;s.focus=100;s.technique='contrapeso';c.cast();check(c.effects.filter(func(fx):return fx.kind=='contrapeso' and fx.get('source','')=='contrapeso').size()==1,'Counterweight uses one body shell instead of a shared expanding ring')
	var technique_kinds=c.effects.filter(func(fx):return fx.get('source','') in ['cordao','fratura','contrapeso']).map(func(fx):return fx.kind)
	check('cordao' in technique_kinds and 'fratura' in technique_kinds and 'contrapeso' in technique_kinds,'all three techniques remain visually distinct by effect kind under crowd load')
	fresh();c.effects.append({'kind':'text','pos':s.position,'text':'1','life':.01,'max':.01});c.hit_stop=.05;c.tick(.02,Vector2.ZERO)
	check(c.effects.is_empty(),'transient combat effects still expire during hitstop')
	fresh();s.learned=['cordao','fratura','contrapeso'];s.technique='contrapeso';c.cast();c.dodge(Vector2.LEFT)
	check(c.guard_time==0 and not c.guard_ready,'dodge responsiveness is preserved when cancelling Counterweight')
	check(c.effects.filter(func(fx):return fx.get('source','')=='contrapeso').is_empty(),'cancelled Counterweight presentation does not linger')
	fresh();c.spawn('boss',s.position+Vector2(65,0),'check');e=c.enemies[0];at=e.pos;c.damage(e,10,true,210);c.tick(.05,Vector2.ZERO)
	check(e.pos==at,'Regulator stays anchored when struck')
	for kind in ['crawler','shield','ranged']:
		fresh();c.spawn(kind,s.position+Vector2(40,0),'check');e=c.enemies[0];e.timer=0;hp=s.health;c.tick(.001,Vector2.ZERO)
		check(e.state=='windup' and e.timer>=.6,'advance warning for '+kind)
		var early_damage=false;var time=0.0
		while e.state=='windup' and time<3:
			if e.timer>1.0/60 and s.health!=hp:early_damage=true
			c.tick(1.0/60,Vector2.ZERO);time+=1.0/60
		check(not early_damage and time>=.6,'no damage before warning completes for '+kind)
		check(e.state=='recover','attack ends with a recovery window for '+kind)
	s.room=5;game.load_room();game.close_modal()
	for phase in range(3):
		for pattern in range(3):
			fresh();s.position=Vector2(680,750);c.spawn('boss',Vector2(840,600),'check');e=c.enemies[0]
			e.phase=phase;e.hp=e.max_hp*(1-(phase+.05)/3.0);e.timer=0;c.boss_cycle=pattern;hp=s.health;c.tick(.001,Vector2.ZERO)
			check(e.state=='windup' and e.timer>=1.25,'boss warning phase '+str(phase+1)+' pattern '+str(pattern))
			var aim=e.direction;var target=e.aim;s.position+=Vector2(-70,0)
			var time=0.0;var early_damage=false
			while e.state=='windup' and time<3:
				if e.timer>1.0/60 and s.health!=hp:early_damage=true
				c.tick(1.0/60,Vector2.ZERO);time+=1.0/60
			check(not early_damage and time>=1.25 and e.direction==aim and e.aim==target,'boss retains its warned target until release '+str(phase)+'/'+str(pattern))
			if pattern==2:
				var rays=c.fan_directions(e);var aligned=c.projectiles.size()==rays.size()
				for shot in c.projectiles:
					var matches=false
					for ray in rays:matches=matches or shot.velocity.normalized().is_equal_approx(ray)
					aligned=aligned and matches
				check(aligned,'all actual fan shots follow displayed rays in phase '+str(phase+1))
	s.room=0;game.load_room();game.close_modal();fresh()
	var t=game.touch;var b=t.buttons.attack;var attack_pos=Vector2(b.x,b.y)
	touch_event(1,t.origin+Vector2(32,0),true);touch_event(2,attack_pos,true)
	var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.pressed=false;t._input(mouse)
	check(t.attack_held and t.move_finger==1 and t.direction.x>0,'synthetic mouse release preserves independent held touch controls')
	touch_event(2,attack_pos,false)
	check(t.press_flash.attack>0 and not t.attack_held,'short tap keeps visible feedback after finger release')
	check(t.move_finger==1 and t.direction.x>0,'releasing attack does not stop movement')
	c.spell_cd=1;b=t.buttons.cast;touch_event(3,Vector2(b.x,b.y),true)
	check(t.press_flash.cast>0 and c.spell_flash==0,'technique touch responds immediately even during cooldown')
	t.release_all()
	for object in game.current_room().objects:
		if object.get('npc',false):s.position=Vector2(object.x,object.y);break
	game.hud.update_status();check(game.hud.context.visible,'interaction appears beside a resident')
	c.spawn('crawler',s.position+Vector2(100,0),'check');game.hud.update_status()
	check(not game.hud.context.visible,'blocked interaction is hidden during nearby combat')
	game.session_active=true;s.elapsed=123;game.hud.settings_menu();game._physics_process(.5)
	check(s.elapsed==123,'time spent adjusting presentation does not inflate campaign duration')
	game.close_modal();fresh();s.muted=false;game.preferences.effects_volume=.85;game.sound.apply_volumes()
	for voice in game.sound.players:voice.stop()
	game.sound.effect('hit');game.sound.effect('hit')
	check(game.sound.players[0].stream!=game.sound.players[1].stream,'successive impacts use different recordings')
	for voice in game.sound.players:voice.stop()
	for i in range(game.sound.players.size()):game.sound.effect('snow')
	check(game.sound.players.all(func(voice):return voice.playing),'sound saturation scenario fills the voice pool')
	game.sound.effect('hurt');var hurt_voices=game.sound.players.filter(func(voice):return voice.get_meta('sound','')=='hurt')
	check(hurt_voices.size()==1 and hurt_voices[0].playing,'damage sound replaces a footstep when all voices are busy')
	game.sound.effect('ui');check(hurt_voices[0].get_meta('sound')=='hurt','low-priority interface sound cannot cut off damage feedback')
	game.sound.shutdown();await create_timer(.15).timeout
	print('POLISH TESTS ',count-failures.size(),'/',count,' passed')
	game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
