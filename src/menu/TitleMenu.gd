extends MenuBase

onready var file_menu := $Canvas/FileMenu

func _ready():
	UI.menu.show = true

func _exit_tree():
	UI.menu.show = false

func _input(event):
	menu_input(event)

func _physics_process(delta):
	menu_process(delta)

func accept():
	match items[cursor].name.to_lower():
		"play":
			sub_menu(file_menu)
		"options":
			sub_menu(OptionsMenu)
		"exit":
			get_tree().quit()
