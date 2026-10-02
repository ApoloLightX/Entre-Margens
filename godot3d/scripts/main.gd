extends Node3D
## Experimental 3D vertical slice: Iqaluit warrior with an ice arm.
## The approved 2D campaign remains untouched in ../godot on this branch.

const PLAYER = preload("res://scripts/player.gd")
const LEVEL = preload("res://scripts/level.gd")
const HUD = preload("res://scripts/hud.gd")
const WORLD_VFX = preload("res://scripts/world_vfx.gd")

var player:CharacterBody3D
var level:Node3D
var hud:Control
var ambience:Node3D

func _ready():
	_setup_environment()
	level = LEVEL.new()
	level.name = "MargemDeIqaluit"
	add_child(level)

	player = PLAYER.new()
	player.name = "GuerreiroDeIqaluit"
	add_child(player)
	player.global_position = Vector3(0, 1.05, 12)

	hud = HUD.new()
	hud.name = "HUD"
	add_child(hud)

	level.setup(player)
	hud.bind(player, level)
	player.set_hud(hud)

	ambience = WORLD_VFX.new()
	ambience.name = "AtmosphereVFX"
	add_child(ambience)
	ambience.setup(player)

func _setup_environment():
	var world = WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#4f7181")
	env.ambient_light_energy = 0.58
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.fog_enabled = true
	env.fog_light_color = Color("#6c8793")
	env.fog_light_energy = 0.42
	env.fog_density = 0.011
	env.fog_sky_affect = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.94

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#071722")
	sky_mat.sky_horizon_color = Color("#173645")
	sky_mat.ground_bottom_color = Color("#071116")
	sky_mat.ground_horizon_color = Color("#24414a")
	sky_mat.sun_angle_max = 18.0
	sky_mat.sun_curve = 0.08
	sky.sky_material = sky_mat
	env.sky = sky
	world.environment = env
	add_child(world)

	var moon = DirectionalLight3D.new()
	moon.name = "MoonKey"
	moon.light_color = Color("#b9e8ff")
	moon.light_energy = 1.18
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 78.0
	moon.rotation_degrees = Vector3(-52, -34, 0)
	add_child(moon)

	var rim = DirectionalLight3D.new()
	rim.name = "ColdRim"
	rim.light_color = Color("#4fa7c5")
	rim.light_energy = 0.36
	rim.rotation_degrees = Vector3(-24, 148, 0)
	add_child(rim)
