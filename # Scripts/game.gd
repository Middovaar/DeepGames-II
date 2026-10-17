extends Node2D

@onready var spaceship: CharacterBody2D = $Spaceship
@onready var blackhole: Area2D = $Blackhole
@onready var win_screen: TextureRect = $ResultScreen/WinScreen
@onready var lose_screen: TextureRect = $ResultScreen/LoseScreen
@onready var blackhole_ambience: AudioStreamPlayer = $Audio/BlackHoleAmbience

@onready var bgm: AudioStreamPlayer = $Audio/BGM
@onready var bgm_next: AudioStreamPlayer = $Audio/BGMNext

@export var bgm_fade_time: float = 2.0
var bgm_fade: Tween

const BGM1: AudioStream = preload("res://# Assets/Audio/BGM1.mp3")
const BGM2: AudioStream = preload("res://# Assets/Audio/BGM2.mp3")
const BGM3: AudioStream = preload("res://# Assets/Audio/BGM3.wav")
const BLACKHOLE_LOSE: Texture2D = preload("res://# Assets/Art-Assets/UI/BlackholeEnding.png")
const TEAR_LOSE: Texture2D = preload("res://# Assets/Art-Assets/UI/LoseScene.png")

@export var bgm_blackhole_distance: float = 2000.0
@export var bgm_outer_distance: float = 5000.0

@export var ambience_far_distance: float = 6500.0
@export var ambience_near_distance: float = 500.0
@export var ambience_far_db: float = -32.0
@export var ambience_near_db: float = -8.0
var game_finished: bool = false
var returning_to_menu := false



func _ready() -> void:
	blackhole.body_entered.connect(_on_blackhole_body_entered)
	spaceship.connect("stable_orbit_completed", _on_stable_orbit_completed)
	spaceship.connect("ship_torn_apart", show_lose_screen)
	update_blackhole_ambience()
	blackhole_ambience.play()
	update_bgm()
func _on_blackhole_body_entered(body: Node2D) -> void:
	if body != spaceship or game_finished:
		return

	show_lose_screen(true)
func _on_stable_orbit_completed() -> void:
	if game_finished:
		return

	game_finished = true
	spaceship.set_process(false)
	spaceship.set_physics_process(false)
	win_screen.show()
func show_lose_screen(consumed_by_blackhole: bool = false) -> void:
	if game_finished:
		return

	game_finished = true
	spaceship.set_process(false)
	spaceship.set_physics_process(false)

	lose_screen.texture = BLACKHOLE_LOSE if consumed_by_blackhole else TEAR_LOSE
	lose_screen.show()
func _process(_delta: float) -> void:
	update_blackhole_ambience()
	update_bgm()

func update_blackhole_ambience() -> void:
	if game_finished or spaceship.call("is_in_stable_orbit"):
		blackhole_ambience.volume_linear = 0.0
		return

	var distance: float = spaceship.global_position.distance_to(blackhole.global_position)
	var closeness: float = clampf(
		(ambience_far_distance - distance)
		/ (ambience_far_distance - ambience_near_distance),
		0.0,
		1.0
	)
	blackhole_ambience.volume_db = lerpf(
		ambience_far_db,
		ambience_near_db,
		closeness
	)
func update_bgm() -> void:
	if game_finished:
		return

	var target_stream: AudioStream

	if spaceship.call("is_in_stable_orbit"):
		target_stream = BGM1
	else:
		var distance: float = spaceship.global_position.distance_to(blackhole.global_position)
		if distance < bgm_blackhole_distance or distance >= bgm_outer_distance:
			target_stream = BGM3
		else:
			target_stream = BGM2

	crossfade_to(target_stream)
func crossfade_to(target_stream: AudioStream) -> void:
	if bgm.stream == target_stream:
		return

	if bgm_fade != null and bgm_fade.is_running():
		return

	# Start the first track immediately.
	if not bgm.playing and not bgm_next.playing:
		bgm.stream = target_stream
		bgm.volume_linear = 1.0
		bgm.play()
		return

	var outgoing: AudioStreamPlayer = bgm
	var incoming: AudioStreamPlayer = bgm_next

	incoming.stream = target_stream
	incoming.volume_linear = 0.0
	incoming.play()

	# Swap the roles of the two players.
	bgm = incoming
	bgm_next = outgoing

	bgm_fade = create_tween().set_parallel(true)
	bgm_fade.tween_property(outgoing, "volume_linear", 0.0, bgm_fade_time)
	bgm_fade.tween_property(incoming, "volume_linear", 1.0, bgm_fade_time)
	bgm_fade.chain().tween_callback(outgoing.stop)
