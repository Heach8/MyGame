extends SceneTree
## Oyundan ekran görüntüleri alır (CI'da görsel kontrol için).
## Kullanım: godot --path . --script res://tests/screenshot.gd -- <klasör>
## 1) avatar ekranı açıkken karakterin yakın görüntüsü, 2) oyun görünümü.

var _frame := 0
var _main
var _out := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 100:
		_main.editor._open_palette("body")
	elif _frame == 110:
		_save("0_palet.png")
		_main.editor._palette.hide()
	elif _frame == 120:
		_save("1_avatar_ekrani.png")
	elif _frame == 125:
		_main.editor._on_done()
	elif _frame == 240:
		_save("2_oyun.png")
	elif _frame == 245:
		_main.rig.set_focus(true)
	elif _frame == 330:
		_main.editor.hide()
		_save("3_yakin.png")
		var head: Node3D = _main.player.avatar.head
		var fwd: Vector3 = _main.player.avatar.global_transform.basis.z
		var cam := Camera3D.new()
		_main.add_child(cam)
		cam.global_position = head.global_position + fwd * 0.95 + Vector3(0.25, 0.05, 0)
		cam.look_at(head.global_position, Vector3.UP)
		cam.fov = 40.0
		cam.make_current()
	elif _frame == 340:
		_save("4_yuz.png")
		quit(0)
	return false


func _save(file: String) -> void:
	var img := root.get_texture().get_image()
	var path := _out.path_join(file)
	var err := img.save_png(path)
	print("Ekran görüntüsü: ", path, " -> ", err)
