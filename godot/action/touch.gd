extends Node2D
## Independent finger ownership and safe-area-relative controls.
var game
var direction=Vector2.ZERO
var move_finger=-1
var action_fingers={}
var attack_held=false
var origin=Vector2(110,432)
var joystick_radius=60.0
var knob=Vector2.ZERO
var font=preload('res://assets/action/body.ttf')
var buttons:Dictionary={}
var press_flash={'attack':0.0,'cast':0.0,'dodge':0.0}
const Icons=preload('res://action/icons.gd')
const JOYSTICK_HIT_PADDING=12.0
const KNOB_TRAVEL_RATIO=.8
const KNOB_RADIUS_RATIO=.4
const DIRECTION_MARKER_INNER_RATIO=2.0/3.0
const DIRECTION_MARKER_OUTER_RATIO=47.0/60.0
func _ready():
	# HUD Controls own layout. Request their resolved geometry after both nodes
	# have entered the tree; touch never listens to viewport resize itself.
	call_deferred('layout_controls')
func layout_controls():
	if game!=null and game.hud!=null:game.hud.sync_touch_layout()
func apply_layout(new_origin:Vector2,action_centers:Dictionary,radius:float,new_joystick_radius:float):
	origin=new_origin
	joystick_radius=new_joystick_radius
	buttons={}
	for action in action_centers:
		var center:Vector2=action_centers[action]
		buttons[action]=Vector3(center.x,center.y,radius)
	release_all();queue_redraw()
func release_all():
	direction=Vector2.ZERO;move_finger=-1;action_fingers.clear();attack_held=false;knob=Vector2.ZERO
	for key in press_flash:press_flash[key]=0.0
func _process(dt):
	for key in press_flash:press_flash[key]=maxf(0,press_flash[key]-dt)
	queue_redraw()
func trigger(action:String):
	press_flash[action]=.14;queue_redraw()
	match action:
		'attack':game.combat.attack()
		'cast':game.combat.cast()
		'dodge':game.combat.dodge(game.input_direction())
func _input(event):
	if game.modal:release_all();return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.index==move_finger or action_fingers.has(event.index):return
			if event.position.distance_to(origin)<joystick_radius+JOYSTICK_HIT_PADDING and move_finger<0:
				move_finger=event.index;update_stick(event.position);get_viewport().set_input_as_handled();return
			for action in buttons:
				var b=buttons[action]
				if event.position.distance_to(Vector2(b.x,b.y))<b.z+6:
					action_fingers[event.index]=action
					if action=='attack':attack_held=true
					trigger(action);get_viewport().set_input_as_handled();return
		else:
			if event.index==move_finger:move_finger=-1;direction=Vector2.ZERO;knob=Vector2.ZERO
			action_fingers.erase(event.index);attack_held='attack' in action_fingers.values()
	elif event is InputEventScreenDrag and event.index==move_finger:
		update_stick(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		# A synthetic mouse release must not release an independently held touch.
		if event.device==InputEvent.DEVICE_ID_EMULATION:return
		if not event.pressed:
			if move_finger==-2:move_finger=-1;direction=Vector2.ZERO;knob=Vector2.ZERO
			attack_held=false;return
		if event.position.distance_to(origin)<joystick_radius+JOYSTICK_HIT_PADDING:move_finger=-2;update_stick(event.position);get_viewport().set_input_as_handled();return
		for action in buttons:
			var b=buttons[action]
			if event.position.distance_to(Vector2(b.x,b.y))<b.z:
				if action=='attack':attack_held=true
				trigger(action);get_viewport().set_input_as_handled();return
	elif event is InputEventMouseMotion and move_finger==-2:update_stick(event.position)
func update_stick(pos:Vector2):
	var travel=joystick_radius*KNOB_TRAVEL_RATIO
	knob=(pos-origin).limit_length(travel);direction=knob/travel
	if direction.length()<.12:direction=Vector2.ZERO
func icon(action:String,p:Vector2,color:Color):
	Icons.paint(self,game.state.technique if action=='cast' else action,p,color,40)
func action_color(action:String)->Color:
	if action=='attack':return Color('#efb76d')
	if action=='dodge':return Color('#a3d9db')
	match game.state.technique:
		'cordao':return Color('#bceeff')
		'fratura':return Color('#4f9bd6')
		'contrapeso':return Color('#d9e8e9')
	return Color('#a3d9db')
func _draw():
	if game==null or game.modal:return
	draw_circle(origin,joystick_radius,Color(.025,.07,.09,.64));draw_arc(origin,joystick_radius,0,TAU,48,Color(.75,.86,.86,.35),2)
	var marker_inner=joystick_radius*DIRECTION_MARKER_INNER_RATIO;var marker_outer=joystick_radius*DIRECTION_MARKER_OUTER_RATIO
	for v in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:draw_line(origin+v*marker_inner,origin+v*marker_outer,Color(.8,.88,.88,.5),3)
	if direction.length()>.1:draw_line(origin+direction*(joystick_radius*5.0/12.0),origin+direction*(joystick_radius*KNOB_TRAVEL_RATIO),Color('#92d6d7',.55),4)
	var knob_radius=joystick_radius*KNOB_RADIUS_RATIO
	draw_circle(origin+knob,knob_radius,Color(.65,.82,.82,.68));draw_arc(origin+knob,knob_radius,0,TAU,32,Color(.85,.95,.94,.65),2)
	for action in buttons:
		var b=buttons[action];var p=Vector2(b.x,b.y)
		var color=action_color(action)
		var cd=game.combat.attack_cd if action=='attack' else (game.combat.spell_cd if action=='cast' else game.combat.dodge_cd)
		var total=.52 if action=='attack' else (float(game.catalog.combat.techniques[game.state.technique].cooldown) if action=='cast' else 1.05)
		var down=action in action_fingers.values() or (action=='attack' and attack_held) or press_flash[action]>0
		draw_circle(p,b.z+3,Color(.015,.045,.06,.55));draw_circle(p,b.z,Color('#314953') if down else Color(.04,.10,.13,.85))
		draw_arc(p,b.z,0,TAU,48,Color(color,.95 if down else .6),2)
		if press_flash[action]>0:draw_arc(p,b.z-2,0,TAU,48,Color(color,press_flash[action]/.14),4)
		if cd>0:draw_arc(p,b.z-4,-PI/2,-PI/2+TAU*minf(cd/total,1),40,color,3)
		icon(action,p-Vector2(0,8),Color(color,.62 if cd>0 and not down else 1.0))
		var label='ATQ' if action=='attack' else ('TÉCNICA' if action=='cast' else 'ESQ')
		draw_string(font,p+Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,28),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
