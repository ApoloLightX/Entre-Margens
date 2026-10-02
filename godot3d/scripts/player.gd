extends CharacterBody3D
## First-person warrior from Iqaluit. The right arm itself is the weapon.

signal stats_changed(health:float, focus:float)
signal cooldowns_changed(values:Dictionary)

const MAX_HEALTH := 140.0
const MAX_FOCUS := 100.0
const SPEED := 7.2
const DASH_SPEED := 19.0
const GRAVITY := 24.0
const LOOK_SENS := 0.00225

var health := MAX_HEALTH
var focus := MAX_FOCUS
var pitch := -0.06
var touch_move := Vector2.ZERO
var dash_time := 0.0
var dash_dir := Vector3.ZERO
var interact_buffer := false
var attack_cd := 0.0
var spear_cd := 0.0
var wall_cd := 0.0
var pulse_cd := 0.0
var dash_cd := 0.0
var spawn_point := Vector3(0, 1.05, 12)
var hud

var camera:Camera3D
var arm_root:Node3D
var arm_visual:Node3D
var arm_clock := 0.0
var arm_home := Vector3(0.48, -0.43, -0.70)
const ICE_ARM_MESH = preload("res://assets/models/ice_arm.obj")
var ice_material:ShaderMaterial
var dark_ice_material:StandardMaterial3D

func _ready():
	collision_layer = 1
	collision_mask = 1
	var body_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	body_shape.shape = capsule
	body_shape.position.y = 0.9
	add_child(body_shape)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 1.62, 0)
	camera.fov = 76.0
	camera.current = true
	add_child(camera)

	_build_ice_arm()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_emit_stats()

func set_hud(value):
	hud = value

func _build_ice_arm():
	ice_material = ShaderMaterial.new()
	ice_material.shader = load("res://shaders/ice.gdshader")

	arm_root = Node3D.new()
	arm_root.name = "IceArmRoot"
	arm_root.position = arm_home
	arm_root.rotation_degrees = Vector3(-6, -8, -4)
	camera.add_child(arm_root)

	arm_visual = Node3D.new()
	arm_visual.name = "IceArmVisual"
	arm_root.add_child(arm_visual)

	var model = MeshInstance3D.new()
	model.name = "AuthoredIceArm"
	model.mesh = ICE_ARM_MESH
	model.scale = Vector3(0.88,0.88,0.88)
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	arm_visual.add_child(model)

	var arm_light = OmniLight3D.new()
	arm_light.name = "IceArmBounce"
	arm_light.light_color = Color("#7fdff5")
	arm_light.light_energy = 0.32
	arm_light.omni_range = 2.1
	arm_light.position = Vector3(0.0,0.04,-0.62)
	arm_visual.add_child(arm_light)

func _add_arm_piece(mesh:Mesh, material:Material, pos:Vector3, rot_deg:Vector3, scale_value:Vector3):
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot_deg
	node.scale = scale_value
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	arm_root.add_child(node)

func _physics_process(delta):
	arm_clock += delta
	if arm_visual != null and dash_time <= 0.0:
		var planar_speed = Vector2(velocity.x, velocity.z).length()
		var step = sin(arm_clock * (8.0 + planar_speed * 0.45)) * minf(1.0, planar_speed / SPEED)
		arm_visual.position = Vector3(step * 0.012, -abs(step) * 0.010 + sin(arm_clock*1.7)*0.006, 0)
		arm_visual.rotation_degrees = Vector3(step*0.55, 0, -step*0.75)
	attack_cd = maxf(0.0, attack_cd - delta)
	spear_cd = maxf(0.0, spear_cd - delta)
	wall_cd = maxf(0.0, wall_cd - delta)
	pulse_cd = maxf(0.0, pulse_cd - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	focus = minf(MAX_FOCUS, focus + delta * 5.0)

	var move_input = touch_move
	if move_input.length() < 0.05:
		move_input = Vector2(
			float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		)
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	var local = Vector3(move_input.x, 0, move_input.y)
	var desired = (transform.basis * local)
	desired.y = 0
	if desired.length() > 0.01:
		desired = desired.normalized()

	if dash_time > 0:
		dash_time -= delta
		velocity.x = dash_dir.x * DASH_SPEED
		velocity.z = dash_dir.z * DASH_SPEED
	else:
		velocity.x = move_toward(velocity.x, desired.x * SPEED, delta * 34.0)
		velocity.z = move_toward(velocity.z, desired.z * SPEED, delta * 34.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.4

	move_and_slide()
	_emit_stats()
	emit_signal("cooldowns_changed", {
		"garra": attack_cd,
		"lanca": spear_cd,
		"muralha": wall_cd,
		"pulso": pulse_cd,
		"passo": dash_cd
	})

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			strike()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q: cast_spear()
			KEY_E: cast_wall()
			KEY_R: cast_pulse()
			KEY_SHIFT: dash()
			KEY_F: request_interact()
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_look(delta:Vector2):
	rotation.y -= delta.x * LOOK_SENS
	pitch = clampf(pitch - delta.y * LOOK_SENS, -1.18, 1.08)
	camera.rotation.x = pitch

func add_touch_look(delta:Vector2):
	_apply_look(delta)

func set_touch_move(value:Vector2):
	touch_move = value.limit_length(1.0)

func request_interact():
	interact_buffer = true

func consume_interact()->bool:
	var value = interact_buffer
	interact_buffer = false
	return value

func forward()->Vector3:
	return -camera.global_transform.basis.z.normalized()

func strike():
	if attack_cd > 0:
		return
	attack_cd = 0.43
	_arm_anim(Vector3(0.0, 0.025, -0.28), Vector3(-18, 4, -14), 0.075, 0.13)
	var target = _best_enemy(3.05, 0.34)
	if target != null:
		target.take_damage(24.0, "garra")
		focus = minf(MAX_FOCUS, focus + 9.0)
		_spawn_impact(target.global_position + Vector3.UP * 0.7)

func cast_spear():
	if spear_cd > 0 or focus < 22.0:
		return
	spear_cd = 2.15
	focus -= 22.0
	_arm_anim(Vector3(-0.03, 0.05, -0.17), Vector3(-28, 0, -5), 0.10, 0.18)
	var origin = camera.global_position + forward() * 0.8
	var target = _best_enemy(29.0, 0.72)
	var end = origin + forward() * 26.0
	if target != null:
		end = target.global_position + Vector3.UP * 0.75
		target.take_damage(48.0, "lanca")
		target.apply_slow(0.55, 1.8)
	_spawn_beam(origin, end)

func cast_wall():
	if wall_cd > 0 or focus < 28.0:
		return
	wall_cd = 5.2
	focus -= 28.0
	_arm_anim(Vector3(-0.06, -0.03, -0.12), Vector3(18, 0, 10), 0.10, 0.16)
	var root = Node3D.new()
	root.name = "MuralhaDeGelo"
	root.global_position = global_position + forward() * 3.8
	root.rotation.y = rotation.y
	get_tree().current_scene.add_child(root)

	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	root.add_child(body)
	var shape_node = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(5.1, 2.8, 0.48)
	shape_node.shape = shape
	shape_node.position.y = 1.35
	body.add_child(shape_node)

	for i in range(7):
		var shard = MeshInstance3D.new()
		var box = BoxMesh.new()
		var height = 1.5 + (3-abs(3-i)) * 0.32
		box.size = Vector3(0.72, height, 0.42 + (i%2)*0.12)
		shard.mesh = box
		shard.material_override = ice_material
		shard.position = Vector3(-2.25 + i * 0.75, height * 0.5, (i%2) * 0.08)
		shard.rotation_degrees.z = -7 + i * 2.2
		root.add_child(shard)
	get_tree().create_timer(4.6).timeout.connect(root.queue_free)

func cast_pulse():
	if pulse_cd > 0 or focus < 44.0:
		return
	pulse_cd = 8.4
	focus -= 44.0
	_arm_anim(Vector3(0.0, -0.09, -0.22), Vector3(26, 0, -18), 0.12, 0.22)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			var d = global_position.distance_to(enemy.global_position)
			if d <= 8.2:
				enemy.take_damage(32.0 + (8.2-d) * 1.8, "pulso")
				enemy.freeze_for(1.35)
	_spawn_pulse()

func dash():
	if dash_cd > 0:
		return
	dash_cd = 1.0
	var input = touch_move
	if input.length() < 0.1:
		input = Vector2(
			float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		)
	var local = Vector3(input.x, 0, input.y)
	dash_dir = (transform.basis * local).normalized() if local.length() > 0.1 else forward()
	dash_dir.y = 0
	dash_time = 0.17

func take_damage(amount:float):
	health = maxf(0.0, health - amount)
	if hud != null and hud.has_method("flash_damage"):
		hud.flash_damage()
	if health <= 0.0:
		_respawn()
	_emit_stats()

func _respawn():
	health = MAX_HEALTH
	focus = MAX_FOCUS
	global_position = spawn_point
	velocity = Vector3.ZERO

func _best_enemy(max_range:float, min_dot:float):
	var best = null
	var best_dist = max_range + 1.0
	var fwd = forward()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var to = enemy.global_position + Vector3.UP * 0.65 - camera.global_position
		var dist = to.length()
		if dist <= max_range and dist < best_dist and to.normalized().dot(fwd) >= min_dot:
			best = enemy
			best_dist = dist
	return best

func _arm_anim(offset:Vector3, rot_offset:Vector3, out_time:float, back_time:float):
	if arm_root == null:
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(arm_root, "position", arm_home + offset, out_time)
	tween.parallel().tween_property(arm_root, "rotation_degrees", Vector3(-8, -7, -5) + rot_offset, out_time)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(arm_root, "position", arm_home, back_time)
	tween.parallel().tween_property(arm_root, "rotation_degrees", Vector3(-8, -7, -5), back_time)

func _spawn_beam(origin:Vector3, end:Vector3):
	var beam = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var distance = origin.distance_to(end)
	mesh.size = Vector3(0.12, 0.12, distance)
	beam.mesh = mesh
	beam.material_override = ice_material
	beam.global_position = (origin + end) * 0.5
	get_tree().current_scene.add_child(beam)
	beam.look_at(end, Vector3.UP)
	get_tree().create_timer(0.16).timeout.connect(beam.queue_free)

func _spawn_impact(pos:Vector3):
	var root = Node3D.new()
	root.global_position = pos
	get_tree().current_scene.add_child(root)
	for i in range(6):
		var shard = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.height = 0.34 + i * 0.035
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.045
		mesh.radial_segments = 5
		shard.mesh = mesh
		shard.material_override = ice_material
		var a = i * TAU / 6.0
		shard.position = Vector3(cos(a), 0.1, sin(a)) * 0.28
		shard.rotation = Vector3(cos(a) * 0.55, -a, sin(a) * 0.55)
		root.add_child(shard)
	get_tree().create_timer(0.34).timeout.connect(root.queue_free)

func _spawn_pulse():
	var root = Node3D.new()
	root.global_position = global_position
	get_tree().current_scene.add_child(root)
	for i in range(24):
		var shard = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.height = 0.56 + (i%4) * 0.09
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.055
		mesh.radial_segments = 5
		shard.mesh = mesh
		shard.material_override = ice_material
		var a = i * TAU / 24.0
		var radius = 3.5 + (i%3) * 0.45
		shard.position = Vector3(cos(a) * radius, 0.2, sin(a) * radius)
		shard.rotation = Vector3(0.18, -a, 0.35)
		root.add_child(shard)
	var tween = root.create_tween()
	root.scale = Vector3(0.15, 0.15, 0.15)
	tween.tween_property(root, "scale", Vector3.ONE, 0.22)
	tween.tween_interval(0.18)
	tween.tween_callback(root.queue_free)

func _emit_stats():
	emit_signal("stats_changed", health, focus)
