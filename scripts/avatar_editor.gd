extends Control
## Avatar ekranı: sağda seçenek paneli, solda karakter canlı olarak değişir.
## Düğmeler parmakla rahat basılacak büyüklükte (en az 52 piksel).

signal look_changed(look: Dictionary)
signal finished(look: Dictionary)

const AvatarData = preload("res://scripts/avatar_data.gd")

const INK := Color("1f2a44")
const PAPER := Color("fffaf0")
const SUN := Color("ffc23d")
const SOFT := Color("f1e8d6")
const COLOR_KEYS := AvatarData.COLOR_KEYS
const SECTIONS := [
	["skin", "Ten rengi"],
	["hair_style", "Saç modeli"],
	["hair", "Saç rengi"],
	["eyes", "Göz rengi"],
	["body", "Tişört"],
	["pants", "Pantolon"],
	["accessory", "Aksesuar"],
]

var look: Dictionary = {}
var _buttons: Array = []  # [anahtar, değer, Button]
var _name_edit: LineEdit
var _custom: Dictionary = {}  # anahtar -> "+" palet düğmesi
var _palette: PopupPanel
var _palette_title: Label
var _picker: ColorPicker
var _palette_key := ""


func _ready() -> void:
	_fit_screen()
	get_viewport().size_changed.connect(_fit_screen)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.anchor_left = 0.55
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0
	panel.offset_right = -16.0
	panel.offset_top = 16.0
	panel.offset_bottom = -16.0
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(22)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0.12, 0.16, 0.27, 0.25)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	box.add_child(_label("Avatarını yap", 30))

	box.add_child(_label("Adın", 18, true))
	_name_edit = LineEdit.new()
	_name_edit.max_length = AvatarData.NAME_MAX
	_name_edit.placeholder_text = "Adını yaz"
	_name_edit.custom_minimum_size = Vector2(0, 52)
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.text_changed.connect(_on_name_changed)
	box.add_child(_name_edit)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for section in SECTIONS:
		_add_section(list, str(section[0]), str(section[1]))

	var done := Button.new()
	done.text = "Hazır!"
	done.custom_minimum_size = Vector2(0, 60)
	done.add_theme_font_size_override("font_size", 26)
	_style_button(done, SUN, false, 16)
	done.pressed.connect(_on_done)
	box.add_child(done)


func open(current: Dictionary) -> void:
	look = AvatarData.sanitize(current)
	_name_edit.text = str(look["name"])
	_refresh()
	show()


func _add_section(parent: Control, key: String, title: String) -> void:
	parent.add_child(_label(title, 18, true))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	parent.add_child(flow)
	for value in AvatarData.OPTIONS[key]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		if COLOR_KEYS.has(key):
			b.custom_minimum_size = Vector2(52, 52)
			b.tooltip_text = str(value)
		else:
			b.text = str(AvatarData.LABELS.get(value, value))
			b.custom_minimum_size = Vector2(0, 52)
			b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_on_pick.bind(key, str(value)))
		flow.add_child(b)
		_buttons.append([key, str(value), b])
	if COLOR_KEYS.has(key):
		flow.add_child(_make_palette_button(key))


## Hazır renklerin yanındaki "+" düğmesi: dokununca renk çemberi açılır, her renk seçilebilir.
func _make_palette_button(key: String) -> Button:
	var b := Button.new()
	b.text = "+"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(_open_palette.bind(key))
	_custom[key] = b
	return b


func _open_palette(key: String) -> void:
	if _palette == null:
		_palette = PopupPanel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = PAPER
		sb.set_corner_radius_all(22)
		sb.set_content_margin_all(18)
		_palette.add_theme_stylebox_override("panel", sb)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 12)
		_palette.add_child(col)
		_palette_title = _label("", 22)
		col.add_child(_palette_title)
		_picker = ColorPicker.new()
		_picker.edit_alpha = false
		_picker.picker_shape = ColorPicker.SHAPE_HSV_WHEEL
		_picker.sliders_visible = false
		_picker.presets_visible = false
		_picker.sampler_visible = false
		_picker.color_modes_visible = false
		_picker.hex_visible = false
		_picker.can_add_swatches = false
		_picker.add_theme_constant_override("sv_width", 300)
		_picker.add_theme_constant_override("sv_height", 300)
		_picker.add_theme_constant_override("h_width", 44)
		_picker.color_changed.connect(func(c: Color): _on_palette_color(c, _palette_key))
		col.add_child(_picker)
		var ok := Button.new()
		ok.text = "Tamam"
		ok.focus_mode = Control.FOCUS_NONE
		ok.custom_minimum_size = Vector2(0, 56)
		ok.add_theme_font_size_override("font_size", 24)
		_style_button(ok, SUN, false, 16)
		ok.pressed.connect(func(): _palette.hide())
		col.add_child(ok)
		add_child(_palette)
	_palette_key = key
	for section in SECTIONS:
		if section[0] == key:
			_palette_title.text = str(section[1]) + ": istediğin rengi seç"
	_picker.color = Color(str(look.get(key, "#ffffff")))
	_palette.popup_centered()


func _on_palette_color(color: Color, key: String) -> void:
	_on_pick(key, "#" + color.to_html(false))


func _on_pick(key: String, value: String) -> void:
	look[key] = value
	_refresh()
	look_changed.emit(look)


func _on_name_changed(text: String) -> void:
	look["name"] = AvatarData.clean_name(text)
	look_changed.emit(look)


func _on_done() -> void:
	look = AvatarData.sanitize(look)
	_name_edit.text = str(look["name"])
	finished.emit(look)


func _refresh() -> void:
	for key in _custom:
		var cb: Button = _custom[key]
		var value := str(look.get(key, ""))
		var is_custom: bool = not AvatarData.OPTIONS[key].has(value)
		_style_button(cb, Color(value) if is_custom else Color.WHITE, is_custom, 26)
		var light := Color(value).get_luminance() > 0.5 if is_custom else true
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			cb.add_theme_color_override(state, INK if light else Color.WHITE)
	for entry in _buttons:
		var key := str(entry[0])
		var value := str(entry[1])
		var b: Button = entry[2]
		var selected := str(look.get(key, "")) == value
		if COLOR_KEYS.has(key):
			_style_button(b, Color(value), selected, 26)
		else:
			_style_button(b, SUN if selected else SOFT, selected, 12)


func _style_button(b: Button, bg: Color, selected: bool, radius: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	if selected:
		sb.set_border_width_all(4)
		sb.border_color = INK
	else:
		sb.set_border_width_all(2)
		sb.border_color = Color(0.12, 0.16, 0.27, 0.15)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(state, sb)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, INK)


func _label(text: String, font_px: int, quiet: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", Color("66708a") if quiet else INK)
	return l


## Ekranın tamamını kaplar. CanvasLayer altındaki Control'lerde çapalar boyut vermediği için
## boyutu ekrandan alır ve ekran döndüğünde/değiştiğinde günceller.
func _fit_screen() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
