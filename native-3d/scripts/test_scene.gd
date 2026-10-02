extends SceneTree
var game
var frames := 0
func _initialize():
	game = load("res://main.tscn").instantiate()
	root.add_child.call_deferred(game)
func _physics_process(_dt):
	frames += 1
	if frames == 5:
		assert(game.enemies.size() == 7)
		game.active = true
		game.cast("lanca")
		assert(game.bolts.size() == 1)
		assert(game.focus == 88)
		game.cast("lanca")
		assert(game.bolts.size() == 1)
		game.cast("guarda")
		assert(game.guard == 3)
		var target = game.enemies[0]
		game.player.position = target.node.position+Vector3(0,1,2)
		var before: float = target.hp
		game.cast("onda")
		assert(target.hp == before-38)
		assert(target.slow == 4)
		game.cast("soco")
		var after: float = target.hp
		game.cast("soco")
		assert(target.hp == after)
		game.player.position = Vector3(0,2,7)
	if frames == 120:
		assert(game.player.is_on_floor())
		assert(game.player.position.y > 0)
		assert(game.cooldowns.lanca == 0)
		print("Cena, projétil, recarga, guarda e chão físico verificados")
		quit()
