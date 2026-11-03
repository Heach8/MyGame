extends CharacterBody3D
## Oyuncunun karakteri: klavye (W A S D, oklar, Boşluk, Shift) ya da ekrandaki joystick ile yürür, koşar, zıplar.
## Hareket kameranın baktığı yöne göredir.

const AvatarScript = preload("res://scripts/avatar.gd")

const WALK_SPEED := 5.2
const RUN_SPEED := 8.5
const JUMP_SPEED := 7.2
const GRAVITY := 20.0
const ISLAND_LIMIT := 35.0

var look: Dictionary = {}
var camera_rig  # camera_rig.gd; yaw değerini okuruz
var joystick_vector := Vector2.ZERO  # dokunmatik joystick, -1..1 (y aşağı = geri)
var jump_requested := false
var input_enabled := true  # avatar ekranı açıkken kapalı

var avatar
var _facing := PI


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 2.4
	shape.shape = capsule
	shape.position.y = 1.2
	add_child(shape)

	avatar = AvatarScript.new()
	avatar.name = "Avatar"
	add_child(avatar)
	avatar.setup(look)
	floor_snap_length = 0.3


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("sol", "sag", "ileri", "geri") + joystick_vector
	input = input.limit_length(1.0)
	if not input_enabled:
		input = Vector2.ZERO
		jump_requested = false

	var yaw := 0.0
	if camera_rig != null:
		yaw = camera_rig.yaw
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var dir := right * input.x - forward * input.y

	var strength := dir.length()
	if strength > 0.05:
		var speed := RUN_SPEED if Input.is_action_pressed("kos") else WALK_SPEED
		dir = dir / strength
		velocity.x = dir.x * speed * minf(strength, 1.0)
		velocity.z = dir.z * speed * minf(strength, 1.0)
		_facing = lerp_angle(_facing, atan2(dir.x, dir.z), minf(1.0, delta * 12.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)

	if is_on_floor():
		if input_enabled and (jump_requested or Input.is_action_just_pressed("zipla")):
			velocity.y = JUMP_SPEED
	else:
		velocity.y -= GRAVITY * delta
	jump_requested = false

	move_and_slide()

	var flat := Vector2(position.x, position.z)
	if flat.length() > ISLAND_LIMIT:
		flat = flat.normalized() * ISLAND_LIMIT
		position.x = flat.x
		position.z = flat.y
	if position.y < -5.0:
		position = Vector3(0, 1, 2)
		velocity = Vector3.ZERO

	avatar.rotation.y = _facing
	avatar.animate(Vector2(velocity.x, velocity.z).length(), delta, not is_on_floor())


## Karakteri verilen yöne çevirir (kameranın yaw değeri verilirse kameraya bakar).
func face_yaw(yaw: float) -> void:
	_facing = yaw
	if avatar != null:
		avatar.rotation.y = _facing
