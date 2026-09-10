extends Node2D
## Independent finger ownership and safe-area-relative controls.
var game
var direction=Vector2.ZERO
var move_finger=-1
var action_fingers={}
var attack_held=false
var origin=Vector2(110,432)
var knob=Vector2.ZERO
var font=preload('res://assets/action/body.ttf')
var buttons:Dictionary={}
var press_flash={'attack':0.0,'cast':0.0,'dodge':0.0}
const Icons=preload('res://action/icons.gd')
func _ready():
	get_viewport().size_changed.connect(layout_controls);layout_controls()
func layout_controls():
	var r=game.preferences.safe_rect(get_viewport())
	origin=Vector2(r.position.x+78,r.end.y-78)
	buttons={'attack':Vector3(r.end.x-64,r.end.y-64,52),'cast':Vector3(r.end.x-184,r.end.y-58,44),'dodge':Vector3(r.end.x-74,r.end.y-185,44)}
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
			if event.position.distance_to(origin)<84 and move_finger<0:
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
		if event.position.distance_to(origin)<84:move_finger=-2;update_stick(event.position);get_viewport().set_input_as_handled();return
		for action in buttons:
			var b=buttons[action]
			if event.position.distance_to(Vector2(b.x,b.y))<b.z:
				if action=='attack':attack_held=true
				trigger(action);get_viewport().set_input_as_handled();return
	elif event is InputEventMouseMotion and move_finger==-2:update_stick(event.position)
func update_stick(pos:Vector2):
	knob=(pos-origin).limit_length(57);direction=knob/57
	if direction.length()<.12:direction=Vector2.ZERO
func icon(action:String,p:Vector2,color:Color):
	Icons.paint(self,game.state.technique if action=='cast' else action,p,color,40)
func _draw():
	if game==null or game.modal:return
	draw_circle(origin,66,Color(.025,.07,.09,.64));draw_arc(origin,66,0,TAU,48,Color(.75,.86,.86,.35),2)
	for v in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:draw_line(origin+v*45,origin+v*52,Color(.8,.88,.88,.5),3)
	draw_circle(origin+knob,27,Color(.65,.82,.82,.68));draw_arc(origin+knob,27,0,TAU,32,Color(.85,.95,.94,.65),2)
	for action in buttons:
		var b=buttons[action];var p=Vector2(b.x,b.y)
		var color=Color('#efb76d') if action=='attack' else (Color('#eee5cc') if action=='cast' and game.state.technique=='fratura' else Color('#a3d9db'))
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
