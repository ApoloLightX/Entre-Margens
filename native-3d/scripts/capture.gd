extends SceneTree
var frames := 0
var game
func _initialize():
	game = load("res://main.tscn").instantiate()
	root.add_child.call_deferred(game)
func _process(_delta):
	frames += 1
	if frames == 8:
		game.menu.hide()
		game.active = true
	if frames == 40:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview.png")
		quit()
