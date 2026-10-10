extends CharacterBody2D

const MAXSPEED: Vector2 = Vector2(500,500)
@export var speed: float = 30
@export var isActive:bool = true
@export var gravity_source: Node2D
@onready var sprite: Sprite2D = $Spaceship

@export var safe_orbit: float = 3000.0 # where pull is weakest
@export var safe_orbit_pull : float = 20.0 # pull at the neutral distance
@export var pull_strength_from_safe : float = 500.0 # how fast pull grows away from neutral
@export var max_pull : float = 4000.0 # maximum pull strength, also for division by zero prevention
@export var momentum_decay : float = 1.0 # how fast momentum decays

@export var far_distance : float = 5000.0   # beyond this, the boost starts building
@export var far_ramp_time : float = 4.0    # max time to reach full boost
@export var far_boost : float = 1500.0     # extra pull at full boost
var far_time: float = 0.0


func _ready():
	if isActive:
		$Camera2D.visible = false
		velocity.clamp(-MAXSPEED, MAXSPEED)

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	return input_direction

	
func _physics_process(delta: float) -> void:
	if isActive:
		var direction = get_input()
		if direction:
			velocity += direction * speed

			var last_direction = direction
			sprite.rotation = lerp_angle(sprite.rotation, last_direction.angle() + deg_to_rad(90), 0.1)
			
			velocity = velocity.clamp(-MAXSPEED, MAXSPEED)
		if gravity_source != null:
			var offset: Vector2 = gravity_source.global_position - global_position
			var distance: float = offset.length()

			var ratio: float = max(distance, 1.0) / safe_orbit
			var pull: float = safe_orbit_pull + pull_strength_from_safe * pow(ratio - 1.0 / ratio, 2)
			pull = min(pull, max_pull)


			# adds extra pull if you are trying to escape, mby can be changed for something better
			# can probably be used for sheding mechanic 
			if distance > far_distance:
				far_time = min(far_time + delta, far_ramp_time)
			else:
				far_time = max(far_time - delta, 0.0)
			pull += far_boost * (far_time / far_ramp_time)


			print("Distance: ", distance, " Pull: ", pull)
			print("Far Time: ", far_time)
			velocity += offset.normalized() * pull * delta  
		move_and_slide()
