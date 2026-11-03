extends Node3D
## Çizgi film tarzı karakter: gövde, kollar, bacaklar, baş, saç, yüz ve isim etiketi.
## Karakter +Z yönüne bakar. Görünüm bir sözlükle verilir:
## Alanlar ve seçenekleri avatar_data.gd içinde (ten, saç modeli ve rengi, göz, tişört, pantolon, aksesuar).

const MapBuilder = preload("res://scripts/map_builder.gd")
const AvatarData = preload("res://scripts/avatar_data.gd")

const HEAD_Y := 1.97

var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var head: Node3D
var label: Label3D

var skin_mat: StandardMaterial3D
var body_mat: StandardMaterial3D
var hair_mat: StandardMaterial3D
var eye_mat: StandardMaterial3D
var pants_mat: StandardMaterial3D

var _hair_root: Node3D
var _acc_root: Node3D
var _style := ""
var _accessory := ""

var _phase := 0.0
var _amp := 0.0


func setup(look: Dictionary) -> void:
	skin_mat = MapBuilder.mat(Color.WHITE, 0.75)
	body_mat = MapBuilder.mat(Color.WHITE, 0.8)
	hair_mat = MapBuilder.mat(Color.WHITE, 0.55)
	eye_mat = MapBuilder.mat(Color.WHITE, 0.4)
	pants_mat = MapBuilder.mat(Color.WHITE, 0.85)
	var pants := pants_mat
	var shoes := MapBuilder.mat(Color("2a2a35"))
	var dark := MapBuilder.mat(Color("2b2233"), 0.4)
	var white := MapBuilder.mat(Color.WHITE, 0.3)
	var cheek := MapBuilder.mat(Color("ff9fb0"), 0.9)

	leg_l = _limb(Vector3(-0.15, 0.62, 0), _capsule(0.13, 0.58), pants, -0.26)
	leg_r = _limb(Vector3(0.15, 0.62, 0), _capsule(0.13, 0.58), pants, -0.26)
	for leg in [leg_l, leg_r]:
		var shoe := _mesh(leg, MapBuilder.sphere(0.15, 12, 8), shoes, Vector3(0, -0.53, 0.05))
		shoe.scale = Vector3(1.0, 0.6, 1.35)

	var torso := _mesh(self, _capsule(0.3, 1.02), body_mat, Vector3(0, 1.08, 0))
	torso.scale = Vector3(1.0, 1.0, 0.82)

	arm_l = _limb(Vector3(-0.42, 1.36, 0), _capsule(0.095, 0.53), body_mat, -0.24)
	arm_r = _limb(Vector3(0.42, 1.36, 0), _capsule(0.095, 0.53), body_mat, -0.24)
	for arm in [arm_l, arm_r]:
		_mesh(arm, MapBuilder.sphere(0.105, 12, 8), skin_mat, Vector3(0, -0.5, 0))

	head = Node3D.new()
	head.position.y = HEAD_Y
	add_child(head)
	_mesh(head, MapBuilder.sphere(0.55, 32, 16), skin_mat, Vector3.ZERO)
	for side in [-1.0, 1.0]:
		var ear := _mesh(head, MapBuilder.sphere(0.11, 10, 6), skin_mat, Vector3(0.55 * side, -0.02, 0))
		ear.scale = Vector3(0.6, 1.0, 1.0)
		var eye := _mesh(head, MapBuilder.sphere(0.085, 12, 8), eye_mat, Vector3(0.19 * side, -0.02, 0.5))
		eye.scale = Vector3(1.0, 1.25, 0.6)
		_mesh(head, MapBuilder.sphere(0.03, 8, 6), white, Vector3(0.19 * side - 0.03, 0.04, 0.56))
		var ch := _mesh(head, MapBuilder.sphere(0.09, 10, 6), cheek, Vector3(0.32 * side, -0.14, 0.42))
		ch.scale = Vector3(1.0, 0.6, 0.35)
	var mouth := _mesh(head, MapBuilder.sphere(0.07, 10, 6), dark, Vector3(0, -0.19, 0.51))
	mouth.scale = Vector3(1.4, 0.5, 0.4)

	_hair_root = Node3D.new()
	head.add_child(_hair_root)
	_acc_root = Node3D.new()
	head.add_child(_acc_root)

	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.95
	label.font_size = 56
	label.pixel_size = 0.004
	label.outline_size = 14
	label.modulate = Color.WHITE
	label.outline_modulate = Color("1f2a44")
	add_child(label)

	apply_look(look)


func apply_look(raw: Dictionary) -> void:
	var look := AvatarData.sanitize(raw)
	skin_mat.albedo_color = Color(str(look["skin"]))
	body_mat.albedo_color = Color(str(look["body"]))
	hair_mat.albedo_color = Color(str(look["hair"]))
	eye_mat.albedo_color = Color(str(look["eyes"]))
	pants_mat.albedo_color = Color(str(look["pants"]))
	label.text = str(look["name"])
	if look["hair_style"] != _style:
		_style = str(look["hair_style"])
		_build_hair(_style)
	if look["accessory"] != _accessory:
		_accessory = str(look["accessory"])
		_build_accessory(_accessory)


func _build_hair(style: String) -> void:
	for child in _hair_root.get_children():
		child.queue_free()
	# Hepsinde ortak: üstte kâkül yapan kubbe, arkada başı saran küre.
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.59
	cap_mesh.height = 0.59
	cap_mesh.is_hemisphere = true
	cap_mesh.radial_segments = 32
	cap_mesh.rings = 10
	var cap := _mesh(_hair_root, cap_mesh, hair_mat, Vector3(0, 0.14, 0))
	cap.scale = Vector3(1.0, 0.8, 1.0)
	var back := _mesh(_hair_root, MapBuilder.sphere(0.58, 24, 12), hair_mat, Vector3(0, 0.02, -0.08))
	back.scale = Vector3(1.0, 1.0, 0.9)
	match style:
		"kisa":
			back.position = Vector3(0, 0.06, -0.06)
			back.scale = Vector3(0.98, 0.92, 0.88)
		"uzun":
			var panel := _mesh(_hair_root, _capsule(0.32, 1.1), hair_mat, Vector3(0, -0.45, -0.25))
			panel.scale = Vector3(1.5, 1.0, 0.6)
		"atkuyrugu":
			_mesh(_hair_root, MapBuilder.sphere(0.1, 10, 6), hair_mat, Vector3(0, 0.15, -0.6))
			var tail := _mesh(_hair_root, _capsule(0.14, 0.7), hair_mat, Vector3(0, -0.2, -0.68))
			tail.rotation.x = 0.3
		"topuz":
			_mesh(_hair_root, MapBuilder.sphere(0.24, 16, 10), hair_mat, Vector3(0, 0.62, -0.12))


func _build_accessory(kind: String) -> void:
	for child in _acc_root.get_children():
		child.queue_free()
	match kind:
		"gozluk":
			var frame := MapBuilder.mat(Color("1f2a44"), 0.3)
			for side in [-1.0, 1.0]:
				var ring := TorusMesh.new()
				ring.inner_radius = 0.075
				ring.outer_radius = 0.1
				var r := _mesh(_acc_root, ring, frame, Vector3(0.19 * side, -0.02, 0.56))
				r.rotation.x = PI / 2.0
			_mesh(_acc_root, MapBuilder.box(Vector3(0.12, 0.025, 0.025)), frame, Vector3(0, 0.0, 0.59))
		"sapka":
			var red := MapBuilder.mat(Color("e35d5b"), 0.7)
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 0.61
			crown_mesh.height = 0.61
			crown_mesh.is_hemisphere = true
			crown_mesh.radial_segments = 32
			crown_mesh.rings = 10
			var crown := _mesh(_acc_root, crown_mesh, red, Vector3(0, 0.16, 0))
			crown.scale = Vector3(1.0, 0.78, 1.0)
			var brim := _mesh(_acc_root, MapBuilder.cyl(0.34, 0.34, 0.04, 24), red, Vector3(0, 0.18, 0.5))
			brim.scale = Vector3(1.0, 1.0, 1.15)
		"fiyonk":
			var pink := MapBuilder.mat(Color("ff5fa2"), 0.6)
			for side in [-1.0, 1.0]:
				var lobe := _mesh(_acc_root, MapBuilder.sphere(0.12, 12, 8), pink, Vector3(0.34 + 0.11 * side, 0.5, 0.12))
				lobe.scale = Vector3(1.0, 0.7, 0.5)
			_mesh(_acc_root, MapBuilder.sphere(0.05, 8, 6), pink, Vector3(0.34, 0.5, 0.15))


## Yürüme ve zıplama hareketi. speed: metre/saniye.
func animate(speed: float, delta: float, in_air: bool) -> void:
	_amp += (minf(speed / 5.0, 1.0) - _amp) * minf(1.0, delta * 10.0)
	_phase += delta * speed * 2.3
	var s := sin(_phase) * 0.8 * _amp
	if in_air:
		leg_l.rotation.x = -0.5
		leg_r.rotation.x = 0.3
		arm_l.rotation.x = -2.4
		arm_r.rotation.x = -2.4
	else:
		leg_l.rotation.x = s
		leg_r.rotation.x = -s
		arm_l.rotation.x = -s * 0.85
		arm_r.rotation.x = s * 0.85
	head.position.y = HEAD_Y + absf(sin(_phase)) * 0.05 * _amp


# ---------- yardımcılar ----------

func _limb(pivot_pos: Vector3, m: Mesh, material: Material, offset_y: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	add_child(pivot)
	_mesh(pivot, m, material, Vector3(0, offset_y, 0))
	return pivot


func _mesh(parent: Node3D, m: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 16
	m.rings = 6
	return m
