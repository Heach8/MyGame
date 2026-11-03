extends Node3D
## Oyuncuyu arkadan izleyen kamera. Ekranı sürükleyince döner, iki parmakla ya da fare tekerleğiyle yakınlaşır.

const MIN_DIST := 5.0
const MAX_DIST := 24.0

var target: Node3D
var yaw := 0.0
var pitch := 0.42
var pitch_target := 0.42
var focus := false  # avatar ekranı: kamera karaktere yaklaşır, karakter ekranın soluna kayar
var _saved_dist := 10.0
var _saved_pitch := 0.42
var dist := 10.0
var dist_target := 10.0

var camera: Camera3D
var _look := Vector3.ZERO
var _drag_index := -1


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 400.0
	add_child(camera)
	camera.make_current()
	if target != null:
		_look = target.global_position + Vector3(0, 1.4, 0)


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	var drag := event as InputEventScreenDrag
	var wheel := event as InputEventMouseButton
	var pinch := event as InputEventMagnifyGesture
	if touch != null:
		if focus and touch.position.x > get_viewport().get_visible_rect().size.x * 0.55:
			return
		if touch.pressed and _drag_index == -1:
			_drag_index = touch.index
		elif not touch.pressed and touch.index == _drag_index:
			_drag_index = -1
	elif drag != null and drag.index == _drag_index:
		yaw -= drag.relative.x * 0.008
		pitch_target = clampf(pitch_target + drag.relative.y * 0.005, 0.05, 1.25)
	elif wheel != null and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist_target = clampf(dist_target * 0.9, MIN_DIST, MAX_DIST)
		elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist_target = clampf(dist_target * 1.1, MIN_DIST, MAX_DIST)
	elif pinch != null:
		dist_target = clampf(dist_target / pinch.factor, MIN_DIST, MAX_DIST)


func _process(delta: float) -> void:
	if target == null:
		return
	dist = lerpf(dist, dist_target, minf(1.0, delta * 6.0))
	pitch = lerpf(pitch, pitch_target, minf(1.0, delta * 6.0))
	var wanted := target.global_position + Vector3(0, 1.4, 0)
	if focus:
		wanted += Vector3(cos(yaw), 0.0, -sin(yaw)) * 1.6 - Vector3(0, 0.2, 0)
	_look = _look.lerp(wanted, minf(1.0, delta * 8.0))
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	camera.global_position = _look + offset
	camera.look_at(_look, Vector3.UP)


func set_focus(on: bool) -> void:
	if on == focus:
		return
	focus = on
	if on:
		_saved_dist = dist_target
		_saved_pitch = pitch_target
		dist_target = 4.2
		pitch_target = 0.12
	else:
		dist_target = _saved_dist
		pitch_target = _saved_pitch
