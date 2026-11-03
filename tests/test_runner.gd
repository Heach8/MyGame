extends SceneTree
## Hızlı testler: avatar verisi ve serbest renk seçimi.
## Çalıştırma: godot --headless --path . --script res://tests/test_runner.gd

const AvatarData = preload("res://scripts/avatar_data.gd")

const EXPECTED_CHECKS := 13

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
	_test_colors()
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
	var s := AvatarData.sanitize({"skin": "#00000g", "hair_style": "topuz", "name": "Ela"})
	_check(s["skin"] == AvatarData.defaults()["skin"], "ayar: geçersiz renk varsayılana döner")
	_check(s["hair_style"] == "topuz", "ayar: geçerli saç modeli korunur")
	_check(s["name"] == "Ela", "ayar: ad korunur")
	_check(not s.has("photo"), "ayar: fotoğraf alanı yok")


func _test_colors() -> void:
	var s := AvatarData.sanitize({"skin": "#3A2B1C", "hair": "#12345", "body": "kirmizi", "eyes": "#00ff00"})
	_check(s["skin"] == "#3a2b1c", "renk: paletten seçilen ten rengi korunur")
	_check(s["eyes"] == "#00ff00", "renk: paletten seçilen göz rengi korunur")
	_check(s["hair"] == AvatarData.defaults()["hair"], "renk: bozuk renk kodu varsayılana döner")
	_check(s["body"] == AvatarData.defaults()["body"], "renk: renk olmayan yazı varsayılana döner")
	var t := AvatarData.sanitize({"accessory": "#ffffff", "hair_style": "#000000"})
	_check(t["accessory"] == "yok" and t["hair_style"] == AvatarData.defaults()["hair_style"], "renk: renk olmayan alanlara renk yazılamaz")
