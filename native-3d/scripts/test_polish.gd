extends SceneTree
var game
var frames := 0
func check(ok: bool, message: String):
 if not ok:
  push_error(message)
  quit(1)
func _initialize():
 game = load("res://main.tscn").instantiate()
 root.add_child.call_deferred(game)
func _process(_dt):
 frames += 1
 if frames == 9: quit()
 if frames != 8: return
 game.active = true
 var enemy = game.enemies[1]
 game.player.position = enemy.node.position+Vector3(0,1,2)
 enemy.node.rotation.y = 0
 enemy.hp = 80.0
 game.hit_enemy(enemy,28)
 check(is_equal_approx(enemy.hp,68.8),"Shield must reduce frontal projectile damage")
 enemy.node.rotation.y = PI
 game.hit_enemy(enemy,28)
 check(is_equal_approx(enemy.hp,40.8),"Rear attack must bypass shield")
 check(game.model_cache.size() == 10,"All ten Blender assets must load")
 game.move_touch = Vector2.ONE
 game.pause_game()
 check(not game.active and game.move_touch == Vector2.ZERO,"Pause must clear held movement")
 game.end_run(false)
 check(game.menu.visible and not game.active,"Death must offer retry")
 print("Escudo direcional, dez GLBs, pausa e derrota verificados")
