extends CharacterBody2D

const MAXSPEED: Vector2 = Vector2(500,500)
var speed: float = 30
var fuel: float = 100.0
@export var player_normal_speed: float = 30.0;
@export var player_boosting_speed: float = 60.0;
@onready var fuel_bar: ProgressBar = $FuelBar

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
@export var far_boost : float = 3000.0     # extra pull at full boost
var far_time: float = 0.0
var last_direction

var is_boosting: bool = false
var is_escaping_with_fuel: bool = false
@export var escape_dot_threshold: float = -0.3

@export var countdown_textures: Array[Texture2D] = [] 
@export var left_wing : PackedScene
@export var right_wing : PackedScene

@export var escape_countdown_time: float = 5.0
var escape_timer: float = 5.0
var last_shown_second: int = -1
var default_texture: Texture2D
var ship_is_broken: bool = false

func _ready():
	if isActive:
		$Camera2D.visible = false
		velocity.clamp(-MAXSPEED, MAXSPEED)
		last_direction = Vector2.RIGHT
		speed = player_normal_speed
		default_texture = sprite.texture
		escape_timer = escape_countdown_time

func _process(delta: float) -> void:
	is_boosting = Input.is_action_pressed("Fuel") and fuel > 0.0
	if is_boosting:
		fuel = max(fuel - 10 * delta, 0.0)
		fuel_bar.value = fuel
	speed = player_boosting_speed if is_boosting else player_normal_speed
	#mby need to add particles to show fuel is being used up (or some other visual effect)	

	if is_escaping_with_fuel:
		print("Escaping with fuel!")
		escape_timer -= delta
		var second: int = ceili(escape_timer)
		if second != last_shown_second:
			last_shown_second = second
			var index: int = int(escape_countdown_time) - second 
			if index < countdown_textures.size():
				sprite.texture = countdown_textures[index]
				if index == 4:
					spawn_wing(right_wing, Vector2.RIGHT)
				elif index == 5:
					spawn_wing(left_wing, Vector2.LEFT)

		if escape_timer <= 0.0:
			# Spawn the wings 
			print("ship is broken")
			ship_is_broken = true


func spawn_wing(wing_scene: PackedScene, _side: Vector2) -> void:
	if wing_scene == null:
		return
	var wing = wing_scene.instantiate()
	get_parent().add_child(wing) # parent, so it doesn't follow the ship
	wing.global_position = global_position
	wing.scale = sprite.scale
		

func get_input():
	if ship_is_broken:
		return Vector2.ZERO

	var input_direction = Input.get_vector("left", "right", "up", "down")
	return input_direction

	
func _physics_process(delta: float) -> void:
	if isActive:
		var direction = get_input()
		if direction:
			velocity += direction * speed

			last_direction = direction
			sprite.rotation = lerp_angle(sprite.rotation, last_direction.angle() + deg_to_rad(90), 0.1)
			
			velocity = velocity.clamp(-MAXSPEED, MAXSPEED)
		if gravity_source != null:
			var offset: Vector2 = gravity_source.global_position - global_position
			var distance: float = offset.length()
			# can use distence to check if player in safe orbit
			# just add timer that resets if they leave safe orbit and get win screen if timer runs out

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

			var to_source: Vector2 = offset.normalized()
			is_escaping_with_fuel = (
				is_boosting
				and direction != Vector2.ZERO
				and direction.normalized().dot(to_source) < escape_dot_threshold
			)
			

			print("Distance: ", distance, " Pull: ", pull)
			print("Far Time: ", far_time)
			print("Speed: ", speed)
			
			velocity += offset.normalized() * pull * delta  
			if ship_is_broken:
				velocity = velocity.move_toward(gravity_source.global_position, 30 * delta) 
				
		move_and_slide()
