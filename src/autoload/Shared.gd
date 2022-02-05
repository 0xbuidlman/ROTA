extends Node

var is_reset := false
var is_level_select := false

var next_scene := ""

var scene_splash := "res://src/menu/Splash.tscn"
var scene_title := "res://src/menu/Title.tscn"
var scene_select := "res://src/menu/WorldSelect.tscn"
var scene_options := "res://src/menu/Options.tscn"

var world := -1
var level := -1

var world_size = {}

var unlocked = [5, -1, -1, -1, -1, -1]

var worlds_path := "res://src/map/worlds/"

func _ready():
	Wipe.connect("wipe_out", self, "wipe_out")
	is_level_select = get_tree().current_scene.name == "WorldSelect"
	
	for i in list_folder(worlds_path).size():
		world_size[i] = list_folder(worlds_path + str(i + 1) + "/").size() - 1

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_F11:
			toggle_fullscreen()

func list_folder(path, include_extension := true):
	var dir = Directory.new()
	if dir.open(path) != OK:
		print("list_folder(): '", path, "' not found")
		return
	
	var list = []
	dir.list_dir_begin(true)
	
	var fname = dir.get_next()
	while fname != "":
		list.append(fname if include_extension else fname.split(".")[0])
		fname = dir.get_next()
	
	return list

func reset():
	if !is_reset:
		is_reset = true
		Wipe.start()

func change_scene(arg):
	next_scene = arg
	Wipe.start()

func wipe_out():
	Wipe.start(true)
	if is_reset:
		is_reset = false
		get_tree().reload_current_scene()
	else:
		is_level_select = next_scene == scene_select
		get_tree().change_scene(next_scene)
	
	match next_scene:
		scene_splash: HUD.show("none")
		scene_title: HUD.show("title")
		scene_select: HUD.show("title")
		scene_options: HUD.show("title")
		_: HUD.show("game")

func complete_level():
	level += 1
	if world != -1 and level != -1:
		if world_size[world] < level:
			if unlocked[world + 1] < 0:
				unlocked[world + 1] = 0
			world += 1
			level = -1
		elif unlocked[world] < level:
			unlocked[world] = clamp(level, 0, world_size[world])
	change_scene(scene_select)

func toggle_fullscreen():
	OS.window_fullscreen = !OS.window_fullscreen
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if OS.window_fullscreen else Input.MOUSE_MODE_VISIBLE)

