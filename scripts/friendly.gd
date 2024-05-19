extends CharacterBody2D

enum Status { IDLE, FOLLOWING, INACTION, MOVING, HELD, FLYBACK }
@onready var animation_player = $AnimationPlayer
@onready var projectile:CollisionShape2D = $Projectile/Projectile
@onready var hitbox = $Hitbox
@export var jumpY_velocity := -400
@export var jumpX_velocity := 200
@export var jumpX_decel := 10
@export var throw_force := 800
var friendly_status = Status.IDLE
var current_x_speed = 0
var target:Node2D = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func follow():
	if position.distance_to(target.position) > 500:
		friendly_status = Status.FLYBACK
		velocity = Vector2.ZERO
	
	if position.distance_to(target.position)>20 and is_on_floor():
		velocity.y = jumpY_velocity
		$jump.play()
		var direction = 1 if (target.position.x-position.x > 0) else -1 
		current_x_speed = direction * clamp(position.distance_to(target.position)*randf_range(1,3), 0, jumpX_velocity)
		velocity.x = current_x_speed
		friendly_status = Status.MOVING

func move():
	if position.distance_to(target.position) > 500:
		friendly_status = Status.FLYBACK
		velocity = Vector2.ZERO
	elif is_on_floor():
		friendly_status = Status.FOLLOWING
		velocity.x = 0
		return
	else:
		velocity.x = current_x_speed

func flyBack(delta):
	if position.distance_to(target.position) > 100 or position.y > target.position.y-20:
		position = position.move_toward(target.position+Vector2(0,-30), delta*700)
		hitbox.disabled = true
	else:
		friendly_status = Status.MOVING
		hitbox.disabled = false

func idle():
	pass
	
func inAction(delta):
	if position.distance_to(target.position) > 1000:
		friendly_status = Status.FLYBACK
		velocity = Vector2.ZERO
		return
		
	var collision = move_and_collide(velocity * delta * 2)
	if collision:
		animation_player.play("trown")
		velocity = velocity.bounce(collision.get_normal()) * 0.75
		$bounce.play()
		if abs(velocity.x)+abs(velocity.y) < 20:
			friendly_status = Status.MOVING
			
	projectile.disabled = (abs(velocity.x)+abs(velocity.y) < 10)

func hold(delta):
	if position.distance_to(target.position) > 50:
		position = position.move_toward(target.position, delta*300)
		
	else:
		position = target.position

func _physics_process(delta):
	if not is_on_floor() and not (friendly_status==Status.HELD or friendly_status==Status.FLYBACK):
		velocity.y += gravity * delta
		animation_player.play("idle")
		
	if friendly_status != Status.FLYBACK and !projectile.disabled:
		projectile.disabled = true
	
	match friendly_status:
		Status.IDLE:
			idle()
		Status.FOLLOWING:
			follow()
		Status.INACTION:
			inAction(delta)
		Status.MOVING:
			move()
		Status.HELD:
			hold(delta)
		Status.FLYBACK:
			flyBack(delta)
			
	if friendly_status != Status.INACTION:
		move_and_slide()

func holdMe():
	if friendly_status != Status.HELD:
		$Hold.play()
		animation_player.play("hold")
	velocity = Vector2(0,0);
	friendly_status = Status.HELD
	
func unholdMe():
	friendly_status = Status.FOLLOWING
	velocity = Vector2(randf_range(-50,50),randf_range(-100,-300))
	animation_player.play("idle")
	
func throwMe(dir:Vector2):
	friendly_status = Status.INACTION
	velocity = dir * throw_force

func _on_area_2d_body_entered(body):
	if friendly_status == Status.IDLE:
		friendly_status = Status.FOLLOWING
		target = body
		
		if body.has_method("add_friendly"):
			body.add_friendly(self)
			
