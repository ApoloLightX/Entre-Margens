extends Node3D
const Rules = preload("res://scripts/rules.gd")
var player: CharacterBody3D
var camera: Camera3D
var arm: Node3D
var hud: Label
var menu: Control
var touch_actions: Array[Dictionary] = []
var focus := 100.0
var health := 100.0
var active := false
var won := false
var guard := 0.0
var dodge_time := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector3.ZERO
var hostile_bolts: Array[Dictionary] = []
var cooldowns := {"lanca": 0.0, "onda": 0.0, "guarda": 0.0}
var enemies: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var move_touch := Vector2.ZERO
var look_finger := -1
var move_finger := -1
var touch_origin := Vector2.ZERO
var melee_cooldown := 0.0
var attack_pose := 0.0
var elapsed := 0.0
var kills := 0
var ice: StandardMaterial3D
var stone: StandardMaterial3D
var snow: StandardMaterial3D
var metal: StandardMaterial3D
var amber: StandardMaterial3D
var seed_rng := RandomNumberGenerator.new()
func material(color: Color, rough := 0.7, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m
func mesh(parent: Node3D, shape: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.position = pos
	n.material_override = mat
	parent.add_child(n)
	return n
func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var n := mesh(parent, shape, pos, mat)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		n.add_child(body)
		body.add_child(collision)
	return n
func sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2
	s.radial_segments = 12
	s.rings = 8
	return mesh(parent, s, pos, mat)
func crystal(parent: Node3D, pos: Vector3, width: float, height: float) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = 0
	c.bottom_radius = width
	c.height = height
	c.radial_segments = 5
	return mesh(parent, c, pos, ice)
func _ready():
	seed_rng.seed = 742
	ice = material(Color("b2dbe2"), 0.22, 0.04)
	ice.metallic = 0.35
	stone = material(Color("233646"))
	snow = material(Color("c6dce1"))
	metal = material(Color("334248"), 0.4)
	amber = material(Color("ffb66a"), 0.4, 2)
	for pair in [[snow,"snow_02"],[stone,"rock_boulder_dry"]]:
		pair[0].albedo_texture = load("res://assets/%s_diff_1k.jpg" % pair[1])
		pair[0].normal_enabled = true
		pair[0].normal_texture = load("res://assets/%s_nor_gl_1k.jpg" % pair[1])
		pair[0].roughness_texture = load("res://assets/%s_rough_1k.jpg" % pair[1])
		pair[0].uv1_triplanar = true
		pair[0].uv1_scale = Vector3(0.3,0.3,0.3)
	world()
	build_player()
	build_ui()
func world():
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("102334")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8daec4")
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("284456")
	env.fog_density = 0.012
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_color = Color("a6d7f5")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	box(self, Vector3(0,-1,-30), Vector3(120,2,160), snow, true)
	build_terrain()
	# A broad raised causeway keeps the route readable without enclosing exploration.
	for i in range(32):
		var z := 8.0 - i * 2.4
		box(self, Vector3(0,0.12,z), Vector3(7,0.24,2.25), stone, true)
		for side in [-1,1]:
			if i % 3 == 0:
				box(self, Vector3(side*3.5,0.8,z), Vector3(0.18,1.6,0.18), metal, true)
				box(self, Vector3(side*3.5,1.0,z), Vector3(0.28,0.35,0.28), amber)
				if i % 6 == 0:
					var lamp := OmniLight3D.new()
					lamp.position = Vector3(side*3.5,1.2,z)
					lamp.light_color = Color("ffad63")
					lamp.light_energy = 2
					lamp.omni_range = 6
					add_child(lamp)
			box(self, Vector3(side*3.5,1.5,z), Vector3(0.12,0.12,2.45), metal)
	for i in range(120):
		var side := -1 if i % 2 == 0 else 1
		var p := Vector3(side*seed_rng.randf_range(6,35),0,-seed_rng.randf_range(-15,100))
		var h := seed_rng.randf_range(2,13)
		var rock := sphere(self,p+Vector3(side*(h+3),h*0.3,0),h*0.7,stone)
		rock.scale = Vector3(1,seed_rng.randf_range(1,2),0.8)
		rock.rotation_degrees.y = seed_rng.randf_range(0,360)
		sphere(self,p+Vector3(side*(h+3),h*0.85,0),h*0.45,snow).scale = Vector3(1,0.25,1)
		if i % 3 == 0:
			crystal(self,p+Vector3(1,h*0.3,1),0.7,h)
	for z in [-18,-46,-67]:
		for side in [-1,1]:
			box(self,Vector3(side*5,3,z),Vector3(1,6,1),stone,true)
			box(self,Vector3(side*5,6.2,z),Vector3(1.5,0.4,1.5),snow)
		box(self,Vector3(0,5.7,z),Vector3(11,0.8,1),stone)
	# Warm refuge marks the destination across the frozen bay.
	box(self,Vector3(0,2,-76),Vector3(11,4,7),stone,true)
	box(self,Vector3(0,4.3,-76),Vector3(12,0.6,8),snow)
	box(self,Vector3(0,2,-72.4),Vector3(3,2.8,0.1),amber)
	for x in [-3.5,3.5]:
		box(self,Vector3(x,2,-72.4),Vector3(1.8,1.4,0.1),amber)
	for i in range(7):
		spawn_enemy(Vector3(seed_rng.randf_range(-2.5,2.5),0.4,-15-i*7),i % 3)
func build_player():
	player = CharacterBody3D.new()
	player.position = Vector3(0,2,7)
	add_child(player)
	var c := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	c.shape = capsule
	player.add_child(c)
	camera = Camera3D.new()
	camera.position.y = 0.65
	camera.fov = 78
	player.add_child(camera)
	arm = Node3D.new()
	camera.add_child(arm)
	arm.position = Vector3(0.42,-0.4,-0.85)
	arm.scale = Vector3.ONE*0.6
	arm.rotation_degrees = Vector3(-65,0,-10)
	var sleeve := material(Color("263846"))
	var forearm := CylinderMesh.new()
	forearm.top_radius = 0.13
	forearm.bottom_radius = 0.19
	forearm.height = 0.72
	forearm.radial_segments = 10
	mesh(arm,forearm,Vector3(0,-0.32,0),ice)
	var cuff := CylinderMesh.new()
	cuff.top_radius = 0.19
	cuff.bottom_radius = 0.2
	cuff.height = 0.12
	mesh(arm,cuff,Vector3(0,-0.66,0),sleeve)
	# Articulated palm and five separated fingers, never a barrel silhouette.
	sphere(arm,Vector3.ZERO,0.18,ice).scale = Vector3(0.8,1.3,0.55)
	for i in range(4):
		var finger := sphere(arm,Vector3((i-1.5)*0.075,0.23,0),0.044,ice)
		finger.scale = Vector3(0.8,3.2,0.9)
		finger.rotation_degrees.z = (1.5-i)*6
		crystal(arm,Vector3((i-1.5)*0.075,0.4,0),0.04,0.1)
	var thumb := sphere(arm,Vector3(-0.16,0.06,0.02),0.06,ice)
	thumb.scale = Vector3(0.7,2.2,0.8)
	thumb.rotation_degrees.z = -35
	for i in range(8):
		crystal(arm,Vector3(seed_rng.randf_range(-0.12,0.12),-i*0.07,0.13),0.025,0.09)
func spawn_enemy(pos: Vector3, kind: int):
	var n := StaticBody3D.new()
	add_child(n)
	n.position = pos
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	n.add_child(collision)
	var torso := sphere(n,Vector3(0,0.9,0),0.55,metal)
	torso.scale.y = 1.3
	box(n,Vector3(0,1.0,0.5),Vector3(0.22,0.5,0.08),amber)
	for side in [-1,1]:
		box(n,Vector3(side*0.45,0.25,0),Vector3(0.25,0.6,0.3),metal)
		box(n,Vector3(side*0.75,0.95,0),Vector3(0.6,0.18,0.18),metal)
	if kind == 1:
		box(n,Vector3(-0.75,1,0.35),Vector3(0.6,1.4,0.22),stone)
	if kind == 2:
		crystal(n,Vector3(0,1.9,0),0.45,1.1)
	enemies.append({"node":n,"hp":80.0 if kind == 1 else 55.0,"kind":kind,"timer":2.0,"slow":0.0,"flash":0.0})
func build_ui():
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	hud = Label.new()
	hud.position = Vector2(24,18)
	hud.add_theme_font_size_override("font_size",20)
	root.add_child(hud)
	var cross := Label.new()
	cross.text = "·"
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.add_theme_font_size_override("font_size",36)
	root.add_child(cross)
	var actions := HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-580,-90)
	actions.size = Vector2(560,65)
	root.add_child(actions)
	for data in [["Soco","soco"],["Lança","lanca"],["Onda","onda"],["Guarda","guarda"],["Esquiva","esquiva"]]:
		var b := Button.new()
		b.text = data[0]
		b.custom_minimum_size = Vector2(100,60)
		b.pressed.connect(action_button.bind(data[1]))
		actions.add_child(b)
		touch_actions.append({"button":b,"power":data[1]})
	menu = ColorRect.new()
	menu.color = Color(0.025,0.065,0.1,0.88)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var column := VBoxContainer.new()
	column.position = Vector2(70,140)
	menu.add_child(column)
	var title := Label.new()
	title.text = "ENTRE MARGENS\nPASSO DA MARÉ FRIA"
	title.add_theme_font_size_override("font_size",42)
	column.add_child(title)
	var desc := Label.new()
	desc.text = "Um guerreiro de Iqaluit. Um braço moldado em gelo.\nAbra a passagem e alcance o abrigo.\n\nWASD · mouse · clique: lança · Q: soco · E: onda · R: guarda · Shift: esquiva\nCelular: arraste à esquerda para andar, à direita para olhar."
	column.add_child(desc)
	var start := Button.new()
	start.text = "ATRAVESSAR A MARÉ"
	start.custom_minimum_size = Vector2(340,64)
	start.pressed.connect(func():
		active = true
		menu.hide()
		if not DisplayServer.is_touchscreen_available():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	column.add_child(start)
func _input(event):
	if not active: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cast("lanca")
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q: cast("soco")
			KEY_E: cast("onda")
			KEY_R: cast("guarda")
			KEY_SHIFT: cast("esquiva")
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				active = false
				menu.show()
	if event is InputEventScreenTouch:
		if event.pressed:
			for action in touch_actions:
				if action.button.get_global_rect().has_point(event.position):
					cast(action.power)
					get_viewport().set_input_as_handled()
					return
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.4:
				move_finger = event.index
				touch_origin = event.position
			else: look_finger = event.index
		else:
			if event.index == move_finger:
				move_finger = -1
				move_touch = Vector2.ZERO
			if event.index == look_finger: look_finger = -1
	if event is InputEventScreenDrag:
		if event.index == move_finger: move_touch = ((event.position-touch_origin)/80).limit_length()
		if event.index == look_finger: look(event.relative)
func look(delta: Vector2):
	player.rotate_y(-delta.x*0.003)
	camera.rotation.x = clamp(camera.rotation.x-delta.y*0.003,-1.25,1.25)
func cast(power: String):
	if not active or won: return
	if power == "esquiva":
		if dodge_cooldown > 0 or focus < 15: return
		focus -= 15
		dodge_cooldown = 1.5
		dodge_time = 0.25
		dodge_direction = player.velocity.normalized() if player.velocity.length() > 0.5 else -player.global_basis.z
		dodge_direction.y = 0
		return
	if power == "soco":
		if melee_cooldown > 0: return
		melee_cooldown = 0.55
		attack_pose = 0.3
		sound(180,0.12)
		for e in enemies:
			if e.node.position.distance_to(player.position) < 3 and (e.node.position-player.position).normalized().dot(-player.global_basis.z) > 0.25:
				e.hp -= 22
				e.node.position += -camera.global_basis.z*0.9
		pulse(player.position+Vector3(0,0.7,0),1.4)
		return
	if not Rules.can_cast(power,focus,cooldowns[power]): return
	attack_pose = 0.24
	sound(640 if power == "lanca" else 220,0.25)
	focus -= Rules.COSTS[power]
	cooldowns[power] = Rules.COOLDOWNS[power]
	match power:
		"lanca":
			var n := crystal(self,camera.global_position-camera.global_basis.z,0.12,0.8)
			n.rotation = camera.global_rotation+Vector3(PI/2,0,0)
			bolts.append({"node":n,"velocity":-camera.global_basis.z*26,"life":3.0})
		"onda":
			for e in enemies:
				var offset: Vector3 = e.node.position-player.position
				if offset.length() < 13 and offset.normalized().dot(-player.global_basis.z) > 0.3:
					e.hp -= 38
					e.slow = 4.0
			for i in range(10):
				var p := player.position-player.global_basis.z*(i+1)
				var n := crystal(self,Vector3(p.x,0.7,p.z),0.55,1.4)
				effects.append({"node":n,"life":1.4})
		"guarda":
			guard = 3.0
			var n := box(camera,Vector3(0,0,-1.4),Vector3(1.5,1.5,0.12),ice)
			effects.append({"node":n,"life":3.0})
func pulse(pos: Vector3, radius: float):
	var n := sphere(self,pos,radius,ice)
	effects.append({"node":n,"life":0.15})
func _physics_process(dt):
	if not active: return
	elapsed += dt
	melee_cooldown = max(0.0,melee_cooldown-dt)
	attack_pose = max(0.0,attack_pose-dt)
	arm.position.z = -0.85-0.3*sin(attack_pose/0.3*PI)
	focus = min(100.0,focus+dt*7)
	guard = max(0.0,guard-dt)
	dodge_time = max(0.0,dodge_time-dt)
	dodge_cooldown = max(0.0,dodge_cooldown-dt)
	for key in cooldowns: cooldowns[key] = max(0.0,cooldowns[key]-dt)
	var input := move_touch
	if Input.is_physical_key_pressed(KEY_A): input.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input.x += 1
	if Input.is_physical_key_pressed(KEY_W): input.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input.y += 1
	var direction := player.global_basis*Vector3(input.x,0,input.y).limit_length()
	player.velocity.x = direction.x*6
	player.velocity.z = direction.z*6
	if dodge_time > 0:
		player.velocity.x = dodge_direction.x*16
		player.velocity.z = dodge_direction.z*16
	player.velocity.y -= dt*18
	player.move_and_slide()
	arm.rotation.z = sin(elapsed*8)*0.035*input.length()
	for i in range(enemies.size()-1,-1,-1):
		var e = enemies[i]
		if e.hp <= 0:
			pulse(e.node.position+Vector3.UP,0.8)
			e.node.queue_free()
			enemies.remove_at(i)
			kills += 1
			continue
		var offset: Vector3 = player.position-e.node.position
		offset.y = 0
		e.slow = max(0.0,e.slow-dt)
		e.timer -= dt
		if offset.length() < 22:
			if offset.length() > 2:
				e.node.position += offset.normalized()*dt*(0.5 if e.slow > 0 else 1.6)
			if e.timer < 0.6:
				e.node.scale = Vector3.ONE*(1.0+sin(elapsed*25)*0.08)
			if e.timer <= 0:
				if offset.length() < 3 and dodge_time <= 0:
					health -= Rules.damage_after_guard(14,guard > 0 and (-offset.normalized()).dot(-player.global_basis.z) > 0.3)
					pulse(player.position,0.25)
				if e.kind == 2 and offset.length() > 3:
					var from: Vector3 = e.node.position+Vector3.UP
					var shot := sphere(self,from,0.13,amber)
					hostile_bolts.append({"node":shot,"velocity":(camera.global_position-from).normalized()*11,"life":4.0})
				e.timer = 2.0
				e.node.scale = Vector3.ONE
	for i in range(bolts.size()-1,-1,-1):
		var b = bolts[i]
		var from: Vector3 = b.node.position
		var to: Vector3 = from+b.velocity*dt
		b.node.position = to
		b.life -= dt
		var query := PhysicsRayQueryParameters3D.create(from,to)
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			for e in enemies:
				if hit.collider == e.node: e.hp -= 28
			b.life = 0
			pulse(hit.position,0.2)
		for e in enemies:
			if b.life > 0 and Geometry3D.get_closest_point_to_segment(e.node.position+Vector3.UP,from,to).distance_to(e.node.position+Vector3.UP) < 0.8:
				e.hp -= 28
				b.life = 0
				pulse(to,0.3)
				break
		if b.life <= 0:
			b.node.queue_free()
			bolts.remove_at(i)
	for i in range(hostile_bolts.size()-1,-1,-1):
		var b = hostile_bolts[i]
		var from: Vector3 = b.node.position
		var to: Vector3 = from+b.velocity*dt
		b.node.position = to
		b.life -= dt
		var query := PhysicsRayQueryParameters3D.create(from,to)
		var exclude: Array[RID] = []
		for e in enemies: exclude.append(e.node.get_rid())
		query.exclude = exclude
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			if hit.collider == player and dodge_time <= 0:
				var front: bool = (-b.velocity.normalized()).dot(-player.global_basis.z) > 0.3
				health -= Rules.damage_after_guard(18,guard > 0 and front)
			b.life = 0
			pulse(hit.position,0.18)
		if b.life <= 0:
			b.node.queue_free()
			hostile_bolts.remove_at(i)
	for i in range(effects.size()-1,-1,-1):
		effects[i].life -= dt
		if effects[i].life <= 0:
			effects[i].node.queue_free()
			effects.remove_at(i)
	if health <= 0:
		health = 100
		focus = 100
		player.position = Vector3(0,2,7)
	if player.position.z < -69 and enemies.is_empty(): won = true
	hud.text = "MARÉ FRIA   •   Vigor %d   /   Foco %d\n%s\nLança %.1fs   Onda %.1fs   Guarda %.1fs" % [health,focus,"Abrigo alcançado — passagem protegida" if won else "Proteja a passagem · %d / 7 sentinelas · Abrigo %dm" % [kills,abs(player.position.z+70)],cooldowns.lanca,cooldowns.onda,cooldowns.guarda]

func terrain_height(x: float, z: float) -> float:
	var edge: float = clamp((abs(x)-5.0)/10.0,0.0,1.0)
	return edge*(1.8+sin(x*0.19+z*0.14)*0.8+cos(z*0.27)*0.4)
func build_terrain():
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-45,45,3):
		for z in range(-100,30,3):
			for corner in [Vector2(0,0),Vector2(3,0),Vector2(0,3),Vector2(3,0),Vector2(3,3),Vector2(0,3)]:
				var px: float = x+corner.x
				var pz: float = z+corner.y
				surface.set_uv(Vector2(px,pz)*0.15)
				surface.add_vertex(Vector3(px,terrain_height(px,pz),pz))
	surface.generate_normals()
	var terrain := mesh(self,surface.commit(),Vector3.ZERO,snow)
	terrain.create_trimesh_collision()
func sound(frequency: float, duration: float):
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var buffer := PackedByteArray()
	buffer.resize(int(duration*22050)*2)
	for i in range(buffer.size()/2):
		var t := float(i)/22050.0
		var value := sin(TAU*frequency*t*(1.0-t))*exp(-t*18)*0.22
		buffer.encode_s16(i*2,int(value*32767))
	wave.data = buffer
	var audio := AudioStreamPlayer.new()
	audio.stream = wave
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func action_button(power: String):
	# Native touch actions are handled per finger, without a second mouse-emulated cast.
	if OS.get_name() not in ["Android", "iOS"]:
		cast(power)
