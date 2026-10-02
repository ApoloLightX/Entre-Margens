extends CharacterBody3D
## Organic ice-bound enemies for the Iqaluit vertical slice.

signal died(enemy, kind:String)

var target:CharacterBody3D
var kind := "husk"
var health := 72.0
var max_health := 72.0
var speed := 3.2
var attack_cd := 0.6
var windup := 0.0
var pending_attack := false
var frozen := 0.0
var slow_factor := 1.0
var slow_time := 0.0
var ice_material:ShaderMaterial
const HUSK_MESH = preload("res://assets/models/husk.obj")
const SHARDLING_MESH = preload("res://assets/models/shardling.obj")
const WARDEN_MESH = preload("res://assets/models/warden.obj")

func setup(player:CharacterBody3D, enemy_kind:String):
	target = player
	kind = enemy_kind
	match kind:
		"shardling":
			health = 58.0
			speed = 2.65
		"warden":
			health = 440.0
			speed = 2.35
		_:
			health = 82.0
			speed = 3.45
	max_health = health

func _ready():
	add_to_group("enemy")
	collision_layer = 2
	collision_mask = 1
	ice_material = ShaderMaterial.new()
	ice_material.shader = load("res://shaders/ice.gdshader")
	_build_body()

func _build_body():
	var shape_node = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.46 if kind != "warden" else 0.80
	capsule.height = 1.55 if kind != "warden" else 2.55
	shape_node.shape = capsule
	shape_node.position.y = 0.78 if kind != "warden" else 1.28
	add_child(shape_node)

	var model = MeshInstance3D.new()
	model.name = "Authored_" + kind
	model.mesh = WARDEN_MESH if kind == "warden" else (SHARDLING_MESH if kind == "shardling" else HUSK_MESH)
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	model.scale = Vector3.ONE * (1.0 if kind != "warden" else 1.08)
	add_child(model)

	var core_light = OmniLight3D.new()
	core_light.light_color = Color("#ff9f4f") if kind == "warden" else Color("#6fdef2")
	core_light.light_energy = 0.55 if kind == "warden" else 0.22
	core_light.omni_range = 4.2 if kind == "warden" else 2.1
	core_light.position = Vector3(0,1.55 if kind == "warden" else 0.92,-0.72 if kind == "warden" else -0.36)
	add_child(core_light)

func _part(mesh:Mesh, material:Material, pos:Vector3, rot_deg:Vector3, scale_value:Vector3):
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot_deg
	node.scale = scale_value
	add_child(node)

func _physics_process(delta):
	if target == null or not is_instance_valid(target):
		return
	attack_cd = maxf(0.0, attack_cd-delta)
	frozen = maxf(0.0, frozen-delta)
	slow_time = maxf(0.0, slow_time-delta)
	if slow_time <= 0:
		slow_factor = 1.0

	if pending_attack:
		windup -= delta
		velocity.x = move_toward(velocity.x, 0.0, delta*15.0)
		velocity.z = move_toward(velocity.z, 0.0, delta*15.0)
		if windup <= 0:
			pending_attack = false
			_resolve_attack()
			attack_cd = 2.25 if kind == "shardling" else (1.6 if kind == "warden" else 1.05)
		move_and_slide()
		return

	if frozen > 0:
		velocity.x = move_toward(velocity.x, 0.0, delta*12.0)
		velocity.z = move_toward(velocity.z, 0.0, delta*12.0)
		move_and_slide()
		return

	var to = target.global_position - global_position
	to.y = 0
	var dist = to.length()
	var attack_range = 12.5 if kind == "shardling" else (2.6 if kind == "warden" else 1.85)
	if dist <= attack_range and attack_cd <= 0:
		pending_attack = true
		windup = 0.62 if kind == "shardling" else (0.72 if kind == "warden" else 0.38)
		return

	if dist > (8.0 if kind == "shardling" else attack_range*0.82):
		var dir = to.normalized()
		velocity.x = dir.x * speed * slow_factor
		velocity.z = dir.z * speed * slow_factor
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta*10.0)
		velocity.z = move_toward(velocity.z, 0.0, delta*10.0)
	move_and_slide()

func _resolve_attack():
	if target == null or not is_instance_valid(target):
		return
	var dist = global_position.distance_to(target.global_position)
	if kind == "shardling":
		if dist <= 14.0:
			target.take_damage(10.0)
			_flash_beam(target.global_position + Vector3.UP*1.0)
	elif kind == "warden":
		if dist <= 3.1:
			target.take_damage(24.0)
	else:
		if dist <= 2.25:
			target.take_damage(13.0)

func _flash_beam(end:Vector3):
	var beam = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var origin = global_position + Vector3.UP*1.0
	var d = origin.distance_to(end)
	mesh.size = Vector3(0.055,0.055,d)
	beam.mesh = mesh
	beam.material_override = ice_material
	beam.global_position = (origin+end)*0.5
	get_tree().current_scene.add_child(beam)
	beam.look_at(end, Vector3.UP)
	get_tree().create_timer(0.12).timeout.connect(beam.queue_free)

func take_damage(amount:float, _source:String=""):
	health -= amount
	if health <= 0:
		_die()

func apply_slow(factor:float, duration:float):
	slow_factor = clampf(factor,0.2,1.0)
	slow_time = maxf(slow_time,duration)

func freeze_for(duration:float):
	frozen = maxf(frozen,duration)

func _die():
	emit_signal("died", self, kind)
	remove_from_group("enemy")
	_spawn_break()
	queue_free()

func _spawn_break():
	var root = Node3D.new()
	root.global_position = global_position + Vector3.UP*0.6
	get_tree().current_scene.add_child(root)
	for i in range(10 if kind != "warden" else 18):
		var shard = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.height = 0.25 + (i%4)*0.08
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.035 + (i%3)*0.012
		mesh.radial_segments = 5
		shard.mesh = mesh
		shard.material_override = ice_material
		var a = i*TAU/float(10 if kind != "warden" else 18)
		shard.position = Vector3(cos(a), 0.2+(i%3)*0.1, sin(a))*0.55
		root.add_child(shard)
	get_tree().create_timer(0.42).timeout.connect(root.queue_free)
