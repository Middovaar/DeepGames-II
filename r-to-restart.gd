extends Node

@onready var lose_screen: TextureRect = $"../ResultScreen/LoseScreen"

var restarting: bool = false


func _input(event: InputEvent) -> void:
	if restarting or not event.is_action_pressed("Restart"):
		return

	restarting = true

	if lose_screen.visible:
		get_tree().call_deferred(
			"change_scene_to_file",
			"res://RetryDialogue.tscn"
		)
	else:
		get_tree().call_deferred("reload_current_scene")
