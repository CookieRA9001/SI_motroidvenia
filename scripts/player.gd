extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var held_friendly = null 
var friendly_found:Array[CharacterBody2D] = []
var f_index = 0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("swap"):
		swap_friends()
	if Input.is_action_just_pressed("throw"):
		throw_friends()

	var direction = Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	

func swap_friends():
	print("swap")
	
	if len(friendly_found) == 0:
		print("no friends")
		return
	
	if len(friendly_found) == 1:
		print("1 friends")
		held_friendly = friendly_found[0]
		if held_friendly.has_method("holdMe"):
			held_friendly.holdMe()
		return	
	
	var new_f_index = (f_index+1) % len(friendly_found)
	var next_friendly = friendly_found[new_f_index]
	while new_f_index!=f_index and position.distance_to(next_friendly.position)>40:
		new_f_index = (new_f_index+1) % len(friendly_found)
		next_friendly = friendly_found[new_f_index]
	
	if new_f_index == f_index:
		print("no other close friends")
		return
	
	if held_friendly.has_method("unholdMe"):
		held_friendly.unholdMe()
	held_friendly = next_friendly
	if held_friendly.has_method("holdMe"):
		held_friendly.holdMe()
	
	pass
	
func throw_friends():
	# TODO: throw held friendly
	pass
	
func add_friendly(friendly:CharacterBody2D):
	friendly_found.append(friendly)

