extends Node2D

@onready var spaceship: CharacterBody2D = $Spaceship
@onready var blackhole: Area2D = $Blackhole
@onready var win_screen: TextureRect = $ResultScreen/WinScreen
@onready var lose_screen: TextureRect = $ResultScreen/LoseScreen
var game_finished: bool = false
var returning_to_menu := false



func _ready() -> void:
	blackhole.body_entered.connect(_on_blackhole_body_entered)
	spaceship.connect("stable_orbit_completed", _on_stable_orbit_completed)
	spaceship.connect("ship_torn_apart", show_lose_screen)
func _on_blackhole_body_entered(body: Node2D) -> void:
	if body != spaceship or game_finished:
		return

	show_lose_screen()
func _on_stable_orbit_completed() -> void:
	if game_finished:
		return

	game_finished = true
	spaceship.set_process(false)
	spaceship.set_physics_process(false)
	win_screen.show()
func show_lose_screen() -> void:
	if game_finished:
		return

	game_finished = true
	spaceship.set_process(false)
	spaceship.set_physics_process(false)
	lose_screen.show()
