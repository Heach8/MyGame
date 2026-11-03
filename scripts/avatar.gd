extends Node3D
## Yarı gerçekçi karakter: insan oranlarında gövde, dirsek ve dizden bükülen kollar ve bacaklar,
## eller, boyun, burun, kaş, göz bebeği, göz kapağı ve dudaklı bir yüz, isim etiketi.
## Bütün parçalar kodla üretilir (dönel yüzeyler), dışarıdan model dosyası gerekmez.
## Karakter +Z yönüne bakar. Görünüm bir sözlükle verilir; alanlar avatar_data.gd içinde.

const MapBuilder = preload("res://scripts/map_builder.gd")
const AvatarData = preload("res://scripts/avatar_data.gd")

# Ölçüler (metre). Toplam boy yaklaşık 2.35; oyuncunun çarpışma kapsülü 2.4.
const HIP_Y := 1.12
const HEAD_Y := 0.98  # kalçaya göre baş merkezinin yüksekliği
const THIGH := 0.5
const SHIN := 0.46
const UPPER_ARM := 0.36
const FOREARM := 0.32
const HEAD_W := 0.215  # başın yarı genişliği

var hips: Node3D  # üst gövde, kollar ve baş buna bağlı; yürürken hafifçe iner kalkar
var chest: Node3D
var head: Node3D
var leg_l: Node3D
var leg_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var label: Label3D

var skin_mat: StandardMaterial3D
var body_mat: StandardMaterial3D
var hair_mat: StandardMaterial3D
var eye_mat: StandardMaterial3D
var pants_mat: StandardMaterial3D
var brow_mat: StandardMaterial3D

var _lids: Array = []
var _hair_root: Node3D
var _acc_root: Node3D
var _style := ""
var _accessory := ""

var _phase := 0.0
var _amp := 0.0
var _time := 0.0
var _blink_at := 2.0


func setup(look: Dictionary) -> void:
	_time = randf() * 10.0
	_blink_at = _time + randf_range(1.0, 4.0)
	skin_mat = _soft_mat(Color.WHITE, 0.6, 0.08)
	body_mat = _soft_mat(Color.WHITE, 0.92, 0.05)
	hair_mat = _soft_mat(Color.WHITE, 0.5, 0.15)
	brow_mat = _soft_mat(Color.WHITE, 0.6, 0.0)
	eye_mat = MapBuilder.mat(Color.WHITE, 0.25)
	pants_mat = _soft_mat(Color.WHITE, 0.95, 0.05)
	var shoe_mat := _soft_mat(Color("f4f1ea"), 0.7, 0.1)
	var sole_mat := MapBuilder.mat(Color("3a3a46"), 0.9)

	hips = Node3D.new()
	hips.position.y = HIP_Y
	add_child(hips)

	# --- bacaklar: uyluk, diz, baldır, ayakkabı ---
	var legs := []
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(0.1 * side, 0.0, 0.0)
		hips.add_child(leg)
		_mesh(leg, _lathe([[0.04, 0.1], [0.0, 0.112], [-0.2, 0.098], [-0.42, 0.078], [-THIGH - 0.03, 0.068]], 18), pants_mat, Vector3.ZERO)
		var knee := Node3D.new()
		knee.position.y = -THIGH
		leg.add_child(knee)
		_mesh(knee, MapBuilder.sphere(0.071, 14, 8), pants_mat, Vector3.ZERO)
		_mesh(knee, _lathe([[0.02, 0.07], [-0.12, 0.072], [-0.3, 0.06], [-SHIN + 0.04, 0.05], [-SHIN, 0.05]], 16), pants_mat, Vector3.ZERO)
		var foot := Node3D.new()
		foot.position = Vector3(0, -SHIN - 0.07, 0.05)
		knee.add_child(foot)
		var shoe := _mesh(foot, MapBuilder.sphere(0.085, 16, 10), shoe_mat, Vector3(0, 0.0, 0.0))
		shoe.scale = Vector3(0.95, 0.75, 1.75)
		var sole := _mesh(foot, MapBuilder.sphere(0.085, 14, 6), sole_mat, Vector3(0, -0.045, 0.0))
		sole.scale = Vector3(0.98, 0.22, 1.78)
		legs.append([leg, knee])
	leg_l = legs[0][0]
	knee_l = legs[0][1]
	leg_r = legs[1][0]
	knee_r = legs[1][1]

	# --- gövde: kalça (pantolon) ve göğüs (tişört) ---
	var pelvis := _mesh(hips, _lathe([[-0.06, 0.15], [0.02, 0.19], [0.12, 0.18], [0.2, 0.16]], 22), pants_mat, Vector3.ZERO)
	pelvis.scale = Vector3(1.0, 1.0, 0.72)
	chest = Node3D.new()
	chest.position.y = 0.16
	hips.add_child(chest)
	var shirt := _mesh(chest, _lathe([[0.0, 0.165], [0.12, 0.16], [0.3, 0.185], [0.42, 0.2], [0.49, 0.175], [0.53, 0.1], [0.555, 0.055]], 22), body_mat, Vector3.ZERO)
	shirt.scale = Vector3(1.0, 1.0, 0.66)
	_mesh(chest, _lathe([[0.5, 0.052], [0.74, 0.046]], 12), skin_mat, Vector3.ZERO)

	# --- kollar: omuz, kol, dirsek, ön kol, el ---
	var arms := []
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(0.235 * side, 0.46, 0.0)
		chest.add_child(arm)
		_mesh(arm, MapBuilder.sphere(0.068, 14, 8), body_mat, Vector3.ZERO)
		_mesh(arm, _lathe([[0.02, 0.064], [-0.16, 0.062], [-0.2, 0.058]], 14), body_mat, Vector3.ZERO)  # kısa kol
		_mesh(arm, _lathe([[-0.15, 0.05], [-0.3, 0.044], [-UPPER_ARM, 0.042]], 14), skin_mat, Vector3.ZERO)
		var elbow := Node3D.new()
		elbow.position.y = -UPPER_ARM
		arm.add_child(elbow)
		_mesh(elbow, _lathe([[0.02, 0.042], [-0.12, 0.042], [-FOREARM + 0.02, 0.033], [-FOREARM, 0.032]], 14), skin_mat, Vector3.ZERO)
		var hand := _mesh(elbow, MapBuilder.sphere(0.05, 12, 8), skin_mat, Vector3(0, -FOREARM - 0.045, 0.0))
		hand.scale = Vector3(0.62, 1.15, 1.0)
		var thumb := _mesh(elbow, MapBuilder.sphere(0.02, 8, 6), skin_mat, Vector3(0, -FOREARM - 0.03, 0.04))
		thumb.scale = Vector3(1.0, 1.6, 1.0)
		arm.rotation.z = 0.1 * side
		arms.append([arm, elbow])
	arm_l = arms[0][0]
	elbow_l = arms[0][1]
	arm_r = arms[1][0]
	elbow_r = arms[1][1]

	# --- baş ---
	head = Node3D.new()
	head.position.y = HEAD_Y - chest.position.y
	chest.add_child(head)
	_build_face()

	_hair_root = Node3D.new()
	head.add_child(_hair_root)
	_acc_root = Node3D.new()
	head.add_child(_acc_root)

	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.8
	label.font_size = 56
	label.pixel_size = 0.004
	label.outline_size = 14
	label.modulate = Color.WHITE
	label.outline_modulate = Color("1f2a44")
	add_child(label)

	apply_look(look)


func _build_face() -> void:
	# Kafatası ve çene: yumurta biçimli dönel yüzey, yüz tarafı hafif öne çıkık.
	var skull := _mesh(head, _lathe([
		[-0.27, 0.0], [-0.266, 0.035], [-0.255, 0.07], [-0.235, 0.105], [-0.205, 0.14], [-0.165, 0.171],
		[-0.1, 0.198], [-0.05, 0.208], [0.0, 0.213], [0.05, 0.215], [0.1, 0.208], [0.14, 0.195],
		[0.18, 0.174], [0.215, 0.145], [0.24, 0.11], [0.258, 0.07], [0.268, 0.035], [0.27, 0.0]], 36), skin_mat, Vector3.ZERO)
	skull.scale = Vector3(1.0, 1.0, 1.06)
	var blush := _soft_mat(Color(0.93, 0.55, 0.55, 0.28), 0.8, 0.0)
	blush.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for side in [-1.0, 1.0]:
		var ear := _mesh(head, MapBuilder.sphere(0.045, 10, 8), skin_mat, Vector3(0.205 * side, -0.02, 0.01))
		ear.scale = Vector3(0.45, 1.0, 0.75)
		# Hafif yanak pembeliği
		var rosy := _mesh(head, MapBuilder.sphere(0.036, 12, 8), blush, Vector3(0.112 * side, -0.068, 0.168))
		rosy.scale = Vector3(1.3, 0.7, 0.3)
		rosy.rotation.y = 0.55 * side
		# Kaş kemeri: gözün üstüne hafif gölge düşürür
		var ridge := _mesh(head, _capsule_x(0.02, 0.085), skin_mat, Vector3(0.078 * side, 0.052, 0.19))
		ridge.rotation.z = PI / 2.0 - 0.1 * side
		ridge.scale = Vector3(1.0, 1.0, 0.75)

	var white := MapBuilder.mat(Color("fbfbf8"), 0.3)
	var lash_mat := MapBuilder.mat(Color("2a1c1c"), 0.6)
	var pupil := MapBuilder.mat(Color("15121a"), 0.2)
	var shine := MapBuilder.mat(Color.WHITE, 0.1)
	shine.emission_enabled = true
	shine.emission = Color.WHITE
	shine.emission_energy_multiplier = 0.6
	_lids.clear()
	for side in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(0.08 * side, 0.005, 0.186)
		head.add_child(eye)
		var ball := _mesh(eye, MapBuilder.sphere(0.044, 16, 10), white, Vector3.ZERO)
		ball.scale = Vector3(1.0, 0.86, 0.7)
		var iris := _mesh(eye, MapBuilder.sphere(0.027, 16, 8), eye_mat, Vector3(0, -0.002, 0.022))
		iris.scale = Vector3(1.0, 1.05, 0.45)
		var pup := _mesh(eye, MapBuilder.sphere(0.013, 10, 6), pupil, Vector3(0, -0.002, 0.03))
		pup.scale = Vector3(1.0, 1.0, 0.4)
		_mesh(eye, MapBuilder.sphere(0.0065, 6, 4), shine, Vector3(-0.009, 0.011, 0.034))
		# Kirpik çizgisi: gözün üst kenarında koyu, dışa doğru kalkan çizgi
		var lash := _mesh(eye, _capsule_x(0.0055, 0.082), lash_mat, Vector3(0.002 * side, 0.032, 0.014))
		lash.rotation = Vector3(0.35, 0, PI / 2.0 + 0.08 * side)
		var flick := _mesh(eye, _capsule_x(0.0045, 0.026), lash_mat, Vector3(0.043 * side, 0.034, 0.006))
		flick.rotation.z = PI / 2.0 - 0.55 * side
		var under := _mesh(eye, _capsule_x(0.003, 0.06), lash_mat, Vector3(0.003 * side, -0.031, 0.012))
		under.rotation = Vector3(-0.3, 0, PI / 2.0)
		under.transparency = 0.6
		_lids.append(eye)  # göz kırparken dikeyde kapanır
		# Kaş
		var brow := _mesh(head, _capsule_x(0.0145, 0.082), brow_mat, Vector3(0.082 * side, 0.078, 0.204))
		brow.rotation.z = PI / 2.0 - 0.14 * side
		brow.scale = Vector3(1.0, 1.0, 0.6)

	# Burun
	var nose := _mesh(head, MapBuilder.sphere(0.022, 12, 8), skin_mat, Vector3(0, -0.052, 0.226))
	nose.scale = Vector3(0.95, 0.85, 0.85)
	var bridge := _mesh(head, MapBuilder.sphere(0.016, 10, 6), skin_mat, Vector3(0, -0.015, 0.22))
	bridge.scale = Vector3(0.75, 2.4, 0.8)
	var nostril_mat := _soft_mat(Color(0.35, 0.2, 0.18, 0.55), 0.9, 0.0)
	nostril_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for side in [-1.0, 1.0]:
		var wing := _mesh(head, MapBuilder.sphere(0.0105, 10, 6), skin_mat, Vector3(0.017 * side, -0.059, 0.214))
		wing.scale = Vector3(1.0, 0.8, 0.8)
		var hole := _mesh(head, MapBuilder.sphere(0.0045, 8, 4), nostril_mat, Vector3(0.009 * side, -0.068, 0.224))
		hole.scale = Vector3(1.2, 0.5, 1.0)

	# Dudaklar
	var lip_mat := _soft_mat(Color("b95c5e"), 0.4, 0.0)
	for side in [-1.0, 1.0]:
		# Üst dudak iki kavisten oluşur (ortada hafif çukur)
		var upper := _mesh(head, _capsule_x(0.0085, 0.034), lip_mat, Vector3(0.013 * side, -0.117, 0.2))
		upper.rotation.z = PI / 2.0 + 0.18 * side
		upper.scale = Vector3(1.0, 1.0, 0.7)
	var lower := _mesh(head, _capsule_x(0.0115, 0.044), lip_mat, Vector3(0, -0.133, 0.196))
	lower.scale = Vector3(1.0, 1.0, 0.7)
	lower.rotation.z = PI / 2.0
	var line := _mesh(head, _capsule_x(0.0022, 0.05), MapBuilder.mat(Color("7a3f40"), 0.6), Vector3(0, -0.125, 0.204))
	line.rotation.z = PI / 2.0


func apply_look(raw: Dictionary) -> void:
	var look := AvatarData.sanitize(raw)
	skin_mat.albedo_color = Color(str(look["skin"]))
	body_mat.albedo_color = Color(str(look["body"]))
	hair_mat.albedo_color = Color(str(look["hair"]))
	brow_mat.albedo_color = Color(str(look["hair"])).darkened(0.35)
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
	# Ortak: başın üstünü saran, alnı açık bırakan kabuk ve başın arkasını örten kubbe.
	var shell := _mesh(_hair_root, _lathe([
		[0.105, 0.228], [0.14, 0.22], [0.18, 0.199], [0.215, 0.17], [0.245, 0.13], [0.27, 0.085], [0.285, 0.04], [0.29, 0.0]], 36, true), hair_mat, Vector3(0, 0.012, 0))
	shell.scale = Vector3(1.0, 1.0, 1.07)
	var dome := SphereMesh.new()
	dome.radius = 0.226
	dome.height = 0.226
	dome.is_hemisphere = true
	dome.radial_segments = 28
	dome.rings = 10
	var back_dome := _mesh(_hair_root, dome, hair_mat, Vector3(0, 0.03, -0.015))
	back_dome.rotation.x = -PI / 2.0
	back_dome.scale = Vector3(1.0, 1.12, 1.03)
	# Şakaklarda saç
	for side in [-1.0, 1.0]:
		var temple := _mesh(_hair_root, MapBuilder.sphere(0.07, 10, 8), hair_mat, Vector3(0.188 * side, 0.06, 0.04))
		temple.scale = Vector3(0.5, 1.4, 0.9)
	match style:
		"kisa":
			back_dome.scale = Vector3(0.98, 1.04, 0.92)
			back_dome.position.y = 0.06
			var nape := _mesh(_hair_root, MapBuilder.sphere(0.17, 14, 8), hair_mat, Vector3(0, -0.07, -0.1))
			nape.scale = Vector3(1.1, 0.7, 0.75)
		"uzun":
			var back := _mesh(_hair_root, _lathe([[0.12, 0.2], [0.0, 0.215], [-0.2, 0.2], [-0.38, 0.17], [-0.48, 0.11], [-0.52, 0.0]], 20), hair_mat, Vector3(0, 0.02, -0.08))
			back.scale = Vector3(1.05, 1.0, 0.55)
			for side in [-1.0, 1.0]:
				var lock := _mesh(_hair_root, _lathe([[0.05, 0.05], [-0.15, 0.055], [-0.3, 0.04], [-0.36, 0.0]], 12), hair_mat, Vector3(0.175 * side, -0.02, 0.02))
				lock.scale = Vector3(0.7, 1.0, 1.0)
		"atkuyrugu":
			var tie := _mesh(_hair_root, MapBuilder.sphere(0.06, 10, 6), hair_mat, Vector3(0, 0.12, -0.24))
			tie.scale = Vector3(1.0, 1.0, 0.8)
			var tail := Node3D.new()
			tail.position = Vector3(0, 0.12, -0.27)
			tail.rotation.x = 0.35
			_hair_root.add_child(tail)
			_mesh(tail, _lathe([[0.02, 0.05], [-0.08, 0.075], [-0.25, 0.06], [-0.4, 0.03], [-0.45, 0.0]], 14), hair_mat, Vector3.ZERO)
		"topuz":
			var bun := _mesh(_hair_root, MapBuilder.sphere(0.1, 16, 10), hair_mat, Vector3(0, 0.27, -0.1))
			bun.scale = Vector3(1.0, 0.85, 1.0)


func _build_accessory(kind: String) -> void:
	for child in _acc_root.get_children():
		child.queue_free()
	match kind:
		"gozluk":
			var frame := MapBuilder.mat(Color("1f2a44"), 0.3)
			for side in [-1.0, 1.0]:
				var ring := TorusMesh.new()
				ring.inner_radius = 0.046
				ring.outer_radius = 0.056
				ring.rings = 20
				var r := _mesh(_acc_root, ring, frame, Vector3(0.08 * side, 0.0, 0.208))
				r.rotation.x = PI / 2.0
				var arm := _mesh(_acc_root, MapBuilder.box(Vector3(0.008, 0.008, 0.2)), frame, Vector3(0.198 * side, 0.01, 0.11))
				arm.rotation.y = 0.05 * side
			_mesh(_acc_root, MapBuilder.box(Vector3(0.05, 0.01, 0.01)), frame, Vector3(0, 0.012, 0.22))
		"sapka":
			var red := _soft_mat(Color("e35d5b"), 0.8, 0.1)
			var crown := _mesh(_acc_root, _lathe([[0.0, 0.232], [0.1, 0.22], [0.17, 0.17], [0.215, 0.1], [0.23, 0.0]], 24, true), red, Vector3(0, 0.07, -0.01))
			crown.scale = Vector3(1.0, 1.0, 1.08)
			var brim := _mesh(_acc_root, MapBuilder.cyl(0.15, 0.15, 0.015, 24), red, Vector3(0, 0.085, 0.2))
			brim.scale = Vector3(1.05, 1.0, 0.9)
			brim.rotation.x = 0.12
		"fiyonk":
			var pink := _soft_mat(Color("ff5fa2"), 0.6, 0.1)
			var bow := Node3D.new()
			bow.position = Vector3(0.13, 0.2, 0.06)
			bow.rotation.z = -0.5
			_acc_root.add_child(bow)
			for side in [-1.0, 1.0]:
				var lobe := _mesh(bow, MapBuilder.sphere(0.055, 12, 8), pink, Vector3(0.05 * side, 0, 0))
				lobe.scale = Vector3(1.0, 0.7, 0.45)
			_mesh(bow, MapBuilder.sphere(0.025, 8, 6), pink, Vector3(0, 0, 0.01))


## Yürüme, koşma, zıplama ve durma hareketi. speed: metre/saniye.
func animate(speed: float, delta: float, in_air: bool) -> void:
	_time += delta
	_amp += (minf(speed / 5.0, 1.0) - _amp) * minf(1.0, delta * 8.0)
	_phase += delta * (2.0 + speed * 1.7)
	var s := sin(_phase)
	var c := cos(_phase)
	var a := _amp
	if in_air:
		_pose_limb(leg_l, knee_l, -0.6, 1.1, delta)
		_pose_limb(leg_r, knee_r, 0.15, 0.35, delta)
		_pose_limb(arm_l, elbow_l, -1.9, -0.4, delta)
		_pose_limb(arm_r, elbow_r, -1.9, -0.4, delta)
		hips.position.y = lerpf(hips.position.y, HIP_Y, minf(1.0, delta * 10.0))
	else:
		# Bacak öne giderken diz bükülür, yere basarken düzleşir.
		var swing := 0.62 * a
		_pose_limb(leg_l, knee_l, s * swing, maxf(0.0, -c) * 0.9 * a + 0.03, delta)
		_pose_limb(leg_r, knee_r, -s * swing, maxf(0.0, c) * 0.9 * a + 0.03, delta)
		# Kollar bacakların tersine sallanır, dirsek hafif bükük.
		var breathe := sin(_time * 1.6) * 0.03 * (1.0 - a)
		_pose_limb(arm_l, elbow_l, -s * 0.55 * a + breathe, -0.18 - 0.35 * a, delta)
		_pose_limb(arm_r, elbow_r, s * 0.55 * a + breathe, -0.18 - 0.35 * a, delta)
		# Her adımda kalça hafif iner kalkar, göğüs nefes alır, gövde hafif döner.
		hips.position.y = HIP_Y - absf(c) * 0.035 * a + 0.01 * a
		chest.rotation.y = s * 0.12 * a
		chest.rotation.x = 0.06 * a
		var idle := 1.0 - a
		chest.scale = Vector3.ONE * (1.0 + sin(_time * 1.6) * 0.008 * idle)
		head.rotation.y = sin(_time * 0.37) * 0.25 * idle - chest.rotation.y
		head.rotation.x = sin(_time * 0.23) * 0.05 * idle - 0.04 * a
	_blink(delta)


func _pose_limb(root: Node3D, joint: Node3D, swing: float, bend: float, delta: float) -> void:
	var k := minf(1.0, delta * 14.0)
	root.rotation.x = lerpf(root.rotation.x, swing, k)
	joint.rotation.x = lerpf(joint.rotation.x, bend, k)


func _blink(_delta: float) -> void:
	var t := _time - _blink_at
	var closed := 0.0
	if t > 0.0:
		closed = 1.0 - absf(t - 0.07) / 0.07
		if t > 0.14:
			_blink_at = _time + randf_range(2.0, 5.0)
			closed = 0.0
	closed = clampf(closed, 0.0, 1.0)
	for eye in _lids:
		eye.scale.y = lerpf(1.0, 0.08, closed)


# ---------- yardımcılar ----------

## Dönel yüzey: profil [[y, yarıçap], ...] noktalarını Y ekseni etrafında döndürür.
## open_bottom true ise alt kenar açık bırakılır (kabuk gibi), aksi halde uçlar kapanır.
func _lathe(profile: Array, segments: int, open_bottom: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := profile.size()
	for i in rows - 1:
		var y0: float = profile[i][0]
		var r0: float = profile[i][1]
		var y1: float = profile[i + 1][0]
		var r1: float = profile[i + 1][1]
		for j in segments:
			var a0 := TAU * float(j) / segments
			var a1 := TAU * float(j + 1) / segments
			var p00 := Vector3(sin(a0) * r0, y0, cos(a0) * r0)
			var p01 := Vector3(sin(a1) * r0, y0, cos(a1) * r0)
			var p10 := Vector3(sin(a0) * r1, y1, cos(a0) * r1)
			var p11 := Vector3(sin(a1) * r1, y1, cos(a1) * r1)
			if y1 > y0:
				_tri(st, p00, p11, p10)
				_tri(st, p00, p01, p11)
			else:
				_tri(st, p00, p10, p11)
				_tri(st, p00, p11, p01)
	# Uçları kapat (yarıçap sıfır değilse)
	var first: Array = profile[0]
	var last: Array = profile[rows - 1]
	var top_first: bool = first[0] > last[0]
	if float(first[1]) > 0.001 and not open_bottom:
		_cap(st, float(first[0]), float(first[1]), segments, top_first)
	if float(last[1]) > 0.001:
		_cap(st, float(last[0]), float(last[1]), segments, not top_first)
	st.index()
	st.generate_normals()
	return st.commit()


## Godot ön yüzleri saat yönünde sayar; dışarıdan bakınca görünsün diye b ile c yer değiştirir.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


func _cap(st: SurfaceTool, y: float, r: float, segments: int, facing_up: bool) -> void:
	var center := Vector3(0, y, 0)
	for j in segments:
		var a0 := TAU * float(j) / segments
		var a1 := TAU * float(j + 1) / segments
		var p0 := Vector3(sin(a0) * r, y, cos(a0) * r)
		var p1 := Vector3(sin(a1) * r, y, cos(a1) * r)
		if facing_up:
			_tri(st, center, p0, p1)
		else:
			_tri(st, center, p1, p0)


func _mesh(parent: Node3D, m: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi


## Yatay (X ekseninde) kapsül: kaş ve dudak için.
func _capsule_x(radius: float, length: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = length
	m.radial_segments = 10
	m.rings = 4
	return m


func _soft_mat(color: Color, roughness: float, rim: float) -> StandardMaterial3D:
	var m := MapBuilder.mat(color, roughness)
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.6
	return m
