extends CharacterBody2D

@export var speed = 400
@export var isActive:bool = true

func _ready():
	if isActive:
		$Spaceship/Camera2D.visible = false

func get_input():
	if isActive:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		velocity = input_direction * speed

var auto_target: Node2D = null


func start_auto_flight(target: Node2D) -> void:
	auto_target = target
	isActive = false

func stop_auto_flight() -> void:
	auto_target = null
	velocity = Vector2.ZERO
	
func _physics_process(_delta: float) -> void:
	if auto_target != null:
		velocity = global_position.direction_to(auto_target.global_position) * speed
		move_and_slide()
		return

	if isActive:
		get_input()
		move_and_slide()
