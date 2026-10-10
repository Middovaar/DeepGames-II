extends CharacterBody2D

const MAXSPEED: Vector2 = Vector2(4000,4000)
@export var speed: float = 30
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
		if direction:
			velocity += direction * speed
			velocity = velocity.clamp(-MAXSPEED, MAXSPEED)
			print_debug(velocity)
		if gravity_source != null:
			var offset: Vector2 = gravity_source.global_position - global_position
			var distance: float = offset.length()

			if distance < gravity_radius and distance > 1.0:
				var proximity: float = 1.0 - distance / gravity_radius
				var pull: float = gravity_strength * proximity * proximity
				velocity += offset.normalized() * pull * delta
		move_and_slide()
