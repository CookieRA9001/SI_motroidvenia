extends Node2D

@onready var hearts_container = $CanvasLayer/heartsContainer
@onready var player = $Player
var win := false
@onready var boss = $Boss
@onready var timer = $Timer

func _ready():
	hearts_container.setMaxHearts(player.maxHealth)
	hearts_container.updateHearts(player.currentHealth)
	player.healthChanged.connect(hearts_container.updateHearts)
	
func _process(delta):
	if !boss and !win:
		win = true
		timer.start()
		await timer.timeout
		get_tree().change_scene_to_file("res://sceans/win_menu.tscn")
	
