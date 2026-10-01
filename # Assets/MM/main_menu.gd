extends Node2D

signal QuitGame
signal StartGame

func _on_quit_pressed():
	emit_signal("QuitGame")

func _on_start_pressed():
	emit_signal("StartGame")
