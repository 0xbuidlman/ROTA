extends Node2D

onready var gem_back := $Back
onready var gem_fill := $Back/Fill

export var from_fill := Color("ff00e9")
export var from_back := Color("af00ff")
export var to_fill := Color("fffb00")
export var to_back := Color("ffdd00")

var fade_ease = EaseMover.new(0.7)
var is_change := false

func _physics_process(delta):
	if is_change:
		if !fade_ease.is_complete:
			fade_ease.count(delta)
			gem_back.color = from_back.linear_interpolate(to_back, fade_ease.smooth())
			gem_fill.color = from_fill.linear_interpolate(to_fill, fade_ease.smooth())
		else:
			is_change = false

func set_color(is_collected := true):
	gem_back.color = to_back if is_collected else from_back
	gem_fill.color = to_fill if is_collected else from_fill

func fade_color(is_collected := true):
	is_change = true
