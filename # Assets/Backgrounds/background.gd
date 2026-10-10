extends Node2D

@export var ControllableStars:bool = true
@export var SpaceSpeed: Vector2 = Vector2.ZERO # Bounded between -1.0 and 1.0
var _star_offset: Vector2 = Vector2.ZERO

@export var speed_multiplier: float = 80.0 # Adjusts how fast the stars scroll
@onready var stars_sprite: Sprite2D = $Stars

func _process(delta: float) -> void:
	# Integrate  smoothly so stars don't teleport when SpaceSpeed changes
	_star_offset += SpaceSpeed * speed_multiplier * delta
	
	if stars_sprite.material:
		# Pass the integrated offset to translate the stars
		stars_sprite.material.set_shader_parameter("global_offset", _star_offset)
		
		# Pass the raw bounded SpaceSpeed to calculate the smear length
		stars_sprite.material.set_shader_parameter("SpaceSpeed", SpaceSpeed)

func _physics_process(delta):
	if ControllableStars:
		SpaceSpeed = Vector2.ZERO
