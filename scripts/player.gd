extends CharacterBody2D

@onready var timer = $hurtbox/Timer
@onready var animation_timer = $effects/animationTimer
@onready var coyote_timer = $Timers/CoyoteTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var effects = $effects

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var held_friendly = null 
var friendly_found:Array[CharacterBody2D] = []
var f_index = 0
@export var BoostPower: int = 1000
@export var maxHealth = 3
@onready var currentHealth: int = maxHealth
@export var knockbackPower: int = 500
@export var speed: float = 350
@export var jumpVelocity: float = -700

var isHurt: bool = false
var enemyCollisions = []

func _ready():
	effects.play("RESET")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if isHurt:
		move_and_slide()
		return

	if Input.is_action_just_pressed("jump") and (is_on_floor() or !coyote_timer.is_stopped()):
		velocity.y = jumpVelocity
	if Input.is_action_just_pressed("swap"):
		swap_friends()
	if Input.is_action_just_pressed("throw"):
		throw_friends()

	var direction = Input.get_axis("move_left", "move_right")
	
	if direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run") 
	
	if direction > 0:
		animated_sprite.flip_h = true
	elif direction < 0:
		animated_sprite.flip_h = false
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	if currentHealth > 0:
		for enemyArea in enemyCollisions:
			hurtByEnemy(enemyArea)
			
	var floored = is_on_floor()
	move_and_slide()
	if is_on_floor() != floored and floored:
		coyote_timer.start()

## FRIENDLIES

func swap_friends():
	if len(friendly_found) == 0:
		return
	
	if len(friendly_found) == 1:
		held_friendly = friendly_found[0]
		if held_friendly.has_method("holdMe") and position.distance_to(held_friendly.position)<80:
			held_friendly.holdMe()
		return
	
	var new_f_index = (f_index+1) % len(friendly_found)
	var next_friendly = friendly_found[new_f_index]
	while new_f_index!=f_index and position.distance_to(next_friendly.position)>80:
		new_f_index = (new_f_index+1) % len(friendly_found)
		next_friendly = friendly_found[new_f_index]
	
	if new_f_index == f_index and position.distance_to(next_friendly.position)>80:
		return
	
	if held_friendly!=null and held_friendly.has_method("unholdMe"):
		held_friendly.unholdMe()
	held_friendly = next_friendly
	if held_friendly.has_method("holdMe"):
		held_friendly.holdMe()
	f_index = new_f_index
	
func throw_friends():
	if held_friendly == null:
		return
	
	var direction = Vector2(1,0)
	if !animated_sprite.flip_h:
		direction.x = -1
	if Input.is_action_pressed("up"):
		direction.x = 0
		direction.y = -1
	elif Input.is_action_pressed("down"):
		direction.x = 0
		direction.y = 1
		velocity.y = -BoostPower
	
	if held_friendly.has_method("throwMe"):
		held_friendly.throwMe(direction)
		
	held_friendly = null

func add_friendly(friendly:CharacterBody2D):
	friendly_found.append(friendly)

## PAIN

func hurtByEnemy(area:Area2D):
	#print_debug(area.get_parent().name)
	currentHealth -= 1
	animated_sprite.play("idle") # TODO: switch to damage animation, if added?
	$hurt.play()
	if currentHealth <= 0:
		#print("You died!")
		isHurt = true
		knockback(area)
		Engine.time_scale = 0.5
		effects.play("hurtBlink")
		timer.start()
		await timer.timeout
		Engine.time_scale = 1
		get_tree().reload_current_scene()
		return
		
	knockback(area)
	hurtBlink()

func hurtBlink():
	isHurt = true
	effects.play("hurtBlink")
	animation_timer.start()
	await animation_timer.timeout
	effects.play("RESET")
	isHurt = false

func knockback(area:Area2D):
	var knockbackDirections = (global_position - area.global_position).normalized() * knockbackPower
	#print(knockbackDirections.x)
	velocity = knockbackDirections

func _on_hurtbox_area_entered(area):
	if area.name == "hitBox":
		enemyCollisions.append(area)

func _on_hurtbox_area_exited(area):
	enemyCollisions.erase(area)
	
