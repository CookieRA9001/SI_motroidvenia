extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

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
	# TODO: swap between near friendlies
	pass
	
func throw_friends():
	# TODO: throw held friendly
	pass
