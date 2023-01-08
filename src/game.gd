extends Node2D

@export var scroll_speed: float = 50

func _process(delta: float) -> void:
	$ParallaxBackground.scroll_offset.x += -scroll_speed * delta
