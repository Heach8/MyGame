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
	if _frame == 120:
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
		quit(0)
	return false


func _save(file: String) -> void:
	var img := root.get_texture().get_image()
	var path := _out.path_join(file)
	var err := img.save_png(path)
	print("Ekran görüntüsü: ", path, " -> ", err)
