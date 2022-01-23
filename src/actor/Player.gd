tool
extends KinematicBody2D
class_name Player

onready var areas : Node2D = $Areas
onready var hit_area : Area2D = $Areas/HitArea
onready var body_area : Area2D = $BodyArea
onready var audio_slap : AudioStreamPlayer2D = $AudioSlap
onready var audio_punch : AudioStreamPlayer2D = $AudioPunch
#onready var anim : AnimationPlayer = $AnimationPlayer
#onready var anim_eyes : AnimationPlayer = $AnimationEyes
onready var collider_size : Vector2 = $CollisionShape2D.shape.extents

onready var spr_body := $Sprites/Body


onready var spr_hand_l := $Sprites/HandL
onready var spr_hand_r := $Sprites/HandR
onready var hands := [$Sprites/HandL, $Sprites/HandR]
onready var hand_start : Vector2 = $Sprites/HandR.position


var guide_scene := preload("res://src/actor/Guide.tscn")
var guide

#var wrench_scene := preload("res://src/actor/Wrench.tscn")
#var wrench

export var is_debug := false
onready var debug_label : Label = $DebugCanvas/Labels/Label
var readout = []
var readout_size = 4

export var is_input := true
var joy := Vector2.ZERO
var joy_last := Vector2.ZERO
var btn_jump := false
var btnp_jump := false
var btnp_action := false
var btn_push := false
var btnp_push := false

var camera : Camera2D

export var dir := 0 setget set_dir

var is_move := true
var is_walk := true
var is_floor := false

var velocity := Vector2.ZERO
var move_velocity := Vector2.ZERO
var dir_x := 1

export var walk_speed := 350.0
#export var air_speed := 250.0
var floor_accel := 12
var air_accel := 7

var is_jump := false
var has_jumped := true
var jump_height := 240.0 setget set_jump_height
export var jump_time := 0.6 setget set_jump_time
var jump_speed := 0.0
var jump_gravity := 0.0
var fall_gravity := 0.0
var jump_clock := 0.0

onready var blink_clock := rand_range(2, 15)

var is_dead := false
var is_exit := false
var exit_node

var turn_clock := 0.0
var turn_time := 0.2
var turn_from := 0.0
var turn_to := 0.0

var is_hold := false
var is_end_hold := false
var box 
var hold_pos := Vector2.ZERO
var push_clock := 0.0
var push_time := 0.2
var push_from := Vector2.ZERO
var push_dir := 1
var box_turn := 1


export var can_spin := true

func _ready():
	if Engine.editor_hint: return
	
	solve_jump()
	
	# snap to floor
	var test = rot(Vector2.DOWN * 75)
	if test_move(transform, test):
		move_and_collide(test)
	
	# face left or right
	randomize()
	set_dir_x(1 if randf() > 0.5 else -1)
	
	# disable input and process if inside level select
	if Shared.is_level_select:
		set_process_input(false)
		set_physics_process(false)
	
	# find camera in the same viewport
	for i in get_tree().get_nodes_in_group("game_camera"):
		if i.get_viewport() == get_viewport():
			camera = i
			camera.target_node = self
			set_dir()
			camera.turn_clock = 99
			spr_body.rotation = turn_to
			camera.connect("turning", self, "turning")
			break
	
	# debug label
	readout.resize(readout_size)
	if is_debug:
		debug_label.visible = true
	
	# wait for parent
	yield(get_parent(),"ready")
	
	# set guide
	guide = guide_scene.instance()
	get_parent().add_child(guide)
	#reparent(guide, get_parent())
	
	# set wrench
	#wrench = wrench_scene.instance()
	#get_parent().add_child(wrench)
	#wrench.player = self

func _input(event):
	if event.is_action_pressed("reset"):
		Shared.reset()

func _physics_process(delta):
	if Engine.editor_hint: return
	
	if is_exit:
		position = position.linear_interpolate(exit_node.position, 3 * delta)
		spr_body.scale = spr_body.scale.linear_interpolate(Vector2.ZERO, 0.9 * delta)
		spr_body.rotate(deg2rad(dir_x * 240) * delta)
		return
	
	if is_dead:
		spr_body.position += rot(velocity) * delta
		spr_body.rotate(deg2rad(-dir_x * 240) * delta)
		velocity.y += fall_gravity * delta
		return
	
	# input
	if is_input:
		joy_last = joy
		joy = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")).round()
		
		btn_jump = Input.is_action_pressed("jump")
		btnp_jump = Input.is_action_just_pressed("jump")
		btnp_action = Input.is_action_just_pressed("action")
		btn_push = Input.is_action_pressed("push")
		btnp_push = Input.is_action_just_pressed("push")
	
	
	# hands
#	if is_hold:
#		var d = dir
#		var s = 0.2
#		if box.turn_clock != box.turn_time:
#			s = 1.0
#			d += box_turn * (box.turn_clock / box.turn_time)
#
#		var box_edge = box.sprite.global_position - rot(Vector2(50 * dir_x, 0), d)
#		spr_hand_l.global_position = spr_hand_l.global_position.linear_interpolate(box_edge + rot(Vector2(0, -20), d), s)
#		spr_hand_r.global_position = spr_hand_r.global_position.linear_interpolate(box_edge + rot(Vector2(0, 20), d), s)
#	else:
#		spr_hand_l.position = spr_hand_l.position.linear_interpolate(Vector2(-25.5, 8.25), 0.1)
#		spr_hand_r.position = spr_hand_r.position.linear_interpolate(Vector2(25.5, 8.25), 0.1)
	
	
	
	
	
	
	
	
	
	# during hold
	if is_hold:
		if !is_end_hold:
			# during push
			if push_clock != push_time:
				push_clock = min(push_clock + delta, push_time)
				
				hold_pos = box.position + rot(Vector2(88 * -dir_x, 49 - collider_size.y))
				var smooth = smoothstep(0, 1, push_clock / push_time)
				var new_pos = push_from.linear_interpolate(hold_pos, smooth)
				var move_to = new_pos - position
				
				move_and_collide(Vector2(move_to.x, 0))
				move_and_collide(Vector2(0, move_to.y))
				
				# wobble body
				spr_body.rotation = lerp_angle(turn_to + deg2rad(12 * -push_dir), turn_to, abs(0.5 - smooth) * 2.0)
			
			# not pushing
			else:
				# check floor
				if !test_move(transform, rot(Vector2.DOWN * 50)):
					walk_around(push_dir == 1)
					is_end_hold = true
				
				# release button
				elif !btn_push:
					is_end_hold = true
				
				# push / pull
				elif joy.x != 0 and joy_last.x == 0:
					if dir_x == joy.x or !box.test_tile(dir - joy.x, 2):
						
						if box.push(dir - joy.x):
							push_from = position
							push_clock = 0
							push_dir = joy.x
							box.push_x = joy.x
							print("push successful")
						else:
							print("push failed")
				
				# turn box
				elif !box.is_turn and can_spin and joy.y != 0 and joy_last.y == 0:
					box_turn = joy.y * -dir_x
					box.dir += box_turn
					
					#wrench_clock = 0
					#wrench_turn = wrench_angle + deg2rad((joy.y * -dir_x) * 90)
					#wrench.turn(deg2rad((joy.y * -dir_x) * 90))
		
		# end hold
		if is_end_hold:
			is_hold = false
			is_end_hold = false
			is_move = true
			has_jumped = true
			
			remove_collision_exception_with(box)
			box.remove_collision_exception_with(self)
			box.is_hold = false
			
			# move to last child
			var p = box.get_parent()
			p.move_child(box, p.get_child_count())
			
			HUD.show("game")
			
			guide.set_box(null)
			#wrench.set_box(null)
	
	# not holding
	else:
		# turning
		turn_clock = min(turn_clock + delta, turn_time)
		spr_body.rotation = lerp_angle(turn_from, turn_to, smoothstep(0, 1, turn_clock / turn_time))
		if turn_clock == turn_time:
			# on floor
			is_floor = !is_jump and test_move(transform, rot(Vector2.DOWN))
			if is_floor:
				has_jumped = false
			
			# dir_x
			if joy.x != 0:
				set_dir_x(joy.x)
			
			# walking
			if is_walk:
				var target = joy.x * walk_speed 
				var weight = floor_accel if is_floor else air_accel
				velocity.x = lerp(velocity.x, target, weight * delta)
			
			# on the floor
			if is_floor:
				
				# start jump
				if btnp_jump:
					is_floor = false
					#anim.play("jump")
					
					is_jump = true
					has_jumped = true
					velocity.y = jump_speed
					jump_clock = 0.0
				
				# start hold
				elif btnp_push: # and !wrench.is_swing:
					#wrench.swing()
					
					#yield(get_tree().create_timer(0.16), "timeout")
					#yield(wrench, "swing_check")
					
					for i in hit_area.get_overlapping_bodies():
						if i.is_in_group("box") and i.is_floor:
							box = i
							print(name, " holding: ", i.name)
							is_hold = true
							is_end_hold = false
							is_move = false
							velocity = Vector2.ZERO
							
							add_collision_exception_with(box)
							box.add_collision_exception_with(self)
							box.is_hold = true
							push_from = position
							push_clock = 0
							
							if can_spin:
								HUD.show("grab2")
							else:
								HUD.show("grab1")
							
							guide.set_box(box)
							#wrench.set_box(box)
							#wrench.is_swing = false
							
							# move to first child
							var p = box.get_parent()
							p.move_child(box, 0)
							
							break
			
			# in the air
			else:
				
				# during jump
				if is_jump:
					jump_clock += delta
					if btn_jump:
						if velocity.y >= 0.0 or test_move(transform, rot(Vector2(0, -1))):
							is_jump = false
							#print("jump start: ", jump_start, " / jump end: ", position.y + velocity.y, " / distance: ", position.y - jump_start)
					else:
						is_jump = false
						velocity.y *= 0.8
				
				# not jumping
				else:
					# spin
					if !has_jumped:
						walk_around(test_move(transform, rot(Vector2(-25, 25))))
						has_jumped = true
						is_floor = false
		
		# movement
		if is_move:
			# gravity
			velocity.y += (jump_gravity if is_jump else fall_gravity) * delta
			
			# move body
			move_velocity = move_and_slide(rot(velocity))
			velocity = rot(move_velocity, -dir)
	
	
	
	
	# hands
	if is_hold:
		var box_angle = turn_to
		var smooth = 0.2
		if box.is_turn or box.is_push:
			box_angle += box.sprite.rotation - (box.turn_from if box.is_turn else box.turn_to)
			smooth = 1.0
		
		var box_edge = box.sprite.global_position - Vector2(50 * dir_x, 0).rotated(box_angle)
		# move hands
		for i in 2:
			var offset = Vector2(0, 20  * (-1 if sign(dir_x + 1) == i else 1))
			var goto = box_edge + offset.rotated(box_angle)
			hands[i].global_position = hands[i].global_position.linear_interpolate(goto, smooth)
	else:
		# move hands
		for i in 2:
			var goto = position + rot(hand_start * Vector2(1 if i > 0 else -1, 1))
			hands[i].global_position = hands[i].global_position.linear_interpolate(goto, 0.1)
	
	# hand depth
	for i in 2:
		var p = rot(hands[i].position, -dir)
		hands[i].show_behind_parent = sign(p.x) == sign(dir_x) and abs(p.x) > abs(hand_start.x) - 4
	
	
	
#
#	# debug label
#	if is_debug:
#		readout[0] = "dir: " + str(dir)
#		readout[1] = "is_floor: " + str(is_floor)
#		readout[2] = "has_jumped: " + str(has_jumped)
#		readout[3] = "dir_x: " + str(dir_x)
#
#		debug_label.text = ""
#		for i in readout:
#			debug_label.text += str(i) + "\n"

func set_dir_x(arg := dir_x):
	dir_x = sign(arg)
	areas.scale.x = dir_x
	spr_body.scale.x = dir_x

func set_jump_height(arg):
	jump_height = arg
	solve_jump()

func set_jump_time(arg):
	jump_time = arg
	solve_jump()

func solve_jump():
	# Sebastian Lague's formula
	#gravity = -(2 * jumpHeight) / Mathf.Pow (timeToJumpApex, 2);
	#jumpVelocity = Mathf.Abs(gravity) * timeToJumpApex;
	
	jump_gravity = (2 * jump_height) / pow(jump_time, 2)
	jump_speed = -jump_gravity * jump_time
	fall_gravity = jump_gravity * 2.0
	print("jump_speed: ", jump_speed, " / jump_gravity: ", jump_gravity, " / fall_gravity: ", fall_gravity)

func rot(arg : Vector2, _dir := dir):
	return arg.rotated(deg2rad(_dir * 90))

func set_dir(arg := dir):
	dir = posmod(arg, 4)
	turn_to = deg2rad(dir * 90)
	
	turn_clock = 0
	turn_from = spr_body.rotation if spr_body else 0
	
	if Engine.editor_hint:
		if !spr_body: spr_body = $Sprites
		spr_body.rotation = turn_to
	elif camera:
		camera.turn(turn_to)
	
	if areas:
		areas.rotation = turn_to

func walk_around(right := false):
	move_and_collide(rot(Vector2.DOWN))
	set_dir(dir + (1 if right else 3))
	velocity.x = (walk_speed if right else -walk_speed) * 0.72

func hit_effector(pos : Vector2):
	move_and_collide(pos - position)
	velocity = Vector2.ZERO
	is_floor = false
	has_jumped = true
	is_jump = false

func spinner(right := false, pos := Vector2.ZERO):
	set_dir(dir + (1 if right else -1))
	hit_effector(pos)

func arrow(arg, pos):
	if dir != arg:
		set_dir(arg)
		hit_effector(pos)

func portal(pos):
	velocity = Vector2.ZERO
	is_floor = false
	has_jumped = true
	is_jump = false
	
	position = pos

func _on_BodyArea_area_entered(area):
	pass

func _on_BodyArea_body_entered(body):
	if body.is_in_group("spike"):
		print("hit spike")
		die()

func exit(arg):
	if is_exit: return
	is_exit = true
	exit_node = arg
	#anim.play("jump")
	
	if !Shared.is_level_select:
		yield(get_tree().create_timer(0.7), "timeout")
		Shared.complete_level()

func die():
	if is_dead: return
	is_dead = true
	#anim.play("jump")
	#anim_eyes.play("die")
	velocity = Vector2(-350 * dir_x, -800)
	
	if !Shared.is_level_select:
		yield(get_tree().create_timer(0.7), "timeout")
		Shared.reset()

func outside_boundary():
	print(name, " outside boundary")
	die()

func turning(angle):
	pass#spr_body.rotation = angle

func reparent(child, parent):
	remove_child(child)
	parent.add_child(child)
	child.owner = parent
