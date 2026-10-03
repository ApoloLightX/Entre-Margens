extends SceneTree
var game
var frames := 0
func _initialize():
 game = load("res://main.tscn").instantiate()
 root.add_child.call_deferred(game)
func _process(_dt):
 frames += 1
 if frames == 12:
  capture("res://preview_menu.png")
 if frames == 14:
  game.menu.hide()
  game.active = true
 if frames == 35:
  capture("res://preview.png")
  game.player.position = Vector3(0,1.3,-5)
  game.camera.rotation.x = -0.04
 if frames == 42:
  game.cast("onda")
 if frames == 46:
  capture("res://preview_combat.png")
  print("Review captured ",root.get_visible_rect().size)
 if frames == 50: quit()

func capture(path: String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
