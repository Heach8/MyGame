extends SceneTree
## Hızlı testler: avatar verisi ve fotoğraftan renk seçme.
## Çalıştırma: godot --headless --path . --script res://tests/test_runner.gd

const AvatarData = preload("res://scripts/avatar_data.gd")
const PhotoPickerScript = preload("res://scripts/photo_picker.gd")

const EXPECTED_CHECKS := 17

var failures := 0
var checks := 0
var _done := false


## Testler ilk karede çalışır; böylece sahne ağacı hazırdır ve eklenen düğümlerin _ready'si çağrılır.
func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_test_names()
	_test_sanitize()
	_test_nearest()
	_test_photo_sampling()
	# Bir test betik hatasıyla yarıda kalırsa kontrol sayısı eksik kalır; bunu da hata sayarız.
	if checks != EXPECTED_CHECKS:
		failures += 1
		printerr("  HATA   %d kontrol bekleniyordu, %d çalıştı" % [EXPECTED_CHECKS, checks])
	print("Testler bitti: %d kontrol, %d hata" % [checks, failures])
	quit(1 if failures > 0 else 0)
	return false


func _check(ok: bool, what: String) -> void:
	checks += 1
	if ok:
		print("  tamam  ", what)
	else:
		failures += 1
		printerr("  HATA   ", what)


func _test_names() -> void:
	_check(AvatarData.clean_name("  Be  ren!! ") == "Be ren", "ad: işaretler ve fazla boşluk temizlenir")
	_check(AvatarData.clean_name("") == "Oyuncu", "ad: boşsa Oyuncu olur")
	_check(AvatarData.clean_name("Çağla Şükriye Öztürk").length() <= AvatarData.NAME_MAX, "ad: en fazla 14 karakter")
	_check(AvatarData.clean_name("Ölçü") == "Ölçü", "ad: Türkçe harfler kalır")


func _test_sanitize() -> void:
	var s := AvatarData.sanitize({"skin": "#000000", "hair_style": "topuz", "name": "Ela"})
	_check(s["skin"] == AvatarData.defaults()["skin"], "ayar: listede olmayan renk varsayılana döner")
	_check(s["hair_style"] == "topuz", "ayar: geçerli saç modeli korunur")
	_check(s["name"] == "Ela", "ayar: ad korunur")
	_check(not s.has("photo"), "ayar: fotoğraf alanı yok")


func _test_nearest() -> void:
	_check(AvatarData.nearest("skin", Color("f0c8a0")) == "#f2c9a5", "renk: açık ten")
	_check(AvatarData.nearest("skin", Color("704530")) == "#6f4430", "renk: koyu ten")
	_check(AvatarData.nearest("hair", Color("e0b860")) == "#e8c06a", "renk: sarı saç")
	_check(AvatarData.nearest("hair", Color("1e1612")) == "#2a1d18", "renk: siyah saç")
	_check(AvatarData.nearest("eyes", Color("4070c0")) == "#3f73c4", "renk: mavi göz")


func _test_photo_sampling() -> void:
	var picker = PhotoPickerScript.new()
	root.add_child(picker)
	var img := Image.create_empty(200, 100, false, Image.FORMAT_RGB8)
	img.fill(Color("a86f4c"))
	picker.start(img)
	picker._photo.size = Vector2(400, 400)
	# 200x100 fotoğraf 400x400 alana 400x200 olarak, dikeyde 100 piksel boşlukla ortalanır.
	_check(picker._to_image(Vector2(200, 200)) == Vector2i(100, 50), "dokunuş: ekran noktası fotoğraf pikseline çevrilir")
	_check(picker._to_image(Vector2(200, 20)) == Vector2i(-1, -1), "dokunuş: fotoğraf dışı yok sayılır")

	var got: Array = []
	picker.sampled.connect(func(k, v): got.append([k, v]))
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(200, 200)
	picker._on_photo_input(ev)
	_check(got.size() == 1 and got[0][0] == "skin" and got[0][1] == "#a86f4c", "fotoğraf: yanak rengi tene uygulanır")

	picker._finish()
	_check(picker._image == null and picker._photo.texture == null, "fotoğraf: bitince hafızadan silinir")
	picker.queue_free()
