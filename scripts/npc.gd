extends CharacterBody3D
## Adada dolaşan arkadaş karakteri. Çok oyunculu aşamaya kadar gerçek oyuncuların yerini tutar.

const AvatarScript = preload("res://scripts/avatar.gd")

const SPEED := 3.2
const GRAVITY := 20.0

var look: Dictionary = {}
var island_radius := 30.0

var avatar
var _target := Vector3.ZERO
var _time_left := 0.0
var _wait := 0.0
var _facing := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_wait = _rng.randf_range(0.0, 2.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 2.4
	shape.shape = capsule
	shape.position.y = 1.2
	add_child(shape)
	avatar = AvatarScript.new()
	add_child(avatar)
	avatar.setup(look)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var moving := false
	if _wait > 0.0:
		_wait -= delta
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		if _time_left <= 0.0:
			var a := _rng.randf() * TAU
			var d := _rng.randf_range(4.0, island_radius)
			_target = Vector3(cos(a) * d, 0.0, sin(a) * d)
			_time_left = 7.0
		_time_left -= delta
		var to := Vector3(_target.x - position.x, 0.0, _target.z - position.z)
		if to.length() < 0.5:
			_time_left = 0.0
			_wait = _rng.randf_range(1.0, 4.0)
		else:
			var dir := to.normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
			_facing = lerp_angle(_facing, atan2(dir.x, dir.z), minf(1.0, delta * 8.0))
			moving = true
	move_and_slide()
	avatar.rotation.y = _facing
	avatar.animate(SPEED if moving else 0.0, delta, false)
