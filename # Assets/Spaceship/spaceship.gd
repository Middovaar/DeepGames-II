extends CharacterBody2D

@export var speed = 400
@export var max_speed: float = 400
@export var acceleration: float = 10
@export var friction: float = 5
@export var isActive:bool = true

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	return input_direction

var auto_target: Node2D = null


func start_auto_flight(target: Node2D) -> void:
	auto_target = target
	isActive = false

func stop_auto_flight() -> void:
	auto_target = null
	velocity = Vector2.ZERO
	
func _physics_process(delta: float) -> void:
	if auto_target != null:
		velocity = global_position.direction_to(auto_target.global_position) * speed
		move_and_slide()
		return

	if isActive:
		var direction = get_input()
		var velocity_weight: float = delta * (acceleration if direction else friction)
		velocity = lerp(velocity, direction * max_speed, velocity_weight)
		move_and_slide()
