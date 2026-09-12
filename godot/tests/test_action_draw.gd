extends SceneTree
var game
var draws=[0]
func _initialize():call_deferred('run')
func run():
	game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
	await process_frame
	game.set_physics_process(false);game.state.reset();game.state.started=true;game.close_modal()
	game.world.draw.connect(func():draws[0]+=1)
	for room in range(6):
		game.state.room=room;game.load_room();game.close_modal();game.state.position=Vector2(800,650);game.camera.position=game.state.position
		game.camera.reset_smoothing();game.state.anomaly=room>=3
		for kind in ['crawler','ranged','shield','boss']:
			game.combat.spawn(kind,Vector2(650+game.combat.enemies.size()*100,620),'draw')
		for e in game.combat.enemies:e.state='windup';e.aim=game.state.position;e.direction=Vector2.DOWN
		for pattern in range(3):
			game.combat.enemies[3].pattern=pattern
			game.combat.effects=[{'kind':'text','pos':Vector2(820,630),'text':'18','life':.3,'max':.6},{'kind':'impact','pos':Vector2(800,630),'dir':Vector2.RIGHT,'life':.15,'max':.22,'heavy':true,'tone':'metal'},{'kind':'deflect','pos':Vector2(830,620),'dir':Vector2.LEFT,'life':.1,'max':.2},{'kind':'spawn','pos':Vector2(860,630),'life':.2,'max':.38},{'kind':'slash','pos':Vector2(800,650),'dir':Vector2.RIGHT,'life':.1,'max':.2,'strong':true},{'kind':'cordao','source':'cordao','pos':Vector2(750,700),'radius':100,'life':.2,'max':.4},{'kind':'status','pos':Vector2(780,610),'status':'shield','owner':1,'life':.2,'max':.4},{'kind':'contrapeso','source':'contrapeso','pos':Vector2(760,700),'dir':Vector2.RIGHT,'life':.2,'max':.4},{'kind':'contrapeso_break','pos':Vector2(760,700),'life':.2,'max':.4},{'kind':'fratura','source':'fratura','pos':Vector2(700,670),'dir':Vector2.RIGHT,'life':.2,'max':.4},{'kind':'enemy_beam','pos':Vector2(850,500),'dir':Vector2.DOWN,'life':.2,'max':.4},{'kind':'danger','pos':Vector2(680,690),'radius':100,'life':.2,'max':.4},{'kind':'burst','pos':Vector2(770,650),'life':.2,'max':.4}]
			game.combat.projectile(Vector2(800,720),Vector2.RIGHT*200,10)
			game.combat.effects.append({'kind':'cordao','pos':Vector2(750,700),'radius':155.0,'life':.2,'max':.42})
			game.combat.effects.append({'kind':'dash','pos':Vector2(800,650),'dir':Vector2.RIGHT,'life':.1,'max':.22})
			game.world.queue_redraw();game.touch.queue_redraw();game.hud.update_status()
			await process_frame;await process_frame
	print('DRAW_CALLBACKS ',draws[0],' expected at least 18 across six areas')
	game.sound.shutdown();await create_timer(.15).timeout
	game.queue_free();await process_frame
	quit(0 if draws[0]>=18 else 1)
