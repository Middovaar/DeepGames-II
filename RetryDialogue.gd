extends Control

@onready var textbox: Textbox = $Textbox
@onready var background = $Background


func _ready() -> void:
	background.ControllableStars = false
	background.SpaceSpeed = Vector2(0.15, 0.0)

	textbox.FinishedDialogue.connect(_on_dialogue_finished)
	textbox.DialogueRequest("Retry")


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id == "Retry":
		get_tree().call_deferred("change_scene_to_file", "res://game.tscn")
