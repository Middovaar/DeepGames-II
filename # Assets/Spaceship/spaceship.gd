extends CharacterBody2D

@export var max_speed: float = 400
@export var acceleration: float = 10
@export var friction: float = 5
@export var isActive:bool = true
@export var gravity_source: Node2D
@export var gravity_radius: float = 1000.0
@export var gravity_strength: float = 5000.0
func _ready():
	if isActive:
		$Spaceship/Camera2D.visible = false

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	return input_direction

	
func _physics_process(delta: float) -> void:

	if isActive:
		var direction = get_input()
		var velocity_weight: float = delta * (acceleration if direction else friction)
		velocity = lerp(velocity, direction * max_speed, velocity_weight)
		if gravity_source != null:
			var offset: Vector2 = gravity_source.global_position - global_position
			var distance: float = offset.length()

			if distance < gravity_radius and distance > 1.0:
				var proximity: float = 1.0 - distance / gravity_radius
				var pull: float = gravity_strength * proximity * proximity
				velocity += offset.normalized() * pull * delta
		move_and_slide()
