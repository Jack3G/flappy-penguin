extends Control


@onready var play_button: Button = %PlayButton


func _ready() -> void:
	play_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://src/game.tscn"))
