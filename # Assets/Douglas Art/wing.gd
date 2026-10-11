extends Sprite2D

var rotation_speed: float 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_speed = randf_range(90.0, -90.0)  


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(deg_to_rad(rotation_speed) * delta)  # Rotate the sprite at 90 degrees per second
