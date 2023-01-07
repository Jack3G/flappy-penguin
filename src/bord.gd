extends CharacterBody2D


@export var flap_strength: float = 120
@export var terminal_velocity: float = 120

@export var max_angle: float = 0.5
@export var min_angle: float = -0.5

@onready var sprite: Node2D = $AnimatedSprite2D


func get_gravity() -> Vector2:
	return ProjectSettings.get_setting("physics/2d/default_gravity") *\
		ProjectSettings.get_setting("physics/2d/default_gravity_vector")


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("flap"):
		velocity.y = -flap_strength
	
	velocity += get_gravity() * delta
	
	velocity.y = clampf(velocity.y, -terminal_velocity, terminal_velocity)
	
	var turn_fraction: float = clampf(
		(velocity.y + flap_strength)/(flap_strength * 2),
		0,
		1,
	)
	
	sprite.rotation = lerp(min_angle, max_angle, turn_fraction)
	
	var had_collision = move_and_slide()
	
	if had_collision:
		print("you ded")
