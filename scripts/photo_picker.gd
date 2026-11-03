extends Control
## "Fotoğrafımdan yap" ekranı. Çocuk fotoğrafta önce yanağına, sonra saçına, sonra gözüne dokunur;
## dokunduğu yerin rengine en yakın seçenek avatara uygulanır. Bitince fotoğraf hafızadan silinir.
## Fotoğraf hiçbir yere kaydedilmez ve gönderilmez.

signal sampled(key: String, value: String)
signal closed

const AvatarData = preload("res://scripts/avatar_data.gd")

const INK := Color("1f2a44")
const SUN := Color("ffc23d")
const STEPS := [
	["skin", "1/3  Yanağına dokun"],
	["hair", "2/3  Saçına dokun"],
	["eyes", "3/3  Gözüne dokun"],
]

var _image: Image
var _photo: TextureRect
var _title: Label
var _step := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.16, 0.27, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.anchor_left = 0.0
	_title.anchor_right = 1.0
	_title.offset_top = 20.0
	_title.offset_bottom = 70.0
	add_child(_title)

	_photo = TextureRect.new()
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.mouse_filter = Control.MOUSE_FILTER_STOP
	_photo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_photo.offset_left = 24.0
	_photo.offset_top = 84.0
	_photo.offset_right = -24.0
	_photo.offset_bottom = -96.0
	_photo.gui_input.connect(_on_photo_input)
	add_child(_photo)

	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -80.0
	bar.offset_bottom = -20.0
	add_child(bar)
	bar.add_child(_button("Döndür", Color("f1e8d6"), _on_rotate))
	bar.add_child(_button("Bu adımı atla", Color("f1e8d6"), _next_step))
	bar.add_child(_button("Bitir", SUN, _finish))

	var note := Label.new()
	note.text = "Fotoğraf sadece bu ekranda. Kaydedilmez, kimseye gönderilmez, bitince silinir."
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.anchor_left = 0.0
	note.anchor_right = 1.0
	note.anchor_top = 1.0
	note.anchor_bottom = 1.0
	note.offset_top = -100.0
	note.offset_bottom = -82.0
	add_child(note)


func start(img: Image) -> void:
	_image = img
	_photo.texture = ImageTexture.create_from_image(_image)
	_step = 0
	_update_title()
	show()


func _update_title() -> void:
	_title.text = str(STEPS[_step][1])


func _on_photo_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _image == null:
		return
	var px := _to_image(mb.position)
	if px.x < 0:
		return
	var key := str(STEPS[_step][0])
	sampled.emit(key, AvatarData.nearest(key, _average(px)))
	_next_step()


## Ekrandaki dokunuşu fotoğraftaki piksele çevirir (fotoğraf ortalanmış ve oranı korunmuş çizilir).
func _to_image(p: Vector2) -> Vector2i:
	var area := _photo.size
	var img_size := Vector2(_image.get_size())
	var s := minf(area.x / img_size.x, area.y / img_size.y)
	var offset := (area - img_size * s) / 2.0
	var q := (p - offset) / s
	if q.x < 0.0 or q.y < 0.0 or q.x >= img_size.x or q.y >= img_size.y:
		return Vector2i(-1, -1)
	return Vector2i(int(q.x), int(q.y))


## Dokunulan noktanın çevresindeki küçük bir dairenin ortalama rengi.
func _average(center: Vector2i) -> Color:
	var w := _image.get_width()
	var h := _image.get_height()
	var r := maxi(2, int(mini(w, h) * 0.012))
	var sum := Vector3.ZERO
	var count := 0
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var x := center.x + dx
			var y := center.y + dy
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var c := _image.get_pixel(x, y)
			sum += Vector3(c.r, c.g, c.b)
			count += 1
	if count == 0:
		return Color.BLACK
	sum /= float(count)
	return Color(sum.x, sum.y, sum.z)


func _on_rotate() -> void:
	if _image == null:
		return
	_image.rotate_90(CLOCKWISE)
	_photo.texture = ImageTexture.create_from_image(_image)


func _next_step() -> void:
	_step += 1
	if _step >= STEPS.size():
		_finish()
	else:
		_update_title()


func _finish() -> void:
	_photo.texture = null
	_image = null
	hide()
	closed.emit()


func _button(text: String, bg: Color, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, sb)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, INK)
	b.pressed.connect(callback)
	return b
