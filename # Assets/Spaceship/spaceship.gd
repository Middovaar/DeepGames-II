extends CharacterBody2D

@export var speed = 400
@export var isActive:bool = true

func get_input():
	if isActive:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		velocity = input_direction * speed

func _physics_process(delta):
	if isActive:
		get_input()
		move_and_slide()
	pass
