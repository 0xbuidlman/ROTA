extends Node
class_name MenuBase

var items = []
export var items_path : NodePath
onready var items_node = get_node_or_null(items_path)

export var cursor_path : NodePath
onready var cursor_node = get_node_or_null(cursor_path)
var cursor := 0 setget set_cursor
export var cursor_margin := Vector2(30, 0)
export var is_audio_cursor := true

export var scroll_path : NodePath
onready var scroll_node = get_node_or_null(scroll_path)

export var fade_path : NodePath
onready var fade_node = get_node_or_null(fade_path)
onready var fade_ease := EaseMover.new()

export var text_accept := "Accept"
export var text_cancel := "Back"

export var is_open := false setget set_open
signal signal_close(arg)
var is_sub_menu := false
var sub_ease := EaseMover.new()

var joy := Vector2.ZERO
var joy_last := Vector2.ZERO

var joy_clock := 0.0
var joy_wait := 0.3
var joy_repeat := 0.2

export var axis_x := false
export var sub_stay_open := false

func _ready():
	fill_items()
	cursor = 0
	
	reset_cursor()

func menu_input(event):
	if !is_open or is_sub_menu or sub_ease.frac() > 0.5 or (fade_node and fade_ease.frac() < 0.5): return
	
	var accept = event.is_action_pressed("ui_accept")
	var back = event.is_action_pressed("ui_cancel")
	
	joy_last = joy
	joy = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").round()
	
	if back and event.is_pressed():
		back()
		get_tree().set_input_as_handled()
	elif accept and event.is_pressed():
		accept()
		get_tree().set_input_as_handled()
	elif joy.y != 0 and joy.y != joy_last.y:
		if axis_x:
			joy_y(joy.y)
		else:
			self.cursor = wrapi(cursor + joy.y, 0, items.size())
			joy_clock = 0.0
	elif joy.x != 0 and joy.x != joy_last.x:
		if axis_x:
			self.cursor = wrapi(cursor + joy.x, 0, items.size())
			joy_clock = 0.0
		else:
			joy_x(joy.x)

func menu_process(delta):
	if fade_node:
		fade_node.modulate.a = fade_ease.count(delta, is_open)
		fade_node.visible = fade_ease.clock > 0
	
	sub_ease.count(delta, is_sub_menu)
	
	if is_open:
		# hold up/down repeat
		var diff = joy.x if axis_x else joy.y
		if !is_sub_menu and diff != 0:
			joy_clock += delta
			if joy_clock > joy_wait + joy_repeat and cursor + diff > -1 and cursor + diff < items.size():
				joy_clock = joy_wait
				self.cursor += diff
		
		# move cursor
		if items_node and cursor_node:
			cursor_node.rect_global_position = cursor_node.rect_global_position.linear_interpolate(items[cursor].rect_global_position - cursor_margin, 0.15)
			cursor_node.rect_size = cursor_node.rect_size.linear_interpolate(items[cursor].rect_size + (cursor_margin * 2.0), 0.15)
			
			# scroll
			if scroll_node:
				scroll_node.rect_position.y = lerp(scroll_node.rect_position.y, (720 / 2.0) - (cursor_node.rect_position.y + cursor_node.rect_size.y / 2.0), 0.08)

func set_cursor(arg := 0):
	cursor = clamp(arg, 0, max(items.size() - 1, 0))
	if is_audio_cursor:
		audio_cursor()

func reset_cursor():
	cursor = 0
	if items_node and cursor_node:
		cursor_node.rect_global_position = items[0].rect_global_position - cursor_margin
		cursor_node.rect_size = items[0].rect_size + (cursor_margin * 2.0)
		
		# scroll
		if scroll_node:
			scroll_node.rect_position.y = (720 / 2.0) - (cursor_node.rect_position.y + cursor_node.rect_size.y / 2.0)

func set_open(arg := is_open):
	is_open = arg
	
	if is_open:
		cursor = 0
		fill_items()
		UI.menu_keys(text_accept, text_cancel)
		open()
	else:
		emit_signal("signal_close", self)
		close()
	
	reset_joy()

func fill_items():
	items = []
	if items_node:
		for i in items_node.get_children():
			if !i.is_in_group("no_item") and i.visible:
				items.append(i)

func open():
	pass

func close():
	pass

func accept():
	pass

func back():
	pass

func joy_x(arg := 1):
	pass

func joy_y(arg := 1):
	pass

func sub_menu(arg : MenuBase):
	is_sub_menu = true
	is_open = sub_stay_open
	
	arg.is_open = true 
	arg.connect("signal_close", self, "sub_close")

func sub_close(arg):
	is_sub_menu = false
	is_open = true
	arg.disconnect("signal_close", self, "sub_close")
	UI.menu_keys(text_accept, text_cancel)
	
	reset_joy()
	open()

func audio_cursor():
	Audio.play(Audio.menu_cursor, 0.8, 1.2)

func audio_accept():
	Audio.play(Audio.menu_accept, 0.8, 1.2)

func audio_back():
	Audio.play(Audio.menu_cancel, 0.6, 0.9)

func reset_joy():
	joy_last = Vector2.ZERO
	joy = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").round()
	joy_clock = 0.0
