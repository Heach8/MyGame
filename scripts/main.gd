extends Node3D
## Oyunun giriş noktası: ışığı, zemini, haritayı, oyuncuyu, arkadaşları ve dokunmatik kontrolleri kurar.

const MapBuilder = preload("res://scripts/map_builder.gd")
const PlayerScript = preload("res://scripts/player.gd")
const NpcScript = preload("res://scripts/npc.gd")
const CameraRigScript = preload("res://scripts/camera_rig.gd")
const TouchControlsScript = preload("res://scripts/touch_controls.gd")

const ISLAND_RADIUS := 36.0
const START_MAP := "res://data/maps/baslangic.json"

var player  # oyuncu (player.gd)
var rig  # kamera (camera_rig.gd)


func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_ground()

	var map_root := Node3D.new()
	map_root.name = "Harita"
	add_child(map_root)
	MapBuilder.load_map_file(map_root, START_MAP)

	player = PlayerScript.new()
	player.name = "Oyuncu"
	player.look = {"name": "Beren", "skin": "#f2c9a5", "hair": "#5a3825", "body": "#ff7aa8"}
	add_child(player)
	player.global_position = Vector3(0, 0.2, 2)

	var friends: Array = [
		{"name": "Ela", "skin": "#ffe0c4", "hair": "#e8c06a", "body": "#b48cff"},
		{"name": "Deniz", "skin": "#a86f4c", "hair": "#2a1d18", "body": "#6ad08a"},
		{"name": "Mira", "skin": "#d9a27a", "hair": "#d8483c", "body": "#ffc23d"},
	]
	for i in friends.size():
		var npc = NpcScript.new()
		npc.look = friends[i]
		npc.island_radius = ISLAND_RADIUS - 6.0
		add_child(npc)
		npc.global_position = Vector3(-6.0 + i * 6.0, 0.2, -1.0)

	rig = CameraRigScript.new()
	rig.name = "Kamera"
	rig.target = player
	add_child(rig)
	player.camera_rig = rig

	var ui := CanvasLayer.new()
	ui.name = "Arayuz"
	add_child(ui)
	ui.add_child(_make_title())
	var touch = TouchControlsScript.new()
	touch.player = player
	ui.add_child(touch)


func _setup_input() -> void:
	_add_action("ileri", [KEY_W, KEY_UP])
	_add_action("geri", [KEY_S, KEY_DOWN])
	_add_action("sol", [KEY_A, KEY_LEFT])
	_add_action("sag", [KEY_D, KEY_RIGHT])
	_add_action("zipla", [KEY_SPACE])
	_add_action("kos", [KEY_SHIFT])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("4fa8e6")
	sky_mat.sky_horizon_color = Color("c4e8fb")
	sky_mat.ground_horizon_color = Color("c4e8fb")
	sky_mat.ground_bottom_color = Color("2b8fc4")
	sky_mat.sun_angle_max = 20.0

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color("d6f0fc")
	env.fog_density = 0.004

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Gunes"
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_color = Color("fff0d4")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _build_ground() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(600, 600)
	water.mesh = plane
	water.material_override = MapBuilder.mat(Color("37a6d8"), 0.15)
	water.position.y = -0.45
	add_child(water)

	var sand := MeshInstance3D.new()
	sand.mesh = MapBuilder.cyl(ISLAND_RADIUS + 3.0, ISLAND_RADIUS + 5.0, 0.8, 72)
	sand.material_override = MapBuilder.mat(Color("f3dca4"))
	sand.position.y = -0.47
	add_child(sand)

	var grass := MeshInstance3D.new()
	grass.mesh = MapBuilder.cyl(ISLAND_RADIUS, ISLAND_RADIUS + 0.8, 0.6, 72)
	grass.material_override = MapBuilder.mat(Color("6cc26a"), 0.95)
	grass.position.y = -0.3
	add_child(grass)

	var ground := StaticBody3D.new()
	ground.name = "Zemin"
	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = ISLAND_RADIUS + 3.0
	cyl_shape.height = 0.6
	shape.shape = cyl_shape
	shape.position.y = -0.3
	ground.add_child(shape)
	add_child(ground)


func _make_title() -> Control:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffaf0")
	style.set_corner_radius_all(14)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "Berenin Adası"
	label.add_theme_color_override("font_color", Color("1f2a44"))
	label.add_theme_font_size_override("font_size", 26)
	panel.add_child(label)
	return panel
