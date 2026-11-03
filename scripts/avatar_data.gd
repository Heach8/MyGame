extends RefCounted
## Avatarın ayarları: seçenek listeleri, varsayılanlar, tablete kaydetme ve okuma.
## Sunucuya ve arkadaşlara giden şey yalnızca bu sözlüktür; fotoğraf asla bunun içinde olmaz.

const SAVE_PATH := "user://avatar.json"
const NAME_MAX := 14

const OPTIONS := {
	"skin": ["#ffe0c4", "#f2c9a5", "#d9a27a", "#a86f4c", "#6f4430"],
	"hair_style": ["kisa", "uzun", "atkuyrugu", "topuz"],
	"hair": ["#2a1d18", "#5a3825", "#a0612f", "#e8c06a", "#d8483c", "#7b5cd6", "#3fa7d6", "#ff8fc7"],
	"eyes": ["#2b2233", "#6b4226", "#3f8f5a", "#3f73c4"],
	"body": ["#ff7aa8", "#5bb3ff", "#ffc23d", "#6ad08a", "#b48cff", "#ff8c42", "#ffffff", "#2f3b5c"],
	"pants": ["#34426b", "#2a2a35", "#8a5a3b", "#e35d5b", "#6ad08a"],
	"accessory": ["yok", "gozluk", "sapka", "fiyonk"],
}

const LABELS := {
	"kisa": "Kısa",
	"uzun": "Uzun",
	"atkuyrugu": "At kuyruğu",
	"topuz": "Topuz",
	"yok": "Yok",
	"gozluk": "Gözlük",
	"sapka": "Şapka",
	"fiyonk": "Fiyonk",
}


static func defaults() -> Dictionary:
	return {
		"name": "Beren",
		"skin": "#f2c9a5",
		"hair_style": "uzun",
		"hair": "#5a3825",
		"eyes": "#2b2233",
		"body": "#ff7aa8",
		"pants": "#34426b",
		"accessory": "yok",
	}


## Kayıtlı avatarı okur. Kayıt yoksa boş sözlük döner (ilk açılış).
static func load_saved() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return sanitize(data)


static func save(look: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Avatar kaydedilemedi")
		return
	file.store_string(JSON.stringify(sanitize(look)))


## Sadece listedeki değerlere izin verir; bilinmeyen ya da bozuk değerler varsayılana döner.
static func sanitize(raw: Dictionary) -> Dictionary:
	var out := defaults()
	for key in OPTIONS:
		var value := str(raw.get(key, ""))
		if OPTIONS[key].has(value):
			out[key] = value
	out["name"] = clean_name(str(raw.get("name", "")))
	return out


## Adı temizler: harf, rakam ve boşluk kalır, en fazla 14 karakter.
## Çok oyunculu aşamada sunucu ayrıca uygunsuz kelime filtresi uygulayacak.
static func clean_name(text: String) -> String:
	var out := ""
	for i in text.length():
		var c := text.substr(i, 1)
		if c.to_upper() != c.to_lower() or "0123456789 ".contains(c):
			out += c
	out = out.strip_edges()
	while out.contains("  "):
		out = out.replace("  ", " ")
	if out.length() > NAME_MAX:
		out = out.substr(0, NAME_MAX).strip_edges()
	return out if not out.is_empty() else "Oyuncu"


## Fotoğraftan alınan renge en yakın seçeneği bulur (insan gözüne yakın "redmean" uzaklığı).
static func nearest(key: String, c: Color) -> String:
	var best := ""
	var best_d := INF
	for v in OPTIONS[key]:
		var o := Color(str(v))
		var rm := (c.r + o.r) * 0.5
		var dr := c.r - o.r
		var dg := c.g - o.g
		var db := c.b - o.b
		var d := (2.0 + rm) * dr * dr + 4.0 * dg * dg + (3.0 - rm) * db * db
		if d < best_d:
			best_d = d
			best = str(v)
	return best


## Seçilen fotoğrafı yalnızca hafızaya okur; dosya kopyalanmaz, hiçbir yere gönderilmez.
static func load_photo(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var img := Image.new()
	var lower := path.to_lower()
	var err := ERR_FILE_UNRECOGNIZED
	if lower.ends_with(".png"):
		err = img.load_png_from_buffer(bytes)
	elif lower.ends_with(".webp"):
		err = img.load_webp_from_buffer(bytes)
	else:
		err = img.load_jpg_from_buffer(bytes)
		if err != OK:
			err = img.load_png_from_buffer(bytes)
		if err != OK:
			err = img.load_webp_from_buffer(bytes)
	if err != OK or img.is_empty():
		return null
	var m := maxi(img.get_width(), img.get_height())
	if m > 1024:
		var k := 1024.0 / m
		img.resize(int(img.get_width() * k), int(img.get_height() * k))
	return img
