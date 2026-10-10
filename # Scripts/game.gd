extends Node2D

@onready var spaceship: CharacterBody2D = $Spaceship
@onready var blackhole: Area2D = $Blackhole

var returning_to_menu := false


func _ready() -> void:
	blackhole.body_entered.connect(_on_blackhole_body_entered)


func _on_blackhole_body_entered(body: Node2D) -> void:
	if body != spaceship or returning_to_menu:
		return

	returning_to_menu = true
	get_tree().call_deferred("change_scene_to_file", "res://head.tscn")
