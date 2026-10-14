extends CharacterBody2D
signal stable_orbit_completed
signal ship_torn_apart
const MAXSPEED: Vector2 = Vector2(500,500)
var speed: float = 30
var fuel: float = 100.0
@export var player_normal_speed: float = 30.0;
@export var player_boosting_speed: float = 60.0;
@onready var fuel_bar: ProgressBar = $FuelBar

@export var isActive:bool = true
@export var gravity_source: Node2D
@onready var sprite: Sprite2D = $Spaceship
@onready var orbit_camera: Camera2D = $Camera2D

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
enum OrbitState { OUTSIDE, UNSTABLE, STABLE }

var orbit_state: OrbitState = OrbitState.OUTSIDE
var last_reported_orbit_state: OrbitState = OrbitState.OUTSIDE
var auto_orbit_active: bool = false
var locked_orbit_radius: float = 0.0
var locked_orbit_speed: float = 0.0
var orbit_direction: float = 1.0
var orbit_exit_hold: float = 0.0

var stable_orbit_time: float = 0.0
var win_condition_sent: bool = false

@export var unstable_shake_strength: float = 35.0
var sprite_base_position: Vector2 = Vector2.ZERO

@export var orbit_exit_hold_time: float = 3.0 
@export var unstable_inner_radius: float = 5800.0
@export var unstable_outer_radius: float = 6200.0
@export var escape_intent_time: float = 1.0

var escape_held_time: float = 0.0
var unstable_armed: bool = true

@export var unstable_entry_grace: float = 0.8
@export var unstable_exit_hold_time: float = 0.5

var unstable_age: float = 0.0
var unstable_exit_hold: float = 0.0
var unstable_input_released: bool = false
@export var unstable_idle_tear_time: float = 8.0
var unstable_idle_time: float = 0.0

@export var stable_distance_tolerance: float = 350.0
@export var stable_max_radial_speed: float = 200.0
@export var stable_min_tangential_speed: float = 80.0
func _ready():
	if isActive:
		velocity.clamp(-MAXSPEED, MAXSPEED)
		last_direction = Vector2.RIGHT
		speed = player_normal_speed
		default_texture = sprite.texture
		sprite_base_position = sprite.position
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

		if escape_timer <= 0.0 and not ship_is_broken:
			ship_is_broken = true
			print("ship is broken")
			ship_torn_apart.emit()
	if orbit_state == OrbitState.UNSTABLE:
		sprite.position = sprite_base_position + Vector2(
			randf_range(-unstable_shake_strength, unstable_shake_strength),
			randf_range(-unstable_shake_strength, unstable_shake_strength)
		)
	else:
		sprite.position = sprite_base_position
	if (
		orbit_state == OrbitState.UNSTABLE
		and Input.get_vector("left", "right", "up", "down") == Vector2.ZERO
		and not is_boosting
	):
		unstable_idle_time += delta
	else:
		unstable_idle_time = 0.0

	if unstable_idle_time >= unstable_idle_tear_time and not ship_is_broken:
		ship_is_broken = true
		print("Ship torn apart in unstable orbit")
		ship_torn_apart.emit()
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
		if auto_orbit_active and orbit_state == OrbitState.UNSTABLE:
			update_orbit_state(delta, direction)
			auto_orbit_active = orbit_state == OrbitState.UNSTABLE
		elif auto_orbit_active:
			if is_boosting:
				auto_orbit_active = false
			elif direction != Vector2.ZERO:
				orbit_exit_hold += delta
				if orbit_exit_hold >= orbit_exit_hold_time:
					auto_orbit_active = false
			else:
				orbit_exit_hold = 0.0

		if not auto_orbit_active and orbit_state == OrbitState.STABLE \
				and direction == Vector2.ZERO and not is_boosting:
			begin_auto_orbit()

		if auto_orbit_active:
			move_in_auto_orbit()

			if orbit_state == OrbitState.STABLE and direction == Vector2.ZERO and not is_boosting:
				stable_orbit_time += delta
			else:
				stable_orbit_time = 0.0

			if stable_orbit_time >= 10.0 and not win_condition_sent:
				win_condition_sent = true
				print("WIN CONDITION MET")
				stable_orbit_completed.emit()

			if orbit_state == OrbitState.STABLE:
				orbit_camera.zoom = Vector2(0.125, 0.125)
			else:
				orbit_camera.zoom = Vector2(0.08, 0.08)
			orbit_camera.global_position = gravity_source.global_position
			return
		stable_orbit_time = 0.0
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
			

			#print("Distance: ", distance, " Pull: ", pull)
			#print("Far Time: ", far_time)
			#print("Speed: ", speed)
			
			velocity += offset.normalized() * pull * delta  
			if ship_is_broken:
				velocity = velocity.move_toward(gravity_source.global_position, 30 * delta) 
				
		move_and_slide()
		update_orbit_state(delta, direction)
		if orbit_state == OrbitState.STABLE:
			orbit_camera.zoom = Vector2(0.125, 0.125)
			orbit_camera.global_position = gravity_source.global_position
		elif orbit_state == OrbitState.UNSTABLE:
			orbit_camera.zoom = Vector2(0.1, 0.1)
			orbit_camera.global_position = gravity_source.global_position
		else:
			orbit_camera.zoom = Vector2(0.4, 0.4)
			orbit_camera.position = Vector2.ZERO
		if orbit_state != last_reported_orbit_state:
			print("Orbit: ", OrbitState.keys()[orbit_state])
			last_reported_orbit_state = orbit_state
func update_orbit_state(delta: float, direction: Vector2) -> void:
	if gravity_source == null:
		orbit_state = OrbitState.OUTSIDE
		return

	var from_hole: Vector2 = global_position - gravity_source.global_position
	var distance: float = from_hole.length()
	var outward: Vector2 = from_hole.normalized()
	var radial_speed: float = velocity.dot(outward)
	var tangential_speed: float = (velocity - outward * radial_speed).length()
	var in_unstable_band: bool = (
		distance >= unstable_inner_radius
		and distance <= unstable_outer_radius
	)

	# Returning toward the black hole allows a future escape attempt.
	if distance < unstable_inner_radius - 200.0:
		unstable_armed = true

	# Once caught in unstable orbit, stay there until the player escapes
	# or the ship leaves the narrow band.
	if orbit_state == OrbitState.UNSTABLE:
		unstable_age += delta

		if direction == Vector2.ZERO:
			unstable_input_released = true
			unstable_exit_hold = 0.0

		if unstable_age >= unstable_entry_grace:
			if is_boosting:
				orbit_state = OrbitState.OUTSIDE
			elif unstable_input_released and direction != Vector2.ZERO:
				unstable_exit_hold += delta
				if unstable_exit_hold >= unstable_exit_hold_time:
					orbit_state = OrbitState.OUTSIDE

		if orbit_state == OrbitState.OUTSIDE:
			escape_held_time = 0.0
			unstable_exit_hold = 0.0
		return

	# Keep the existing stable-orbit conditions.
	if (
		absf(distance - safe_orbit) <= stable_distance_tolerance
		and absf(radial_speed) <= stable_max_radial_speed
		and tangential_speed >= stable_min_tangential_speed
	):
		orbit_state = OrbitState.STABLE
		escape_held_time = 0.0
		return

	# Normal flight is the default, including the approach to the black hole.
	orbit_state = OrbitState.OUTSIDE

	if direction.dot(outward) > 0.5:
		escape_held_time += delta
	else:
		escape_held_time = 0.0

	if (
		unstable_armed
		and in_unstable_band
		and escape_held_time >= escape_intent_time
	):
		orbit_state = OrbitState.UNSTABLE
		unstable_armed = false
		unstable_age = 0.0
		unstable_exit_hold = 0.0
		unstable_input_released = false
		begin_auto_orbit(OrbitState.UNSTABLE)
func begin_auto_orbit(new_state: OrbitState = OrbitState.STABLE) -> void:
	var from_hole: Vector2 = global_position - gravity_source.global_position
	var outward: Vector2 = from_hole.normalized()
	var tangent: Vector2 = Vector2(-outward.y, outward.x)

	locked_orbit_radius = from_hole.length()
	orbit_direction = 1.0 if velocity.dot(tangent) >= 0.0 else -1.0
	locked_orbit_speed = maxf(absf(velocity.dot(tangent)), stable_min_tangential_speed)

	if new_state == OrbitState.UNSTABLE:
		locked_orbit_speed = maxf(locked_orbit_speed, MAXSPEED.x)

	orbit_exit_hold = 0.0
	is_escaping_with_fuel = false
	orbit_state = new_state
	auto_orbit_active = true
	


func move_in_auto_orbit() -> void:
	var from_hole: Vector2 = global_position - gravity_source.global_position
	var outward: Vector2 = from_hole.normalized()
	var tangent: Vector2 = Vector2(-outward.y, outward.x)
	var radius_error: float = from_hole.length() - locked_orbit_radius

	velocity = tangent * orbit_direction * locked_orbit_speed - outward * radius_error * 2.0
	move_and_slide()
