extends ProgressBar

var fuel: float = 100.0
@export var player_speed: float;
@export var player_boosting_speed: float;
@export var player_normal_speed: float;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("Fuel"):
		fuel -= 10 * delta
		if fuel < 0:
			fuel = 0
		value = fuel
		if fuel != 0:
			player_speed = player_boosting_speed
		else:
			player_speed = player_normal_speed
		#depending on how player speed is set up can change how this is handled