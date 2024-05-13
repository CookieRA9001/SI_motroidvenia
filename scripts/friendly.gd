extends Area2D

enum Status { IDLE, FOLLOWING, INACTION }

var friendly_status = Status.IDLE
var target:Node2D = null

func _on_body_entered(body):
	if friendly_status == Status.IDLE:
		friendly_status = Status.FOLLOWING
		target = body
		
func follow(delta):
	if position.distance_to(target.position)>20:
		position = target.position + Vector2(randf_range(-5.0,5.0),0);
		
	pass
	
func idle(delta):
	pass
	
func inAction(delta):
	pass

func _process(delta):
	match friendly_status:
		Status.IDLE:
			idle(delta)
		Status.FOLLOWING:
			follow(delta)
		Status.INACTION:
			inAction(delta)

