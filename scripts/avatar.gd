extends Node3D
## Çizgi film tarzı karakter: gövde, kollar, bacaklar, baş, saç, yüz ve isim etiketi.
## Karakter +Z yönüne bakar. Görünüm bir sözlükle verilir:
## {"name": "Beren", "skin": "#f2c9a5", "hair": "#5a3825", "body": "#ff7aa8"}
## 2. aşamada bu sözlük avatar editöründen ve fotoğraf analizinden gelecek.

const MapBuilder = preload("res://scripts/map_builder.gd")

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

var _phase := 0.0
var _amp := 0.0


func setup(look: Dictionary) -> void:
	skin_mat = MapBuilder.mat(Color.WHITE, 0.75)
	body_mat = MapBuilder.mat(Color.WHITE, 0.8)
	hair_mat = MapBuilder.mat(Color.WHITE, 0.55)
	var pants := MapBuilder.mat(Color("34426b"))
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
		var eye := _mesh(head, MapBuilder.sphere(0.085, 12, 8), dark, Vector3(0.19 * side, -0.02, 0.5))
		eye.scale = Vector3(1.0, 1.25, 0.6)
		_mesh(head, MapBuilder.sphere(0.03, 8, 6), white, Vector3(0.19 * side - 0.03, 0.04, 0.56))
		var ch := _mesh(head, MapBuilder.sphere(0.09, 10, 6), cheek, Vector3(0.32 * side, -0.14, 0.42))
		ch.scale = Vector3(1.0, 0.6, 0.35)
	var mouth := _mesh(head, MapBuilder.sphere(0.07, 10, 6), dark, Vector3(0, -0.19, 0.51))
	mouth.scale = Vector3(1.4, 0.5, 0.4)

	# Saç: üstte kâkül yapan bir kubbe, arkada başı saran bir küre.
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.59
	cap_mesh.height = 0.59
	cap_mesh.is_hemisphere = true
	cap_mesh.radial_segments = 32
	cap_mesh.rings = 10
	var cap := _mesh(head, cap_mesh, hair_mat, Vector3(0, 0.14, 0))
	cap.scale = Vector3(1.0, 0.8, 1.0)
	var back := _mesh(head, MapBuilder.sphere(0.58, 24, 12), hair_mat, Vector3(0, 0.02, -0.08))
	back.scale = Vector3(1.0, 1.0, 0.9)

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


func apply_look(look: Dictionary) -> void:
	skin_mat.albedo_color = Color(str(look.get("skin", "#f2c9a5")))
	body_mat.albedo_color = Color(str(look.get("body", "#ff7aa8")))
	hair_mat.albedo_color = Color(str(look.get("hair", "#5a3825")))
	label.text = str(look.get("name", "Ben"))


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
