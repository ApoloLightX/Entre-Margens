extends RefCounted
## Deterministic fixed-step combat; transient timers never enter saved state.
var game
var enemies:Array=[]
var projectiles:Array=[]
var effects:Array=[]
var triggered:Array=[]
var reinforced:Array=[]
var facing=Vector2.RIGHT
var attack_cd=0.0
var spell_cd=0.0
var dodge_cd=0.0
var dodge_time=0.0
var invulnerable=0.0
var hurt_time=0.0
var combo=0
var combo_time=0.0
var attack_flash=0.0
var boss_cycle=0
var boss_active=false
var damage_out=0.0
var spell_flash=0.0
var strike_wait=0.0
var strike_pending=false
var hit_stop=0.0
var shake=0.0
var spawn_serial=0
var walk_distance=0.0
func setup(g):game=g
func reset():
	enemies.clear();projectiles.clear();effects.clear();triggered.clear();reinforced.clear()
	attack_cd=0;spell_cd=0;dodge_cd=0;dodge_time=0;invulnerable=0;hurt_time=0;combo=0;combo_time=0;attack_flash=0;boss_active=false;boss_cycle=0
	spell_flash=0;strike_wait=0;strike_pending=false;hit_stop=0;shake=0;walk_distance=0
func spawn(kind:String,pos:Vector2,group_id:String):
	var spec=game.catalog.combat.enemies[kind]
	enemies.append({'kind':kind,'pos':pos,'hp':float(spec.health),'max_hp':float(spec.health),'spec':spec,'group':group_id,'state':'idle','timer':.3+enemies.size()*.18,'aim':Vector2.ZERO,'direction':Vector2.RIGHT,'flash':0.0,'stagger':0.0,'phase':0,'pattern':0})
	enemies[-1].recoil=Vector2.ZERO;enemies[-1].windup_duration=float(spec.windup)
	spawn_serial+=1;enemies[-1].visual_id=spawn_serial
func start_boss():
	if boss_active or 'regulador' in game.state.done:return
	boss_active=true;spawn('boss',Vector2(840,600),'regulador')
	game.toast('REGULADOR · observe o chão antes de atacar')
func soft_aim()->Vector2:
	var best=520.0;var direction=facing
	for e in enemies:
		var delta=e.pos-game.state.position;var distance=delta.length()
		if distance<best and (facing.dot(delta.normalized())>-.15 or distance<95):
			best=distance;direction=delta.normalized()
	return direction
func attack():
	if attack_cd>0 or dodge_time>0:return
	facing=soft_aim();combo=combo%3+1;combo_time=1.1
	attack_cd=.52 if combo==3 else .38;attack_flash=.34
	strike_wait=.08;strike_pending=true
	game.sound.effect('swing')
func resolve_player_strike():
	strike_pending=false
	var hits=0;var blocked_hits=0
	for e in enemies:
		var delta=e.pos-game.state.position
		if delta.length()<105 and facing.dot(delta.normalized())>-.05:
			var amount=(27.0 if combo==3 else 18.0)+game.state.upgrades*3
			var push=210.0 if combo==3 else 150.0
			if e.kind=='shield' and e.state!='recover' and e.stagger<=0 and e.direction.dot((game.state.position-e.pos).normalized())>.25:
				amount*=.3
				push=0;blocked_hits+=1
				effects.append({'kind':'text','pos':e.pos+Vector2(0,-65),'text':'ESCUDO','life':.65,'max':.65})
			damage(e,amount,combo==3,push);hits+=1
	game.state.focus=minf(100,game.state.focus+hits*7)
	effects.append({'kind':'slash','pos':game.state.position,'dir':facing,'life':.19,'max':.19,'strong':combo==3})
	if hits>0:
		game.sound.effect('block' if blocked_hits==hits else ('heavy' if combo==3 else 'hit'))
		if blocked_hits<hits:game.sound.effect('body',.35 if combo<3 else .55)
		hit_stop=.045 if combo==3 else .027
		shake=3.0 if combo==3 else 1.5
func cast():
	var s=game.catalog.combat.techniques[game.state.technique]
	if spell_cd>0 or dodge_time>0:return
	if game.state.focus<float(s.cost):game.toast('Foco baixo · acerte golpes ou recue por um instante.');return
	game.state.focus-=float(s.cost);spell_cd=float(s.cooldown);facing=soft_aim();spell_flash=.35
	var pos=game.state.position
	if game.state.technique=='cordao':
		for e in enemies:
			if pos.distance_to(e.pos)<155:damage(e,float(s.damage),true,145)
		projectiles=projectiles.filter(func(p):return p.pos.distance_to(pos)>205)
		invulnerable=maxf(invulnerable,.23)
		effects.append({'kind':'cordao','pos':pos,'radius':155.0,'life':.42,'max':.42})
	else:
		for e in enemies:
			var d=e.pos-pos;var forward=d.dot(facing)
			if forward>0 and forward<410 and absf(d.cross(facing))<55:damage(e,float(s.damage),true,185)
		effects.append({'kind':'beam','pos':pos,'dir':facing,'life':.35,'max':.35})
	game.sound.effect(game.state.technique,.72)
	game.sound.effect('dodge',.35)
func dodge(direction:Vector2):
	if dodge_cd>0:return
	if direction.length()>.1:facing=direction.normalized()
	dodge_cd=1.05;dodge_time=.25;invulnerable=.3
	strike_pending=false;strike_wait=0;attack_flash=0;spell_flash=0;hit_stop=0
	effects=effects.filter(func(fx):return fx.kind!='slash')
	effects.append({'kind':'dash','pos':game.state.position,'dir':facing,'life':.22,'max':.22})
	game.sound.effect('dodge')
func damage(e:Dictionary,amount:float,interrupt:bool,push=0.0):
	if e.kind=='boss' and e.state!='recover':
		amount*=.12
	e.hp-=amount;e.flash=.13;damage_out+=amount
	if push>0 and e.kind!='boss':
		var away=(e.pos-game.state.position).normalized()
		if away.is_zero_approx():away=facing
		e.recoil=away*push
	if interrupt and e.kind!='boss':e.state='recover';e.timer=1.1;e.stagger=1.1
	if interrupt and e.kind=='boss' and e.state=='recover':e.timer=maxf(e.timer,1.3)
	effects.append({'kind':'text','pos':e.pos+Vector2(0,-48),'text':str(int(amount)),'life':.65,'max':.65})
	effects.append({'kind':'spark','pos':e.pos+Vector2(0,-24),'dir':facing,'life':.24,'max':.24})
func hurt(amount:float):
	if invulnerable>0:return
	game.state.health-=amount*(.55 if game.state.assist else 1.0)
	invulnerable=.6;hurt_time=.24
	shake=5.0
	game.sound.effect('hurt')
	if game.state.health<=0:game.fall()
func tick(dt:float,direction:Vector2):
	shake=maxf(0,shake-dt*18)
	if hit_stop>0:
		hit_stop=maxf(0,hit_stop-dt)
		return
	attack_cd=maxf(0,attack_cd-dt);spell_cd=maxf(0,spell_cd-dt);dodge_cd=maxf(0,dodge_cd-dt)
	invulnerable=maxf(0,invulnerable-dt);hurt_time=maxf(0,hurt_time-dt);attack_flash=maxf(0,attack_flash-dt)
	spell_flash=maxf(0,spell_flash-dt)
	if strike_pending:
		strike_wait-=dt
		if strike_wait<=0:resolve_player_strike()
	combo_time-=dt
	if combo_time<=0:combo=0
	game.state.focus=minf(100,game.state.focus+dt*5)
	if dodge_time>0:
		dodge_time-=dt;game.move_player(facing*610*dt)
	elif direction.length()>.1:
		if attack_flash<=0:facing=direction.normalized()
		var before=game.state.position
		game.move_player(direction.limit_length()*190*dt*(.45 if attack_flash>0 else 1.0))
		walk_distance+=before.distance_to(game.state.position)
		if walk_distance>=42:
			walk_distance=0;game.sound.footstep(game.current_room().floor)
	for group in game.current_room().groups:
		if group.id in triggered or group.id in game.state.cleared:continue
		if game.state.position.distance_to(Vector2(group.x,group.y))<330:
			triggered.append(group.id)
			for i in range(group.kinds.size()):
				var offset=Vector2.from_angle(i*TAU/group.kinds.size())*70
				spawn(group.kinds[i],Vector2(group.x,group.y)+offset,group.id)
	for e in enemies:
		if e.hp<=0:continue
		var recoiling=e.recoil.length()>15
		if recoiling:
			e.pos=game.safe_move(e.pos,e.recoil*dt,20)
		e.recoil=e.recoil.move_toward(Vector2.ZERO,1000*dt)
		e.flash=maxf(0,e.flash-dt);e.stagger=maxf(0,e.stagger-dt);e.timer-=dt
		var delta=game.state.position-e.pos;var dist=delta.length()
		if e.kind=='boss':
			var phase=mini(2,int((1-e.hp/e.max_hp)*3))
			if phase>e.phase:
				e.phase=phase;e.state='recover';e.timer=2.4
				game.toast('ARO '+str(phase)+' ROMPIDO · aproveite a abertura!')
				game.sound.effect('heavy');shake=5
				projectiles.clear();game.state.focus=minf(100,game.state.focus+35)
		if e.state=='idle':
			if e.kind=='ranged' and dist<160 and not recoiling:
				e.pos=game.safe_move(e.pos,-delta.normalized()*78*dt,20)
			if dist>e.spec.reach*.8 and e.kind!='boss' and not recoiling:
				var push=Vector2.ZERO
				for other in enemies:
					if other==e:continue
					var separation=e.pos-other.pos
					if separation.length()<42:push+=separation.normalized()*55
				e.pos=game.safe_move(e.pos,(delta.normalized()*float(e.spec.speed)+push)*dt,20)
			if dist<float(e.spec.reach) and e.timer<=0:
				e.state='windup';e.timer=float(e.spec.windup);e.aim=game.state.position;e.direction=delta.normalized()
				if dist<420:game.sound.effect('windup',.24)
				if e.kind=='boss':e.pattern=boss_cycle%3;boss_cycle+=1;e.timer=1.5-e.phase*.12
				e.windup_duration=e.timer
		elif e.state=='windup' and e.timer<=0:
			resolve_attack(e);e.state='recover';e.timer=float(e.spec.recovery)
		elif e.state=='recover' and e.timer<=0:e.state='idle';e.timer=.15
	for p in projectiles:
		var start:Vector2=p.pos;p.pos+=p.velocity*dt;p.life-=dt
		var nearest=Geometry2D.get_closest_point_to_segment(game.state.position,start,p.pos)
		if nearest.distance_to(game.state.position)<23:
			hurt(p.damage);p.life=0
		elif not game.walkable(p.pos,5):p.life=0
	projectiles=projectiles.filter(func(p):return p.life>0)
	var dead=enemies.filter(func(e):return e.hp<=0)
	for e in dead:
		game.sound.effect('break')
		game.state.kills+=1;game.state.parts+=3 if e.kind=='shield' else 2
		effects.append({'kind':'burst','pos':e.pos,'life':.6,'max':.6})
		if e.kind=='boss':
			game.state.done.append('regulador');boss_active=false;projectiles.clear()
			game.toast('O regulador cessa. Alcance a Trama ao norte.');game.save_progress()
	enemies=enemies.filter(func(e):return e.hp>0)
	for id in triggered:
		if id in game.state.cleared:continue
		if enemies.filter(func(e):return e.group==id).is_empty():
			var group={}
			for candidate in game.current_room().groups:
				if candidate.id==id:group=candidate;break
			if group.has('reinforcements') and not id in reinforced:
				reinforced.append(id)
				for i in range(group.reinforcements.size()):
					spawn(group.reinforcements[i],Vector2(group.x,group.y)+Vector2.from_angle(i*TAU/group.reinforcements.size())*175,id)
				game.toast('Outro circuito despertou · reforços nas margens!')
			else:
				game.state.cleared.append(id);game.save_progress()
	for fx in effects:fx.life-=dt
	effects=effects.filter(func(fx):return fx.life>0)
func resolve_attack(e:Dictionary):
	if game.state.position.distance_to(e.pos)<500:game.sound.effect('enemy',.4)
	if e.kind=='ranged':
		projectile(e.pos,e.direction*260,e.spec.damage)
	elif e.kind=='boss':
		if e.pattern==0:
			var v=game.state.position-e.pos
			if v.dot(e.direction)>-25 and v.dot(e.direction)<1100 and absf(v.cross(e.direction))<53:hurt(e.spec.damage)
			effects.append({'kind':'enemy_beam','pos':e.pos,'dir':e.direction,'life':.4,'max':.4})
		elif e.pattern==1:
			if game.state.position.distance_to(e.aim)<155:hurt(e.spec.damage+5)
			effects.append({'kind':'danger','pos':e.aim,'radius':155.0,'life':.6,'max':.6})
		else:
			for direction in fan_directions(e):projectile(e.pos,direction*230,e.spec.damage)
	else:
		if game.state.position.distance_to(e.pos)<float(e.spec.reach)+12:hurt(e.spec.damage)
		effects.append({'kind':'danger','pos':e.pos,'radius':float(e.spec.reach)+12,'life':.25,'max':.25})
func fan_directions(e:Dictionary)->Array:
	var rays=[]
	for i in range(9+e.phase*2):rays.append(Vector2.from_angle(e.direction.angle()+(i-(4+e.phase))*.20))
	return rays
func projectile(pos:Vector2,velocity:Vector2,amount:float):
	projectiles.append({'pos':pos,'velocity':velocity,'damage':amount,'life':5.0})
