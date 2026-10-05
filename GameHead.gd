extends Node2D

var GameScene = preload("res://game.tscn").instantiate()
var IntroScene = preload("res://StartCutscene.tscn").instantiate()


func _on_main_menu_quit_game():
	get_tree().quit()


func _on_main_menu_start_game():
	StartGameCutscene()
	$MainMenu.queue_free()

func StartGameCutscene() -> void:
	add_child(IntroScene)
	$StartCutscene.GoToGame.connect(CutsceneFinish)

func CutsceneFinish():
	get_child(0).queue_free()
	IntroScene = preload("res://StartCutscene.tscn").instantiate()
	add_child(GameScene)
