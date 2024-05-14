extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0

@onready var timer = $hurtbox/Timer
@onready var animation_timer = $effects/animationTimer


@onready var animated_sprite = $AnimatedSprite2D
@onready var effects = $effects


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var held_friendly = null 
var friendly_found:Array[CharacterBody2D] = []
var f_index = 0

@export var maxHealth = 3
@onready var currentHealth: int = maxHealth
@export var knockbackPower: int = 1000

var isHurt: bool = false
var enemyCollisions = []

func _ready():
	effects.play("RESET")

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
	if !isHurt:
		for enemyArea in enemyCollisions:
			hurtByEnemy(enemyArea)

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
	
	if held_friendly == null:
		while held_friendly == null:
			held_friendly = friendly_found[f_index % len(friendly_found)]
	
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
	f_index = new_f_index
	
func throw_friends():
	# TODO: throw held friendly
	pass
	
func add_friendly(friendly:CharacterBody2D):
	friendly_found.append(friendly)

func hurtByEnemy(area):
	print_debug(area.get_parent().name)
	currentHealth -= 1
	if currentHealth <= 0:
		print("You died!")
		hurtBlink()
		Engine.time_scale = 0.5
		timer.start()
		await timer.timeout
		Engine.time_scale = 1
		get_tree().reload_current_scene()
	knockback()
	hurtBlink()

func _on_hurtbox_area_entered(area):
	if area.name == "hitBox":
		enemyCollisions.append(area)

func hurtBlink():
	isHurt = true
	effects.play("hurtBlink")
	animation_timer.start()
	await animation_timer.timeout
	effects.play("RESET")
	isHurt = false

func knockback():
	var knockbackDirections = -velocity.normalized() * knockbackPower
	velocity = knockbackDirections
	move_and_slide()


func _on_hurtbox_area_exited(area):
	enemyCollisions.erase(area)
	
