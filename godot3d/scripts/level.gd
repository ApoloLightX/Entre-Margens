extends Node3D
## New phase: an organic, wind-carved margin outside Iqaluit.
## The layout uses three short routes that reconnect before the final guardian.

signal objective_changed(text:String)
signal area_changed(text:String)
signal completed

const ENEMY = preload("res://scripts/enemy.gd")
const SHELTER_MESH = preload("res://assets/models/shelter.obj")
const BEACON_MESH = preload("res://assets/models/beacon.obj")

var player:CharacterBody3D
var beacons:Array = []
var active_count := 0
var boss_spawned := false
var boss_alive := false
var gate:Node3D
var ice_material:ShaderMaterial
var snow_material:ShaderMaterial
var rock_material:StandardMaterial3D
var warm_material:StandardMaterial3D
var metal_material:StandardMaterial3D

func setup(value:CharacterBody3D):
	player = value
	_build_materials()
	_build_world()
	_spawn_encounters()
	emit_signal("area_changed", "MARGEM DE IQALUIT · FENDA AZUL")
	emit_signal("objective_changed", "Desperte os três Marcos de Vigília")

func _build_materials():
	ice_material = ShaderMaterial.new()
	ice_material.shader = load("res://shaders/ice.gdshader")
	snow_material = ShaderMaterial.new()
	snow_material.shader = load("res://shaders/snow.gdshader")

	rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color("#20303a")
	rock_material.roughness = 0.86

	warm_material = StandardMaterial3D.new()
	warm_material.albedo_color = Color("#d4934f")
	warm_material.emission_enabled = true
	warm_material.emission = Color("#ffad54") * 1.6
	warm_material.roughness = 0.3

	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color("#25353a")
	metal_material.metallic = 0.62
	metal_material.roughness = 0.42

func _build_world():
	_floor()
	_sky_ribbons()
	# A central ice mass blocks the straight sightline and forces a fork.
	_ice_cluster(Vector3(0,0,-24), Vector3(9,9,8), 9)
	_ice_cluster(Vector3(-40,0,-46), Vector3(14,12,9), 12)
	_ice_cluster(Vector3(42,0,-50), Vector3(15,13,10), 12)
	_ice_cluster(Vector3(-6,0,-90), Vector3(16,16,12), 14)
	_ice_cluster(Vector3(38,0,-90), Vector3(15,15,12), 12)
	_ice_cluster(Vector3(-42,0,-92), Vector3(15,15,12), 12)

	# Edge cliffs.
	for z in range(8):
		_ice_cluster(Vector3(-57,0,6-z*15), Vector3(10,8+(z%3)*3,9), 6)
		_ice_cluster(Vector3(57,0,2-z*15), Vector3(10,9+((z+1)%3)*3,9), 6)

	# Human shelter cluster: warm, low and offset from the combat routes.
	_shelter(Vector3(-25,0,-12), Color("#7b4540"))
	_shelter(Vector3(-34,0,-19), Color("#3d6270"))
	_shelter(Vector3(29,0,-17), Color("#6b5d38"))
	_watch_post(Vector3(18,0,-31))
	_watch_post(Vector3(-17,0,-49))

	# Three routes: left shelter, right blue fissure, high central ridge.
	_path_strip([Vector3(0,0.03,8),Vector3(-9,0.03,-7),Vector3(-21,0.03,-23),Vector3(-25,0.03,-39)])
	_path_strip([Vector3(0,0.03,8),Vector3(10,0.03,-8),Vector3(23,0.03,-25),Vector3(27,0.03,-46)])
	_path_strip([Vector3(-2,0.03,-28),Vector3(-3,0.03,-43),Vector3(0,0.03,-62)])

	_beacon(Vector3(-27,0,-40), "MARCO DO ABRIGO")
	_beacon(Vector3(28,0,-47), "MARCO DA FENDA")
	_beacon(Vector3(0,0,-64), "MARCO DO VENTO")

	gate = Node3D.new()
	gate.name = "IceGate"
	gate.position = Vector3(0,0,-73)
	add_child(gate)
	_static_box(gate, Vector3(0,2.3,0), Vector3(10,4.6,1.5), ice_material)
	for i in range(7):
		var shard = CylinderMesh.new()
		shard.height = 4.0 + (i%3)*0.9
		shard.top_radius = 0.0
		shard.bottom_radius = 0.42
		shard.radial_segments = 6
		_mesh(gate, shard, ice_material, Vector3(-4.5+i*1.5,2.1,0), Vector3(0,0,-8+i*2), Vector3.ONE)

	# Final bowl, deliberately wider than the approach.
	_path_strip([Vector3(0,0.03,-74),Vector3(0,0.03,-84),Vector3(0,0.03,-94)], 8.5)
	for i in range(8):
		var a = i*TAU/8.0
		_rock(Vector3(cos(a)*14,0,-91+sin(a)*10), Vector3(3.0,2.2,2.5))

func _floor():
	var floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(122,122)
	plane.subdivide_width = 30
	plane.subdivide_depth = 30
	floor_mesh.mesh = plane
	floor_mesh.material_override = snow_material
	floor_mesh.position = Vector3(0,0, -42)
	add_child(floor_mesh)

	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(0,-0.35,-42)
	var shape_node = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(122,0.7,122)
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func _sky_ribbons():
	for i in range(3):
		var ribbon = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(74,18)
		ribbon.mesh = plane
		var mat = ShaderMaterial.new()
		mat.shader = load("res://shaders/aurora.gdshader")
		mat.set_shader_parameter("alpha", 0.10 + i*0.035)
		ribbon.material_override = mat
		ribbon.position = Vector3(-18+i*18,23+i*2,-58-i*7)
		ribbon.rotation_degrees = Vector3(90,-16+i*14,0)
		add_child(ribbon)

func _path_strip(points:Array, width:float=5.2):
	for i in range(points.size()-1):
		var a:Vector3 = points[i]
		var b:Vector3 = points[i+1]
		var mid = (a+b)*0.5
		var length = a.distance_to(b)
		var plate = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(width,0.08,length)
		plate.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("#244958")
		mat.roughness = 0.32
		mat.metallic = 0.04
		plate.material_override = mat
		plate.position = mid
		add_child(plate)
		plate.look_at(b,Vector3.UP)

func _beacon(pos:Vector3, label:String):
	var root = Node3D.new()
	root.name = label
	root.position = pos
	add_child(root)
	var model = MeshInstance3D.new()
	model.name = "AuthoredBeacon"
	model.mesh = BEACON_MESH
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(model)
	var glow = OmniLight3D.new()
	glow.light_color = Color("#ffb462")
	glow.light_energy = 0.62
	glow.omni_range = 5.0
	glow.position = Vector3(0,3.0,0)
	root.add_child(glow)
	beacons.append({"node":root,"pos":pos,"active":false,"label":label})

func _shelter(pos:Vector3, _wall_color:Color):
	var root = Node3D.new()
	root.position = pos
	add_child(root)
	var model = MeshInstance3D.new()
	model.name = "AuthoredShelter"
	model.mesh = SHELTER_MESH
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(model)

	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = Vector3(0,1.25,0)
	root.add_child(body)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(6.3,2.5,4.55)
	col.shape = shape
	body.add_child(col)

	var warm = OmniLight3D.new()
	warm.light_color = Color("#ffad5f")
	warm.light_energy = 1.65
	warm.omni_range = 8.0
	warm.position = Vector3(0,1.65,-2.7)
	root.add_child(warm)

func _watch_post(pos:Vector3):
	var root = Node3D.new()
	root.position = pos
	add_child(root)
	for x in [-1.1,1.1]:
		var pole = CylinderMesh.new()
		pole.height = 4.8
		pole.top_radius = 0.08
		pole.bottom_radius = 0.11
		pole.radial_segments = 6
		_mesh(root,pole,metal_material,Vector3(x,2.4,0),Vector3.ZERO,Vector3.ONE)
	var beam = BoxMesh.new()
	beam.size = Vector3(2.7,0.18,0.18)
	_mesh(root,beam,metal_material,Vector3(0,4.5,0),Vector3.ZERO,Vector3.ONE)
	var lamp = BoxMesh.new()
	lamp.size = Vector3(0.38,0.3,0.28)
	_mesh(root,lamp,warm_material,Vector3(0,4.2,-0.2),Vector3.ZERO,Vector3.ONE)

func _ice_cluster(center:Vector3, spread:Vector3, count:int):
	for i in range(count):
		var a = i*2.399
		var r = 0.32 + float((i*37)%100)/100.0*0.68
		var p = center + Vector3(cos(a)*spread.x*r,0,sin(a)*spread.z*r)
		var h = 2.3 + float((i*53)%100)/100.0*spread.y
		var shard = CylinderMesh.new()
		shard.height = h
		shard.top_radius = 0.0
		shard.bottom_radius = 0.52 + (i%4)*0.17
		shard.radial_segments = 6
		var node = MeshInstance3D.new()
		node.mesh = shard
		node.material_override = ice_material
		node.position = p + Vector3(0,h*0.5,0)
		node.rotation_degrees = Vector3((i%5-2)*4,(i*41)%360,(i%3-1)*4)
		add_child(node)

func _rock(pos:Vector3, scale_value:Vector3):
	var mesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 5
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = rock_material
	node.position = pos + Vector3(0,scale_value.y*0.5,0)
	node.scale = scale_value
	add_child(node)

func _static_box(parent:Node3D, pos:Vector3, size:Vector3, material:Material):
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = pos
	parent.add_child(body)
	var mesh_node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = material
	body.add_child(mesh_node)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

func _mesh(parent:Node3D, mesh:Mesh, material:Material, pos:Vector3, rot_deg:Vector3, scale_value:Vector3):
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot_deg
	node.scale = scale_value
	parent.add_child(node)
	return node

func _spawn_encounters():
	_spawn_group(Vector3(-21,0,-31),["husk","husk"])
	_spawn_group(Vector3(-30,0,-44),["husk","shardling"])
	_spawn_group(Vector3(20,0,-32),["husk","shardling"])
	_spawn_group(Vector3(31,0,-50),["husk","husk","shardling"])
	_spawn_group(Vector3(0,0,-54),["husk","shardling","husk"])

func _spawn_group(center:Vector3, kinds:Array):
	for i in range(kinds.size()):
		var enemy = ENEMY.new()
		enemy.setup(player, kinds[i])
		add_child(enemy)
		enemy.global_position = center + Vector3((i-kinds.size()/2.0)*2.1,0.05,(i%2)*1.8)
		enemy.died.connect(_on_enemy_died)

func _process(_delta):
	if player == null:
		return
	var nearest = _nearest_inactive_beacon()
	if nearest != null:
		var distance = player.global_position.distance_to(nearest.pos)
		if distance < 4.0:
			if _enemy_near(nearest.pos,10.0):
				emit_signal("objective_changed", "Proteja o %s · elimine os ecos próximos" % nearest.label)
			else:
				emit_signal("objective_changed", "Interaja para despertar o %s" % nearest.label)
				if player.consume_interact():
					_activate_beacon(nearest)
	elif active_count < 3:
		emit_signal("objective_changed", "Desperte os três Marcos de Vigília · %d/3" % active_count)

func _nearest_inactive_beacon():
	var best = null
	var best_distance = INF
	for b in beacons:
		if b.active:
			continue
		var d = player.global_position.distance_to(b.pos)
		if d < best_distance:
			best = b
			best_distance = d
	return best

func _enemy_near(pos:Vector3, radius:float)->bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(pos) <= radius:
			return true
	return false

func _activate_beacon(beacon:Dictionary):
	if beacon.active:
		return
	beacon.active = true
	active_count += 1
	var root:Node3D = beacon.node
	for child in root.get_children():
		if child is MeshInstance3D:
			child.scale *= 1.08
	if active_count >= 3:
		_open_final_route()
	else:
		emit_signal("objective_changed", "Marcos despertos · %d/3" % active_count)

func _open_final_route():
	if gate != null:
		gate.queue_free()
		gate = null
	emit_signal("area_changed", "FENDA AZUL · CÂMARA DO VENTO")
	emit_signal("objective_changed", "Atravesse a fenda e enfrente o Guardião")
	_spawn_boss()

func _spawn_boss():
	if boss_spawned:
		return
	boss_spawned = true
	boss_alive = true
	var boss = ENEMY.new()
	boss.setup(player,"warden")
	add_child(boss)
	boss.global_position = Vector3(0,0.05,-92)
	boss.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy, kind:String):
	if kind == "warden":
		boss_alive = false
		emit_signal("area_changed", "MARGEM DE IQALUIT · SILÊNCIO")
		emit_signal("objective_changed", "A Fenda Azul estabilizou. Vertical slice concluída.")
		emit_signal("completed")
