extends Node

signal stage_changed(old_stage: int, new_stage: int)

var current_stage: int = 1


func _ready() -> void:
	for child in get_children():
		if child is StageZone:
			var zone := child as StageZone
			zone.player_entered.connect(enter_stage)


func enter_stage(new_stage: int) -> void:
	if new_stage < 1 or new_stage > 5:
		push_warning("Stage must be between 1 and 5.")
		return

	if new_stage == current_stage:
		return

	var old_stage: int = current_stage
	current_stage = new_stage
	stage_changed.emit(old_stage, new_stage)
	print("Stage ", old_stage, " -> ", new_stage)
