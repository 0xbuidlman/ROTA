extends Node2D

onready var sprite := $Sprite

var box : Box = null
var is_deploy := false
var last_deploy := false

var easy := EaseMover.new(0.3)

var _delta := 1.0 / 60.0

func _ready():
	visible = false
	
	get_tree().connect("idle_frame", self, "place")
	Shared.connect("scene_changed", self, "set_box")

func _physics_process(delta):
	_delta = delta

func set_box(b = null):
	is_deploy = is_instance_valid(b)
	if is_deploy:
		box = b
		place()

func place():
	easy.count(_delta, is_deploy)
	
	visible = easy.clock > 0
	if visible:
		sprite.material.set_shader_param("scale_x", easy.smooth())
		sprite.material.set_shader_param("scale_y", easy.smooth())
		
		if is_instance_valid(box):
			rotation = box.sprite.rotation
			position = box.sprite.global_position
			scale.x = box.sprite.scale.x
