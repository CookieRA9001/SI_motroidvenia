extends CharacterBody2D

enum Status { IDLE, FOLLOWING, INACTION, MOVING, HELD }

@export var jumpY_velocity := -400
@export var jumpX_velocity := 200
@export var jumpX_decel := 10
@export var throw_force := 800
var friendly_status = Status.IDLE
var current_x_speed = 0
var target:Node2D = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var state_machine

func _ready():
	state_machine = $AnimationTree.get("parameters/playback")

func follow(delta):
	if position.distance_to(target.position)>20 and is_on_floor():
		velocity.y = jumpY_velocity
		var direction = 1 if (target.position.x-position.x > 0) else -1 
		current_x_speed = direction * clamp(position.distance_to(target.position)*randf_range(1,3), 0, jumpX_velocity)
		velocity.x = current_x_speed
		friendly_status = Status.MOVING

func move(delta):
	if is_on_floor():
		friendly_status = Status.FOLLOWING
		velocity.x = 0
		return
	else:
		velocity.x = current_x_speed

func idle(delta):
	pass
	
func inAction(delta):
	var collision = move_and_collide(velocity * delta * 2)
	if collision:
		state_machine.travel("trown")
		velocity = velocity.bounce(collision.get_normal()) * 0.75
		if abs(velocity.x)+abs(velocity.y) < 15:
			friendly_status = Status.MOVING

func hold(delta):
	if position.distance_to(target.position) > 50:
		position = position.move_toward(target.position, delta*300)
		state_machine.travel("hold")
	else:
		position = target.position

func _physics_process(delta):
	if not is_on_floor() and not friendly_status==Status.HELD:
		velocity.y += gravity * delta
		state_machine.travel("idle")
	
	match friendly_status:
		Status.IDLE:
			idle(delta)
		Status.FOLLOWING:
			follow(delta)
		Status.INACTION:
			inAction(delta)
		Status.MOVING:
			move(delta)
		Status.HELD:
			hold(delta)
			
	if friendly_status != Status.INACTION:
		move_and_slide()

func holdMe():
	velocity = Vector2(0,0);
	friendly_status = Status.HELD
	
func unholdMe():
	friendly_status = Status.FOLLOWING
	velocity = Vector2(randf_range(-50,50),randf_range(-100,-300))
	state_machine.travel("idle")
	
func throwMe(dir:Vector2):
	friendly_status = Status.INACTION
	velocity = dir * throw_force

func _on_area_2d_body_entered(body):
	if friendly_status == Status.IDLE:
		friendly_status = Status.FOLLOWING
		target = body
		
		if body.has_method("add_friendly"):
			body.add_friendly(self)
