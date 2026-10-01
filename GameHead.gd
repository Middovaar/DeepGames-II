extends Node2D

var GameScene = preload("res://game.tscn").instantiate()


func _on_main_menu_quit_game():
	get_tree().quit()


func _on_main_menu_start_game():
	LevelChange()
	$MainMenu.queue_free()

func LevelChange() -> void:
	add_child(GameScene)
	print("addscene")
