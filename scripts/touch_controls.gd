extends Control
## Ekrandaki kontroller: sol altta joystick, sağ altta zıplama düğmesi.
## Dokunuşları ekranın tamamından dinler; joystick ya da düğmeye düşen dokunuşu kendisi alır,
## gerisi kameraya gider.

const JOY_RADIUS := 90.0
const KNOB_RADIUS := 40.0
const JUMP_RADIUS := 60.0

var player  # player.gd

var _joy_index := -1
var _knob := Vector2.ZERO
var _jump_index := -1


func _ready() -> void:
	_fit_screen()
	get_viewport().size_changed.connect(_fit_screen)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _joy_center() -> Vector2:
	return Vector2(40.0 + JOY_RADIUS, size.y - 40.0 - JOY_RADIUS)


func _jump_center() -> Vector2:
	return Vector2(size.x - 50.0 - JUMP_RADIUS, size.y - 60.0 - JUMP_RADIUS)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var touch := event as InputEventScreenTouch
	var drag := event as InputEventScreenDrag
	if touch != null:
		var pos := touch.position
		if touch.pressed:
			if _joy_index == -1 and pos.x < size.x * 0.45 and pos.y > size.y * 0.45:
				_joy_index = touch.index
				_set_knob(pos)
				get_viewport().set_input_as_handled()
			elif _jump_index == -1 and pos.distance_to(_jump_center()) < JUMP_RADIUS * 1.3:
				_jump_index = touch.index
				if player != null:
					player.jump_requested = true
				queue_redraw()
				get_viewport().set_input_as_handled()
		else:
			if touch.index == _joy_index:
				_joy_index = -1
				_set_knob(_joy_center())
				get_viewport().set_input_as_handled()
			elif touch.index == _jump_index:
				_jump_index = -1
				queue_redraw()
				get_viewport().set_input_as_handled()
	elif drag != null:
		if drag.index == _joy_index:
			_set_knob(drag.position)
			get_viewport().set_input_as_handled()
		elif drag.index == _jump_index:
			get_viewport().set_input_as_handled()


func _set_knob(pos: Vector2) -> void:
	_knob = (pos - _joy_center()).limit_length(JOY_RADIUS)
	if player != null:
		player.joystick_vector = _knob / JOY_RADIUS
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var c := _joy_center()
	draw_circle(c, JOY_RADIUS, Color(1, 0.98, 0.94, 0.28))
	draw_arc(c, JOY_RADIUS, 0.0, TAU, 48, Color(1, 0.98, 0.94, 0.8), 3.0, true)
	draw_circle(c + _knob, KNOB_RADIUS, Color("fffaf0"))

	var j := _jump_center()
	var pressed := _jump_index != -1
	draw_circle(j + Vector2(0, 4), JUMP_RADIUS, Color(0.12, 0.16, 0.27, 0.25))
	draw_circle(j + (Vector2(0, 3) if pressed else Vector2.ZERO), JUMP_RADIUS, Color("ffc23d"))
	var font := ThemeDB.fallback_font
	var text := "Zıpla"
	var font_size := 26
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, j + Vector2(-text_size.x / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("1f2a44"))


## Ekranın tamamını kaplar. CanvasLayer altındaki Control'lerde çapalar boyut vermediği için
## boyutu ekrandan alır ve ekran döndüğünde/değiştiğinde günceller.
func _fit_screen() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
