extends Control


@export var volume_min_db: float = -45
@export var volume_max_db: float = 6

@onready var play_button: Button = %PlayButton
@onready var volume_slider: HSlider = %VolumeSlider


func _on_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		AudioServer.set_bus_volume_db(0, volume_slider.value)
		if volume_slider.value <= volume_slider.min_value:
			AudioServer.set_bus_mute(0, true)
		else:
			AudioServer.set_bus_mute(0, false)


func _ready() -> void:
	play_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://src/game.tscn"))
	
	volume_slider.min_value = volume_min_db
	volume_slider.max_value = volume_max_db
	
	volume_slider.value = AudioServer.get_bus_volume_db(0)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
