extends RefCounted
## Harita dosyasını (JSON) okuyup adadaki nesneleri kurar.
## Harita biçimi web prototipiyle aynıdır: {"nesneler": [{"t": "ev", "x": 0, "z": 0, "rot": 0}, ...]}

## Her nesne türü: Türkçe adı ve çarpışma yarıçapı (metre).
const KINDS := {
	"agac": {"ad": "Ağaç", "r": 0.8},
	"cam": {"ad": "Çam", "r": 0.7},
	"ev": {"ad": "Ev", "r": 2.4},
	"cicek": {"ad": "Çiçek", "r": 0.0},
	"kaya": {"ad": "Kaya", "r": 0.85},
	"bank": {"ad": "Bank", "r": 0.9},
	"lamba": {"ad": "Lamba", "r": 0.3},
	"havuz": {"ad": "Havuz", "r": 1.6},
}

const LEAF := [Color("5cbf6e"), Color("45a85a"), Color("7dd47c")]
const ROOF := [Color("e35d5b"), Color("4f7cd6"), Color("f29e4c"), Color("8c6bd1")]
const WALL := [Color("fff1d6"), Color("ffe0e6"), Color("dff0ff"), Color("e6ffde")]
const FLOWER := [Color("ff6fa5"), Color("ffd23f"), Color("b08cff"), Color("ff8c42"), Color("ffffff")]
const TRUNK := Color("8a5a3b")


static func load_map_file(root: Node3D, path: String) -> int:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Harita bulunamadı: %s" % path)
		return 0
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("nesneler"):
		push_error("Harita okunamadı: %s" % path)
		return 0
	var count := 0
	for item in data["nesneler"]:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var kind := str(item.get("t", ""))
		if not KINDS.has(kind):
			continue
		var node := make(kind, float(item.get("x", 0)), float(item.get("z", 0)))
		node.rotation.y = float(item.get("rot", 0))
		root.add_child(node)
		count += 1
	return count


static func make(kind: String, x: float, z: float) -> Node3D:
	var node := Node3D.new()
	node.name = "%s_%d_%d" % [kind, int(x), int(z)]
	node.position = Vector3(x, 0, z)
	match kind:
		"agac":
			_add(node, cyl(0.16, 0.25, 1.5, 10), mat(TRUNK), Vector3(0, 0.75, 0))
			var leaf := mat(pick(LEAF, x, z, 0))
			_add(node, sphere(1.05, 12, 8), leaf, Vector3(0, 2.2, 0))
			_add(node, sphere(0.78, 12, 8), leaf, Vector3(0.55, 1.85, 0.25))
			_add(node, sphere(0.72, 12, 8), leaf, Vector3(-0.45, 1.95, -0.3))
			_add(node, sphere(0.66, 12, 8), leaf, Vector3(0, 2.9, 0))
		"cam":
			_add(node, cyl(0.14, 0.2, 1.0, 8), mat(TRUNK), Vector3(0, 0.5, 0))
			var pine := mat(Color("2f8f5b"))
			_add(node, cyl(0.0, 1.25, 1.5, 8), pine, Vector3(0, 1.4, 0))
			_add(node, cyl(0.0, 0.98, 1.3, 8), pine, Vector3(0, 2.15, 0))
			_add(node, cyl(0.0, 0.66, 1.1, 8), pine, Vector3(0, 2.8, 0))
		"ev":
			_add(node, box(Vector3(3.4, 2.2, 3.0)), mat(pick(WALL, x, z, 1)), Vector3(0, 1.1, 0))
			var roof := _add(node, cyl(0.0, 2.75, 1.6, 4), mat(pick(ROOF, x, z, 2)), Vector3(0, 3.0, 0))
			roof.rotation.y = PI / 4.0
			_add(node, box(Vector3(0.75, 1.25, 0.1)), mat(TRUNK), Vector3(0, 0.62, 1.52))
			_add(node, sphere(0.05, 8, 6), mat(Color("ffd23f")), Vector3(0.25, 0.62, 1.59))
			var glass := mat(Color("aee0ff"), 0.2)
			glass.emission_enabled = true
			glass.emission = Color("6fbfff")
			glass.emission_energy_multiplier = 0.35
			for px in [-1.05, 1.05]:
				_add(node, box(Vector3(0.6, 0.6, 0.08)), glass, Vector3(px, 1.35, 1.52))
				_add(node, box(Vector3(0.74, 0.1, 0.12)), mat(Color.WHITE), Vector3(px, 1.02, 1.54))
			_add(node, box(Vector3(0.38, 0.9, 0.38)), mat(Color("b5655a")), Vector3(0.9, 3.2, -0.5))
		"cicek":
			var stem := mat(Color("3f9a4e"))
			for i in 6:
				var a := hash01(x, z, i) * TAU
				var d := hash01(z, x, i) * 0.4
				var h := 0.25 + hash01(x, z, i + 9) * 0.2
				var p := Vector3(cos(a) * d, 0, sin(a) * d)
				_add(node, cyl(0.02, 0.02, h, 5), stem, p + Vector3(0, h / 2.0, 0))
				_add(node, sphere(0.1, 8, 6), mat(pick(FLOWER, x, z, i + 3)), p + Vector3(0, h + 0.04, 0))
		"kaya":
			var rock := _add(node, sphere(0.75, 7, 5), mat(Color("a7adb9")), Vector3(0, 0.38, 0))
			rock.scale = Vector3(1.0, 0.7, 1.15)
			_add(node, sphere(0.35, 6, 4), mat(Color("9298a6")), Vector3(0.75, 0.18, 0.3))
		"bank":
			var wood := mat(Color("c98b52"))
			var metal := mat(Color("34405e"))
			_add(node, box(Vector3(1.7, 0.12, 0.55)), wood, Vector3(0, 0.5, 0))
			_add(node, box(Vector3(1.7, 0.42, 0.08)), wood, Vector3(0, 0.85, -0.24))
			for leg in [Vector2(-0.7, 0.2), Vector2(0.7, 0.2), Vector2(-0.7, -0.2), Vector2(0.7, -0.2)]:
				_add(node, box(Vector3(0.08, 0.5, 0.08)), metal, Vector3(leg.x, 0.25, leg.y))
		"lamba":
			_add(node, cyl(0.06, 0.09, 2.4, 8), mat(Color("2d3550")), Vector3(0, 1.2, 0))
			var bulb := mat(Color("fff3b0"))
			bulb.emission_enabled = true
			bulb.emission = Color("ffd36b")
			bulb.emission_energy_multiplier = 1.3
			_add(node, sphere(0.24, 16, 10), bulb, Vector3(0, 2.5, 0))
		"havuz":
			_add(node, cyl(1.6, 1.7, 0.35, 28), mat(Color("e8e2d4")), Vector3(0, 0.17, 0))
			var water := mat(Color("4cc3f0"), 0.1)
			water.emission_enabled = true
			water.emission = Color("1b78b0")
			water.emission_energy_multiplier = 0.25
			_add(node, cyl(1.35, 1.35, 0.06, 28), water, Vector3(0, 0.33, 0))

	var radius: float = KINDS[kind]["r"]
	if radius > 0.0:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cyl_shape := CylinderShape3D.new()
		cyl_shape.radius = radius
		cyl_shape.height = 3.0
		shape.shape = cyl_shape
		shape.position.y = 1.5
		body.add_child(shape)
		node.add_child(body)
	return node


# ---------- yardımcılar ----------

static func _add(parent: Node3D, m: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi


static func mat(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func cyl(top: float, bottom: float, height: float, segments: int = 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m


static func sphere(radius: float, segments: int = 16, rings: int = 10) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = segments
	m.rings = rings
	return m


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func hash01(x: float, z: float, s: float) -> float:
	var h := sin(x * 12.9898 + z * 78.233 + s * 37.7) * 43758.5453
	return h - floor(h)


static func pick(list: Array, x: float, z: float, s: float) -> Color:
	return list[int(hash01(x, z, s) * list.size()) % list.size()]
