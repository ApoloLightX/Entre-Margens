extends Control
var game
func _draw():
	var r=game.current_room();var origin=Vector2(14,8);var extent=Vector2(660,220);var world_size=Vector2(r.size[0],r.size[1])
	draw_rect(Rect2(origin,extent),Color('#0c1a22'))
	for p in r.props:
		var at=origin+Vector2(p.x,p.y)/world_size*extent
		draw_rect(Rect2(at-Vector2(3,3),Vector2(6,6)),Color('#48606a'))
	for o in r.objects:
		var at=origin+Vector2(o.x,o.y)/world_size*extent
		var required=o.id in r.required and not o.id in game.state.done
		draw_circle(at,5 if required else 3,Color('#e5b77a') if required else Color('#75abad'))
	var exit=origin+Vector2(r.exit[0],r.exit[1])/world_size*extent
	draw_circle(exit,6,Color('#b5dfb8'),false,2)
	var player=origin+game.state.position/world_size*extent
	draw_circle(player,5,Color.WHITE);draw_arc(player,8,0,TAU,20,Color.WHITE,1)
