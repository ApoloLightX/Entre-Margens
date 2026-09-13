extends Node2D
## Two-finger input in logical viewport coordinates; no domain mutations.
var game
var direction = Vector2.ZERO
var finger = -1
var enabled = false
var origin = Vector2(160,555)
const RADIUS = 88.0
const ACTION_CENTER = Vector2(1120,555)
const ACTION_RADIUS = 66.0
const INTERACT_CENTER = Vector2(980,555)
var knob = Vector2.ZERO

func _ready() -> void:
	z_index=20
	enabled=OS.has_feature("android") or "--touch" in OS.get_cmdline_user_args()
	visible=false

func reset() -> void:
	finger=-1
	direction=Vector2.ZERO
	knob=Vector2.ZERO
	queue_redraw()

func _process(_delta:float) -> void:
	var active=enabled and game.state.data.started and not game.ui.is_open()
	if not active and finger!=-1:reset()
	visible=active
	if active:queue_redraw()

func touch_start(index:int,point:Vector2) -> bool:
	if point.distance_to(origin)<=RADIUS+30 and finger==-1:
		finger=index
		update_direction(point)
		return true
	return false

func update_direction(point:Vector2) -> void:
	knob=(point-origin).limit_length(RADIUS)
	direction=Vector2.ZERO if knob.length()<14 else knob/RADIUS

func touch_end(index:int) -> void:
	if index==finger:reset()

func _input(event:InputEvent) -> void:
	if not visible:return
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_start(event.index,event.position):get_viewport().set_input_as_handled()
			elif event.position.distance_to(ACTION_CENTER)<=ACTION_RADIUS+8:
				game.attack()
				get_viewport().set_input_as_handled()
			elif event.position.distance_to(INTERACT_CENTER)<=ACTION_RADIUS+8:
				game.interact()
				get_viewport().set_input_as_handled()
		else:
			if event.index==finger:
				touch_end(event.index)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==finger:
		update_direction(event.position)
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_circle(origin,RADIUS,Color(0.08,0.18,0.23,0.72))
	draw_arc(origin,RADIUS,0,TAU,64,Color("#b7c5b5"),3,true)
	draw_circle(origin+knob*0.65,32,Color("#c6ac76"))
	draw_circle(ACTION_CENTER,ACTION_RADIUS,Color(0.12,0.29,0.34,0.90))
	draw_arc(ACTION_CENTER,ACTION_RADIUS,0,TAU,48,Color("#d7bd83"),3,true)
	draw_string(ThemeDB.fallback_font,ACTION_CENTER+Vector2(-40,8),"ATQ",HORIZONTAL_ALIGNMENT_CENTER,80,28,Color("#fff0c7"))
	draw_circle(INTERACT_CENTER,ACTION_RADIUS,Color(0.18,0.25,0.30,0.90))
	draw_arc(INTERACT_CENTER,ACTION_RADIUS,0,TAU,48,Color("#a9c6c2"),3,true)
	draw_string(ThemeDB.fallback_font,INTERACT_CENTER+Vector2(-40,8),"AGIR",HORIZONTAL_ALIGNMENT_CENTER,80,24,Color("#d8e8de"))
