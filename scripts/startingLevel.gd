extends Node2D

@onready var hearts_container = $CanvasLayer/heartsContainer
@onready var player = $Player
# Called when the node enters the scene tree for the first time.
func _ready():
	hearts_container.setMaxHearts(player.maxHealth)
	hearts_container.updateHearts(player.currentHealth)
	player.healthChanged.connect(hearts_container.updateHearts)
