extends Control
## Responsive touch HUD for the 3D vertical slice.

var player
var level
var health := 140.0
var focus := 100.0
var area := "MARGEM DE IQALUIT"
var objective := "Desperte os três Marcos de Vigília"
var cooldowns := {"garra":0.0,"lanca":0.0,"muralha":0.0,"pulso":0.0,"passo":0.0}
var damage_flash := 0.0
var completed := false

var move_finger := -1
var look_finger := -1
var move_origin := Vector2.ZERO
var move_knob := Vector2.ZERO
var last_look := Vector2.ZERO

const JOY_RADIUS := 74.0
const JOY_KNOB := 34.0
const ACTION_RADIUS := 54.0
const SMALL_RADIUS := 42.0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	set_process(true)

func bind(p, l):
	player = p
	level = l
	player.stats_changed.connect(_on_stats)
	player.cooldowns_changed.connect(_on_cooldowns)
	level.objective_changed.connect(_on_objective)
	level.area_changed.connect(_on_area)
	level.completed.connect(_on_completed)
	queue_redraw()

func _process(delta):
	damage_flash = maxf(0.0, damage_flash-delta*2.7)
	queue_redraw()

func _on_stats(h:float, f:float):
	health = h
	focus = f

func _on_cooldowns(values:Dictionary):
	cooldowns = values

func _on_objective(text:String):
	objective = text

func _on_area(text:String):
	area = text

func _on_completed():
	completed = true

func flash_damage():
	damage_flash = 0.48

func _layout()->Dictionary:
	var s = size
	return {
		"joy": Vector2(108, s.y-112),
		"attack": Vector2(s.x-92, s.y-105),
		"dash": Vector2(s.x-214, s.y-84),
		"spear": Vector2(s.x-254, s.y-177),
		"wall": Vector2(s.x-160, s.y-219),
		"pulse": Vector2(s.x-76, s.y-207),
		"interact": Vector2(s.x*0.5, s.y-77)
	}

func _input(event):
	if player == null:
		return
	var l = _layout()
	if event is InputEventScreenTouch:
		if event.pressed:
			var p = event.position
			if p.distance_to(l.attack) <= ACTION_RADIUS:
				player.strike()
				get_viewport().set_input_as_handled()
				return
			if p.distance_to(l.spear) <= SMALL_RADIUS:
				player.cast_spear()
				get_viewport().set_input_as_handled()
				return
			if p.distance_to(l.wall) <= SMALL_RADIUS:
				player.cast_wall()
				get_viewport().set_input_as_handled()
				return
			if p.distance_to(l.pulse) <= SMALL_RADIUS:
				player.cast_pulse()
				get_viewport().set_input_as_handled()
				return
			if p.distance_to(l.dash) <= SMALL_RADIUS:
				player.dash()
				get_viewport().set_input_as_handled()
				return
			if p.distance_to(l.interact) <= SMALL_RADIUS:
				player.request_interact()
				get_viewport().set_input_as_handled()
				return
			if p.x < size.x*0.42 and p.y > size.y*0.42 and move_finger == -1:
				move_finger = event.index
				move_origin = l.joy
				_update_move(p)
				get_viewport().set_input_as_handled()
				return
			if p.x > size.x*0.40 and look_finger == -1:
				look_finger = event.index
				last_look = p
		else:
			if event.index == move_finger:
				move_finger = -1
				move_knob = Vector2.ZERO
				player.set_touch_move(Vector2.ZERO)
			if event.index == look_finger:
				look_finger = -1
	elif event is InputEventScreenDrag:
		if event.index == move_finger:
			_update_move(event.position)
			get_viewport().set_input_as_handled()
		elif event.index == look_finger:
			var delta = event.position-last_look
			last_look = event.position
			player.add_touch_look(delta)
			get_viewport().set_input_as_handled()

func _update_move(pos:Vector2):
	var delta = (pos-move_origin).limit_length(JOY_RADIUS*0.72)
	move_knob = delta
	var dir = delta/(JOY_RADIUS*0.72)
	if dir.length() < 0.12:
		dir = Vector2.ZERO
	player.set_touch_move(dir)

func _draw():
	var font = ThemeDB.fallback_font
	var l = _layout()
	var panel = Color(0.018,0.055,0.073,0.82)
	var line = Color("#7fa0aa",0.55)
	var ice = Color("#84dff3")
	var warm = Color("#efb263")
	var ink = Color("#e7f1f2")

	# Top-left warrior status.
	draw_style_box(_box(panel,line,18), Rect2(24,22,326,104))
	draw_string(font,Vector2(42,49),"GUERREIRO DE IQALUIT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,ink)
	draw_string(font,Vector2(42,72),"BRAÇO DE GELO",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#93b5bd"))
	_bar(Rect2(42,83,286,12),health/140.0,Color("#e78977"),Color("#172c34"))
	_bar(Rect2(42,103,286,9),focus/100.0,ice,Color("#172c34"))

	# Center location.
	var area_width = minf(520.0, maxf(260.0, font.get_string_size(area,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+54.0))
	draw_style_box(_box(Color(0.018,0.055,0.073,0.68),line,16),Rect2(size.x*0.5-area_width*0.5,22,area_width,42))
	draw_string(font,Vector2(size.x*0.5-area_width*0.5+22,49),area,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#b7d4d9"))

	# Objective card.
	var obj_rect = Rect2(size.x-390,22,366,84)
	draw_style_box(_box(panel,line,18),obj_rect)
	draw_string(font,obj_rect.position+Vector2(20,27),"OBJETIVO",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#93b5bd"))
	draw_string(font,obj_rect.position+Vector2(20,55),objective,HORIZONTAL_ALIGNMENT_LEFT,330,16,ink)

	# Crosshair.
	var c = size*0.5
	draw_line(c+Vector2(-10,0),c+Vector2(-3,0),Color(ink,.85),2)
	draw_line(c+Vector2(3,0),c+Vector2(10,0),Color(ink,.85),2)
	draw_line(c+Vector2(0,-10),c+Vector2(0,-3),Color(ink,.85),2)
	draw_line(c+Vector2(0,3),c+Vector2(0,10),Color(ink,.85),2)

	# Joystick.
	draw_circle(l.joy,JOY_RADIUS,Color(0.02,0.07,0.09,0.46))
	draw_arc(l.joy,JOY_RADIUS,0,TAU,56,Color("#a7cbd0",0.35),2)
	draw_circle(l.joy+move_knob,JOY_KNOB,Color("#b6dadd",0.52))
	draw_arc(l.joy+move_knob,JOY_KNOB,0,TAU,40,Color("#e2f0ef",0.55),2)

	_action(l.attack,ACTION_RADIUS,"GARRA",warm,"garra",0.43)
	_action(l.spear,SMALL_RADIUS,"LANÇA",ice,"lanca",2.15)
	_action(l.wall,SMALL_RADIUS,"MURALHA",Color("#b7eef4"),"muralha",5.2)
	_action(l.pulse,SMALL_RADIUS,"PULSO",Color("#79bce9"),"pulso",8.4)
	_action(l.dash,SMALL_RADIUS,"PASSO",Color("#a8d3d9"),"passo",1.0)

	draw_circle(l.interact,SMALL_RADIUS,Color(0.02,0.07,0.09,0.68))
	draw_arc(l.interact,SMALL_RADIUS,0,TAU,40,Color("#d5e9e9",.55),2)
	draw_string(font,l.interact+Vector2(-27,5),"INTERAGIR",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)

	# Desktop hint is intentionally quiet.
	draw_string(font,Vector2(26,size.y-18),"WASD · mouse | Q lança · E muralha · R pulso · Shift passo · F interagir",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#9bb5bb",.65))

	if damage_flash > 0:
		draw_rect(Rect2(Vector2.ZERO,size),Color("#8fcde8",damage_flash*0.18),true)

	if completed:
		var end_rect = Rect2(size.x*0.5-260,size.y*0.5-60,520,120)
		draw_style_box(_box(Color(0.015,0.045,0.06,.94),Color("#8bd9e6",.8),20),end_rect)
		draw_string(font,end_rect.position+Vector2(40,45),"A FENDA SILENCIOU",HORIZONTAL_ALIGNMENT_LEFT,-1,27,ink)
		draw_string(font,end_rect.position+Vector2(40,79),"Vertical slice 3D concluída",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#9fc3ca"))

func _action(center:Vector2,radius:float,label:String,color:Color,key:String,total:float):
	var font = ThemeDB.fallback_font
	var cd = float(cooldowns.get(key,0.0))
	draw_circle(center,radius+3,Color(0.01,0.04,0.055,.62))
	draw_circle(center,radius,Color(0.035,0.10,0.125,.84))
	draw_arc(center,radius,0,TAU,48,Color(color,.74),2)
	if cd > 0:
		var pct = clampf(cd/total,0,1)
		draw_arc(center,radius-5,-PI/2,-PI/2+TAU*pct,48,Color(color,.92),4)
	var width = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_string(font,center+Vector2(-width*0.5,4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#edf7f7"))

func _bar(rect:Rect2,value:float,color:Color,bg:Color):
	draw_rect(rect,bg,true)
	var fill = rect
	fill.size.x *= clampf(value,0,1)
	draw_rect(fill,color,true)

func _box(bg:Color,border:Color,radius:int)->StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box
