extends Node2D

@onready var stage_manager = $StageManager
@onready var spaceship = $Spaceship
@onready var blackhole = $Blackhole
@onready var white_screen: ColorRect = $EndingOverlay/WhiteScreen

var ending_started: bool = false


func _ready() -> void:
	stage_manager.stage_changed.connect(_on_stage_changed)
	blackhole.body_entered.connect(_on_blackhole_body_entered)


func _on_stage_changed(_old_stage: int, new_stage: int) -> void:
	if new_stage == 5:
		spaceship.start_auto_flight(blackhole)

func _on_blackhole_body_entered(body: Node2D) -> void:
	if body != spaceship or stage_manager.current_stage != 5 or ending_started:
		return

	ending_started = true
	spaceship.stop_auto_flight()

	var fade := create_tween()
	fade.tween_property(white_screen, "modulate:a", 1.0, 1.5)
	await fade.finished

	get_tree().paused = true
