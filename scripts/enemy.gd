extends CharacterBody2D

enum EnemyStates { IDLE, MOVE, ATTACK }

var direction = -1
var enemy_status:EnemyStates = EnemyStates.IDLE
var rome_states = [EnemyStates.IDLE, EnemyStates.MOVE, EnemyStates.MOVE]
@onready var animation_timer = $effects/animationTimer
@onready var effects = $effects
@onready var currentHealth: int = maxHealth
@export var knockbackPower: int = 100
@export var speed = 60
@export var attack_dash = 200
@export var maxHealth = 2
@onready var ray_cast_r = $RayCastR
@onready var ray_cast_l = $RayCastL
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox_timer = $hitBox/TimerAttackCharge
@onready var timer_attack_end = $hitBox/TimerAttackEnd
@onready var hitbox_collision_shape = $hitBox/CollisionShape2D
@onready var timer_rome = $TimerRome
@onready var attack_ray_cast_r = $hitBox/RayCastR
@onready var attack_ray_cast_l = $hitBox/RayCastL
var allyCollisions = []
func _ready():
	hitbox_collision_shape.disabled = true

func _process(delta):
	velocity.x = move_toward(velocity.x,0,delta)
	
	if timer_rome.is_stopped():
		timer_rome.start()
		enemy_status = rome_states.pick_random()
	
	if attack_ray_cast_r.is_colliding() or attack_ray_cast_l.is_colliding():
		enemy_status = EnemyStates.ATTACK
		
	match enemy_status:
		EnemyStates.MOVE:
			animated_sprite.play("run")
			if ray_cast_r.is_colliding():
				direction = -1
				animated_sprite.flip_h = false
				attack_ray_cast_l.enabled = true
				attack_ray_cast_r.enabled = false
			if ray_cast_l.is_colliding():
				direction = 1
				animated_sprite.flip_h = true
				attack_ray_cast_r.enabled = true
				attack_ray_cast_l.enabled = false
			velocity.x = direction * speed
		EnemyStates.IDLE:
			animated_sprite.play("idle")
			velocity.x = 0
		EnemyStates.ATTACK:
			attack();
	
	move_and_slide()
	
func attack():
	if !timer_attack_end.is_stopped():
		return
		
	velocity.x = 0
	animated_sprite.play("attack")
	hitbox_timer.start()
	timer_attack_end.start()
	await hitbox_timer.timeout
	
	hitbox_collision_shape.disabled = false
	velocity.x = direction * attack_dash
	await timer_attack_end.timeout
	
	hitbox_collision_shape.disabled = true
	enemy_status = EnemyStates.IDLE
	
func hurtBlink():
	effects.play("hurtBlink")
	animation_timer.start()
	await animation_timer.timeout
	effects.play("RESET")

func knockback(area:Area2D):
	var knockbackDirections = (global_position - area.global_position).normalized() * knockbackPower
	print(knockbackDirections.x)
	velocity = knockbackDirections
	
func _on_hurtbox_area_entered(area):
	if area == $hitBox: return
	if area.name == "Projectile":
		allyCollisions.append(area)
		currentHealth -= 1
		if currentHealth <= 0:
			queue_free()
			return
		knockback(area)
		hurtBlink()

