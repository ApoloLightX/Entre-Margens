extends Node3D
const Rules = preload("res://scripts/rules.gd")
var player: CharacterBody3D
var camera: Camera3D
var arm: Node3D
var hud: Label
var health_bar: ProgressBar
var focus_bar: ProgressBar
var objective: Label
var model_cache: Dictionary = {}
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
var hit_flash := 0.0
var damage_flash := 0.0
var last_health := 100.0
var crosshair: Label
var damage_overlay: ColorRect
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
	ice = material(Color("76a8bf"), 0.36, 0.0)
	ice.metallic = 0.12
	stone = material(Color("233646"))
	snow = material(Color("c6dce1"))
	metal = material(Color("334248"), 0.4)
	amber = material(Color("ffb66a"), 0.4, 0.5)
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
func art_material(original: Material) -> Material:
	if original == null: return stone
	var title := original.resource_name
	if title == "Cliff_stone": return stone
	if title == "Snow_cap": return snow
	var m: StandardMaterial3D = original.duplicate()
	m.albedo_color = m.albedo_color.darkened(0.15)
	if title == "Timber":
		var noise := FastNoiseLite.new()
		noise.frequency = 0.06
		noise.fractal_octaves = 3
		var texture := NoiseTexture2D.new()
		texture.width = 256
		texture.height = 256
		texture.noise = noise
		var ramp := Gradient.new()
		ramp.set_color(0,Color("191d21"))
		ramp.set_color(1,Color("68675e"))
		texture.color_ramp = ramp
		m.albedo_texture = texture
		m.albedo_color = Color.WHITE
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.2,2,3)
	if title == "Heat_glass":
		m.albedo_color = Color("c68546")
		m.emission = Color("ffa658")
		m.emission_energy_multiplier = 0.45
	if title.begins_with("Ice_"):
		m.albedo_color = Color("588eaa") if title == "Ice_blue" else Color("9ec2d0")
		m.metallic = 0.35
		m.roughness = 0.28
	return m
func collect_meshes(node: Node3D, transform: Transform3D, groups: Dictionary):
	var current := transform*node.transform
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var mat: Material = node.get_active_material(surface)
			if not groups.has(mat): groups[mat] = []
			groups[mat].append([node.mesh,surface,current])
	for child in node.get_children():
		if child is Node3D: collect_meshes(child,current,groups)
func asset(name: String, parent: Node3D, pos: Vector3, size := Vector3.ONE) -> Node3D:
	if not model_cache.has(name):
		var source: Node3D = load("res://assets/models/%s.glb" % name).instantiate()
		var groups: Dictionary = {}
		collect_meshes(source,Transform3D.IDENTITY,groups)
		var combined := ArrayMesh.new()
		for mat in groups:
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for part in groups[mat]: surface.append_from(part[0],part[1],part[2])
			surface.set_material(art_material(mat))
			surface.commit(combined)
		model_cache[name] = combined
		source.free()
	var model := MeshInstance3D.new()
	model.mesh = model_cache[name]
	parent.add_child(model)
	model.position = pos
	model.scale = size
	return model
func lamp_at(pos: Vector3):
	asset("lantern",self,pos)
	var lamp := OmniLight3D.new()
	lamp.position = pos+Vector3(0,0.3,0)
	lamp.light_color = Color("ffb875")
	lamp.light_energy = 1.0
	lamp.omni_range = 7
	add_child(lamp)
func world():
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("071526")
	sky_mat.sky_horizon_color = Color("263f54")
	sky_mat.ground_bottom_color = Color("102536")
	sky_mat.ground_horizon_color = Color("263f54")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9abfd4")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("395b71")
	env.fog_density = 0.012
	env.fog_sky_affect = 0.2
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32,-32,0)
	sun.light_color = Color("b6d9f0")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	box(self,Vector3(0,-1,-30),Vector3(120,2,160),snow,true)
	build_terrain()
	for i in range(32):
		var z := 8.0-i*2.4
		asset("boardwalk",self,Vector3(0,0.15,z))
		var floor_mesh := box(self,Vector3(0,0.04,z),Vector3(6.8,0.2,2.4),stone,true)
		floor_mesh.visible = false
		if i % 4 == 0:
			for side in [-1,1]: lamp_at(Vector3(side*3.25,1.4,z))
	# Layered cliffs frame three distinct spaces without closing the horizon.
	for i in range(56):
		var side := -1 if i % 2 == 0 else 1
		var z := 18.0-float(i/2)*4.3
		var x: float = side*(13+sin(z*0.08)*4+seed_rng.randf_range(0,9))
		var h := seed_rng.randf_range(2.5,6.0)
		var cliff := asset("cliff",self,Vector3(x,1,z),Vector3(3,h,3))
		cliff.rotation.y = seed_rng.randf_range(-PI,PI)
		if i % 2 == 0:
			asset("crystals",self,Vector3(side*seed_rng.randf_range(5,10),0,z),Vector3.ONE*seed_rng.randf_range(0.6,1.3))
	for z in [-18,-46,-67]:
		asset("gate",self,Vector3(0,0,z))
		for side in [-1,1]:
			lamp_at(Vector3(side*4.1,2.7,z+0.65))
			var pillar := box(self,Vector3(side*4.5,2,z),Vector3(1,4,1),stone,true)
			pillar.visible = false
	for p in [Vector3(-9,0,3),Vector3(9,0,-9),Vector3(-10,0,-42),Vector3(0,0,-77)]:
		asset("shelter",self,p)
		lamp_at(p+Vector3(0,1.3,3))
		var wall := box(self,p+Vector3(0,1.8,0),Vector3(7,3.6,5),stone,true)
		wall.visible = false
	for i in range(16):
		var side := -1 if i % 2 == 0 else 1
		asset("supplies",self,Vector3(side*seed_rng.randf_range(4.2,7),0,-i*4.2),Vector3.ONE*seed_rng.randf_range(0.7,1.1)).rotation.y = seed_rng.randf_range(-1,1)
	asset("sled",self,Vector3(-5,0,5))
	asset("sled",self,Vector3(6,0,-39)).rotation.y = 0.8
	for i in range(7):
		spawn_enemy(Vector3(seed_rng.randf_range(-2.1,2.1),0.25,-9-i*8),i%3)
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
	asset("ice_arm",arm,Vector3.ZERO)
	var flakes := CPUParticles3D.new()
	flakes.amount = 130
	flakes.lifetime = 9
	flakes.preprocess = 9
	flakes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	flakes.emission_box_extents = Vector3(14,8,20)
	flakes.direction = Vector3(-0.2,-1,0)
	flakes.gravity = Vector3(-0.1,-0.15,0)
	flakes.initial_velocity_min = 0.3
	flakes.initial_velocity_max = 0.7
	flakes.scale_amount_min = 0.025
	flakes.scale_amount_max = 0.055
	var quad := SphereMesh.new()
	quad.radius = 0.5
	quad.height = 1
	quad.radial_segments = 6
	quad.rings = 4
	var snowflake := material(Color(0.7,0.83,0.91,0.55))
	snowflake.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	snowflake.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	snowflake.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = snowflake
	flakes.mesh = quad
	player.add_child(flakes)
	flakes.position.y = 4
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
	var body := asset("sentinel",n,Vector3.ZERO,Vector3.ONE*0.8)
	body.name = "Visual"
	if kind == 1:
		box(n,Vector3(-0.7,1,0.5),Vector3(0.6,1.2,0.18),metal)
	if kind == 2:
		asset("crystals",n,Vector3(0,1.7,0),Vector3.ONE*0.18)
	var health_label := Label3D.new()
	health_label.name = "Health"
	health_label.position = Vector3(0,2.5,0)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 32
	health_label.pixel_size = 0.01
	health_label.modulate = Color("e6bd87")
	health_label.no_depth_test = false
	n.add_child(health_label)
	enemies.append({"node":n,"hp":80.0 if kind == 1 else 55.0,"kind":kind,"timer":2.0,"slow":0.0,"flash":0.0})
func ui_style(color: Color, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = Color(0.65,0.8,0.85,0.3)
	style.set_border_width_all(1)
	style.content_margin_left = 0
	style.content_margin_right = 0
	return style
func label_at(parent: Control, text: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("e0e8e9"))
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.7))
	label.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(label)
	return label
func build_ui():
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud = label_at(root,"VIGOR   100      FOCO   100",Vector2(28,24),16)
	for i in range(2):
		var bar := ProgressBar.new()
		bar.position = Vector2(28,54+i*16)
		bar.size = Vector2(238,9)
		bar.show_percentage = false
		bar.add_theme_font_size_override("font_size",1)
		bar.value = 100
		bar.add_theme_stylebox_override("background",ui_style(Color(0.02,0.05,0.07,0.8),3))
		bar.add_theme_stylebox_override("fill",ui_style(Color("b96757") if i == 0 else Color("7abacf"),3))
		root.add_child(bar)
		bar.set_deferred("size",Vector2(238,8))
		if i == 0: health_bar = bar
		else: focus_bar = bar
	objective = label_at(root,"PASSO DA MARÉ FRIA",Vector2.ZERO,16)
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	objective.offset_left = -330
	objective.offset_top = 25
	objective.offset_right = -75
	objective.offset_bottom = 85
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(0.6,0.08,0.03,0)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_overlay)
	var cross := label_at(root,"+",Vector2.ZERO,24)
	crosshair = cross
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.offset_left = -7
	cross.offset_top = -16
	cross.offset_right = 7
	cross.offset_bottom = 16
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var actions := Control.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	root.add_child(actions)
	var entries := [["Soco","soco",Vector2(-132,-142)],["Lança","lanca",Vector2(-238,-236)],["Fratura","onda",Vector2(-342,-142)],["Guarda","guarda",Vector2(-238,-142)],["Esquiva","esquiva",Vector2(-132,-52)]]
	for data in entries:
		var button := Button.new()
		button.text = data[0]
		button.position = data[2]
		button.size = Vector2(96,76 if data[1] != "esquiva" else 44)
		button.add_theme_font_size_override("font_size",16)
		button.add_theme_stylebox_override("normal",ui_style(Color(0.035,0.09,0.12,0.73),22))
		button.add_theme_stylebox_override("pressed",ui_style(Color(0.24,0.5,0.59,0.95),22))
		button.pressed.connect(action_button.bind(data[1]))
		actions.add_child(button)
		touch_actions.append({"button":button,"power":data[1],"title":data[0]})
	var joystick := Panel.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(44,-176)
	joystick.size = Vector2(132,132)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.add_theme_stylebox_override("panel",ui_style(Color(0.05,0.12,0.16,0.28),66))
	root.add_child(joystick)
	label_at(joystick,"+",Vector2(48,45),28).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(-64,23)
	pause.size = Vector2(42,42)
	pause.pressed.connect(pause_game)
	root.add_child(pause)
	menu = ColorRect.new()
	menu.color = Color(0.02,0.05,0.075,0.78)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var column := VBoxContainer.new()
	column.position = Vector2(70,120)
	column.add_theme_constant_override("separation",22)
	menu.add_child(column)
	var overline := Label.new()
	overline.text = "IQALUIT  /  PASSO DA MARÉ FRIA"
	overline.add_theme_color_override("font_color",Color("aac4cd"))
	overline.add_theme_font_size_override("font_size",16)
	column.add_child(overline)
	var title := Label.new()
	title.text = "ENTRE\nMARGENS"
	title.add_theme_font_size_override("font_size",62)
	column.add_child(title)
	var desc := Label.new()
	desc.text = "O vento levou as vozes da passagem.\nAinda há luz no abrigo."
	desc.add_theme_font_size_override("font_size",20)
	column.add_child(desc)
	var start := Button.new()
	start.text = "ATRAVESSAR"
	start.custom_minimum_size = Vector2(340,60)
	start.add_theme_stylebox_override("normal",ui_style(Color("a6bfc5"),4))
	start.add_theme_color_override("font_color",Color("10232e"))
	start.pressed.connect(func():
		active = true
		menu.hide()
		start.text = "CONTINUAR"
		if not DisplayServer.is_touchscreen_available(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	column.add_child(start)
	var help := Label.new()
	help.text = "WASD mover · mouse olhar · clique lançar\nQ soco · E fratura · R guarda · Shift esquiva\n\nNo celular, arraste à esquerda para andar\ne à direita para olhar. Toque nos poderes para atacar."
	help.add_theme_font_size_override("font_size",14)
	column.add_child(help)
func pause_game():
	active = false
	move_touch = Vector2.ZERO
	move_finger = -1
	look_finger = -1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
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
			KEY_ESCAPE: pause_game()
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
				hit_enemy(e,22)
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
					hit_enemy(e,38,false)
					e.slow = 4.0
			for i in range(8):
				var p := player.position-player.global_basis.z*(2.5+i*1.2)
				var n := asset("crystals",self,Vector3(p.x,0.2,p.z),Vector3.ONE*(0.23+i*0.014))
				effects.append({"node":n,"life":1.4})
		"guarda":
			guard = 3.0
			var guard_mat := ice.duplicate()
			guard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			guard_mat.albedo_color = Color(0.3,0.7,0.85,0.15)
			var n := box(camera,Vector3(0,0,-1.4),Vector3(1.5,1.5,0.04),guard_mat)
			effects.append({"node":n,"life":3.0})
func hit_enemy(enemy: Dictionary, amount: float, shieldable := true):
	var to_player: Vector3 = (player.position-enemy.node.position).normalized()
	var blocked: bool = shieldable and enemy.kind == 1 and enemy.node.global_basis.z.dot(to_player) > 0.4
	enemy.hp -= amount*(0.4 if blocked else 1.0)
	enemy.flash = 0.16
	hit_flash = 0.12
	sound(360 if blocked else 110,0.09)
func end_run(success: bool):
	pause_game()
	for child in menu.get_children(): child.queue_free()
	var column := VBoxContainer.new()
	column.position = Vector2(70,180)
	column.add_theme_constant_override("separation",26)
	menu.add_child(column)
	var title := Label.new()
	title.text = "A PASSAGEM ESTÁ SEGURA" if success else "O GELO CEDEU"
	title.add_theme_font_size_override("font_size",38)
	column.add_child(title)
	var desc := Label.new()
	desc.text = "Há alguém esperando por você no abrigo." if success else "Use a guarda contra ataques de frente.\nA esquiva atravessa o momento do impacto."
	column.add_child(desc)
	var retry := Button.new()
	retry.text = "JOGAR NOVAMENTE" if success else "TENTAR NOVAMENTE"
	retry.custom_minimum_size = Vector2(330,64)
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	column.add_child(retry)
func pulse(pos: Vector3, radius: float):
	for i in range(8):
		var n := crystal(self,pos,0.035+radius*0.02,0.12+radius*0.08)
		n.rotation = Vector3(seed_rng.randf_range(-PI,PI),0,seed_rng.randf_range(-PI,PI))
		var velocity := Vector3(seed_rng.randf_range(-1,1),seed_rng.randf_range(0.3,1.4),seed_rng.randf_range(-1,1))*3
		effects.append({"node":n,"life":0.45,"velocity":velocity})
func _physics_process(dt):
	if not active: return
	elapsed += dt
	hit_flash = max(0.0,hit_flash-dt)
	damage_flash = max(0.0,damage_flash-dt)
	if health < last_health: damage_flash = 0.28
	last_health = health
	damage_overlay.color.a = damage_flash*0.7
	crosshair.text = "×" if hit_flash > 0 else "+"
	camera.fov = lerpf(camera.fov,84.0 if dodge_time > 0 else 78.0,dt*12)
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
	arm.rotation.z = -0.17+sin(elapsed*8)*0.035*input.length()
	arm.position.y = -0.4+sin(elapsed*8)*0.014*input.length()
	for i in range(enemies.size()-1,-1,-1):
		var e = enemies[i]
		if e.hp <= 0:
			pulse(e.node.position+Vector3.UP,0.8)
			e.node.queue_free()
			enemies.remove_at(i)
			kills += 1
			continue
		var offset: Vector3 = player.position-e.node.position
		if offset.length() > 0.1: e.node.rotation.y = atan2(offset.x,offset.z)
		offset.y = 0
		e.slow = max(0.0,e.slow-dt)
		e.flash = max(0.0,e.flash-dt)
		var visual: Node3D = e.node.get_node("Visual")
		visual.position.y = sin(elapsed*5+float(i))*0.025
		visual.rotation.z = sin(elapsed*18)*0.035 if e.timer < 0.6 else 0.0
		var nameplate: Label3D = e.node.get_node("Health")
		nameplate.text = "!" if e.timer < 0.6 and offset.length() < 22 else ("%d" % e.hp if e.flash > 0 or e.hp < (80 if e.kind == 1 else 55) else "")
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
				if hit.collider == e.node: hit_enemy(e,28)
			b.life = 0
			pulse(hit.position,0.2)
		for e in enemies:
			if b.life > 0 and Geometry3D.get_closest_point_to_segment(e.node.position+Vector3.UP,from,to).distance_to(e.node.position+Vector3.UP) < 0.8:
				hit_enemy(e,28)
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
		if effects[i].has("velocity"):
			effects[i].node.position += effects[i].velocity*dt
			effects[i].velocity.y -= dt*8
			effects[i].node.visible = effects[i].node.global_position.distance_to(camera.global_position) > 0.8
		if effects[i].life <= 0:
			effects[i].node.queue_free()
			effects.remove_at(i)
	if health <= 0:
		end_run(false)
		return
	if player.position.z < -69 and enemies.is_empty() and not won:
		won = true
		end_run(true)
	hud.text = "VIGOR  %d     FOCO  %d" % [health,focus]
	health_bar.value = health
	focus_bar.value = focus
	objective.text = "PASSO DA MARÉ FRIA\n%s" % ("Passagem protegida" if won else "Abrigo · %dm   /   %d de 7" % [abs(player.position.z+70),kills])
	for action in touch_actions:
		var remaining: float = cooldowns.get(action.power,melee_cooldown if action.power == "soco" else dodge_cooldown)
		action.button.text = action.title+("\n%.1fs" % remaining if remaining > 0 else "")

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
