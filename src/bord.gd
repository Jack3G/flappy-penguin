extends CharacterBody2D


@export var flap_strength: float = 120
@export var terminal_velocity: float = 120

@export var max_angle: float = 0.5
@export var min_angle: float = -0.5

# how many pixels he can be off screen before dying
@export var off_screen_zone: float = 20

@onready var sprite: Node2D = $AnimatedSprite2D

var dead: bool = false
var frozen: bool = true

@onready var jetpack_particles: GPUParticles2D = $JetpackParticles

signal died
signal unfrozen


func get_gravity() -> Vector2:
	return ProjectSettings.get_setting("physics/2d/default_gravity") *\
		ProjectSettings.get_setting("physics/2d/default_gravity_vector")


func _physics_process(delta: float) -> void:
	if not dead and Input.is_action_just_pressed("flap"):
		velocity.y = -flap_strength
		if frozen:
			frozen = false
			emit_signal("unfrozen")
	
	if not frozen:
		velocity += get_gravity() * delta
		
		velocity.y = clampf(velocity.y, -terminal_velocity, terminal_velocity)
		velocity.x = 0 # just in case
		
		var turn_fraction: float = clampf(
			(velocity.y + flap_strength)/(flap_strength * 2),
			0,
			1,
		)
		
		sprite.rotation = lerp(min_angle, max_angle, turn_fraction)
		
		var had_collision = move_and_slide()
		
		if (had_collision or
				self.position.y < -off_screen_zone or
				self.position.y > get_viewport_rect().size.y + off_screen_zone
				) and not dead:
			dead = true
			jetpack_particles.emitting = false
			emit_signal("died")
