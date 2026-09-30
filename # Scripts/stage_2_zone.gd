class_name StageZone
extends Area2D

signal player_entered(stage_number: int)

@export_range(1, 5) var stage_number: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(stage_number)
