extends Node2D

@onready var stage_manager = $StageManager
@onready var spaceship = $Spaceship
@onready var blackhole = $Blackhole


func _ready() -> void:
	stage_manager.stage_changed.connect(_on_stage_changed)
	blackhole.body_entered.connect(_on_blackhole_body_entered)


func _on_stage_changed(_old_stage: int, new_stage: int) -> void:
	if new_stage == 5:
		spaceship.start_auto_flight(blackhole)

func _on_blackhole_body_entered(body: Node2D) -> void:
	if body != spaceship or stage_manager.current_stage != 5:
		return

	spaceship.stop_auto_flight()
	print("Reached black hole")
