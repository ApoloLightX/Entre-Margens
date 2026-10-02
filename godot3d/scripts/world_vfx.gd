extends Node3D
## Lightweight mobile-friendly atmosphere for the Iqaluit 3D slice.
var target:Node3D
var snow:GPUParticles3D
var crystals:GPUParticles3D

func setup(follow_target:Node3D):
	target = follow_target
	_make_snow()
	_make_crystal_drift()

func _process(_delta):
	if target != null and is_instance_valid(target):
		global_position = Vector3(target.global_position.x, target.global_position.y + 6.0, target.global_position.z - 4.0)

func _make_snow():
	snow = GPUParticles3D.new()
	snow.name = "SnowField"
	snow.amount = 160
	snow.lifetime = 4.5
	snow.randomness = 0.55
	snow.visibility_aabb = AABB(Vector3(-22,-10,-22),Vector3(44,22,44))
	var process = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(19,7,19)
	process.direction = Vector3(0.20,-1.0,0.10)
	process.spread = 18.0
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 4.6
	process.gravity = Vector3(0,-0.65,0)
	process.scale_min = 0.045
	process.scale_max = 0.11
	process.color = Color(0.83,0.94,1.0,0.72)
	snow.process_material = process
	var quad = QuadMesh.new()
	quad.size = Vector2(0.045,0.045)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.86,0.96,1.0,0.82)
	quad.material = mat
	snow.draw_pass_1 = quad
	add_child(snow)

func _make_crystal_drift():
	crystals = GPUParticles3D.new()
	crystals.name = "IceDust"
	crystals.amount = 46
	crystals.lifetime = 3.2
	crystals.randomness = 0.7
	crystals.visibility_aabb = AABB(Vector3(-16,-8,-16),Vector3(32,18,32))
	var process = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(14,4,14)
	process.direction = Vector3(0.65,-0.22,0.0)
	process.spread = 36.0
	process.initial_velocity_min = 0.7
	process.initial_velocity_max = 2.1
	process.gravity = Vector3(0,-0.18,0)
	process.scale_min = 0.025
	process.scale_max = 0.065
	process.color = Color(0.37,0.76,0.92,0.38)
	crystals.process_material = process
	var quad = QuadMesh.new()
	quad.size = Vector2(0.028,0.10)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.42,0.82,0.96,0.46)
	quad.material = mat
	crystals.draw_pass_1 = quad
	add_child(crystals)
