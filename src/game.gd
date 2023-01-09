extends Node2D

# Helmet bonks off stuff. have a variable that measures distance that can be
# reversed

# most horizontal measurements are in meters (distance counter thing not pixels)

@export var scroll_speed: float = 5
@export var pixels_per_meter: float = 15
@export var player_pixel_position_default: Vector2 = Vector2(
	110,
	ProjectSettings.get_setting("display/window/size/viewport_height") * 0.25)

@export var hazard_distance_min: float = 6
@export var hazard_distance_max: float = 8
@export var hazard_gap_min: int = 40
@export var hazard_gap_max: int = 70
# to make sure it doesn't spawn on screen spawn it a bit further
@export var hazard_spawn_offset: float = 3

@export var distance_label_prefix: String = "Distance: "
@export var high_score_label_prefix: String = "High-Score: "
@export var high_score_default: float = 100
@export_file var save_file: String = "user://save.ini"

@export var death_screen_time: float = 3

var distance: float = 0
var high_score: float = high_score_default
var player: Node2D
var continue_moving: bool = false

var hazards: Array[Hazard] = []
var next_hazard_distance: float = randf_range(
	hazard_distance_min, hazard_distance_max)

const stalactite: PackedScene = preload("res://src/hazards/stalactite.tscn")
const stalagmite: PackedScene = preload("res://src/hazards/stalagmite.tscn")

@onready var distance_label: Label = %DistanceLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var cave_background: ParallaxBackground = $CaveBackground


class Hazard:
	var top: Node2D
	var bottom: Node2D
	var position: float
	
	func update_pixel_position(player_distance: float,
			pixels_per_meter: float) -> void:
		var new_pos = (self.position - player_distance) * pixels_per_meter
		self.top.position.x = new_pos
		self.bottom.position.x = new_pos
	
	func get_pixel_position() -> float:
		assert(self.top.position.x == self.bottom.position.x)
		return self.top.position.x


func spawn_new_hazard_pair() -> void:
	var new_hazard: Hazard = Hazard.new()
	
	# dividing the ints is ok, I want them to snap to whole numbers
	var half_gap: int = randi_range(hazard_gap_min, hazard_gap_max)/2
	var gap_center: int = randi_range(
		0 + half_gap,
		get_viewport_rect().size.y - half_gap,
	)
	
	var top = stalactite.instantiate()
	top.position.y = gap_center - half_gap
	new_hazard.top = top
	
	var bottom = stalagmite.instantiate()
	bottom.position.y = gap_center + half_gap
	new_hazard.bottom = bottom
	
	new_hazard.position = get_viewport_rect().size.x / pixels_per_meter\
		+ hazard_spawn_offset + distance
	new_hazard.update_pixel_position(distance, pixels_per_meter)
	
	hazards.append(new_hazard)
	self.add_child(new_hazard.top)
	self.add_child(new_hazard.bottom)


func load_high_score() -> float:
	var new_high_score: float = high_score_default
	
	var file = ConfigFile.new()
	var err = file.load(save_file)
	if err != OK:
		print("Couldn't load the save file. Using defaults.")
		return new_high_score
	
	new_high_score = file.get_value("game", "high_score", high_score_default)
	
	return new_high_score

func save_high_score(high_score: float) -> void:
	var file = ConfigFile.new()
	
	# It doesn't matter if we can't load it
	file.load(save_file)
	
	file.set_value("game", "high_score", high_score)
	var err = file.save(save_file)
	if err != OK:
		print("Couldn't save file (" + save_file + "). error code: " + err)


func _on_player_unfrozen() -> void:
	continue_moving = true


func respawn() -> void:
	if player and not player.is_queued_for_deletion():
		player.queue_free()
	
	distance = 0
	for h in hazards:
		h.top.free()
		h.bottom.free()
	hazards = []
	
	player = preload("res://src/bord.tscn").instantiate()
	player.position = player_pixel_position_default
	player.died.connect(_on_player_died)
	player.unfrozen.connect(_on_player_unfrozen)
	self.add_child(player)
	
	continue_moving = false


func _on_player_died() -> void:
	continue_moving = false
	get_tree().create_timer(death_screen_time).timeout.connect(
		func _on_death_screen_timeout():
			respawn())
	
	save_high_score(high_score)


func _ready() -> void:
	high_score = load_high_score()
	
	respawn()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_tree().change_scene_to_file("res://src/main_menu.tscn")


func _physics_process(delta: float) -> void:
	if continue_moving:
		distance += scroll_speed * delta
	
	if distance > high_score:
		high_score = distance
	
	distance_label.text = distance_label_prefix + str(roundi(distance))
	high_score_label.text = high_score_label_prefix + str(roundi(high_score))
	
	cave_background.scroll_offset.x = -distance * pixels_per_meter
	
	
	var viewport_meter_width = get_viewport_rect().size.x / pixels_per_meter
	var last_hazard_to_screen_left_distance
	if not hazards.is_empty():
		last_hazard_to_screen_left_distance = hazards.back().position - distance
	
	var spawn_new_hazard: bool = hazards.is_empty() or (
		last_hazard_to_screen_left_distance and (viewport_meter_width -
			last_hazard_to_screen_left_distance + hazard_spawn_offset
			) > next_hazard_distance)
	
	if spawn_new_hazard:
		spawn_new_hazard_pair()
		next_hazard_distance = randf_range(
			hazard_distance_min, hazard_distance_max)
	
	# I have to be able to change i inside the loop for when stuff gets deleted
	# so that elements dont get skipped
	var i: int = 0
	while i < hazards.size():
		var h = hazards[i]
		h.update_pixel_position(distance, pixels_per_meter)
		
		if h.get_pixel_position() + hazard_spawn_offset*pixels_per_meter < 0:
			h.bottom.queue_free()
			h.top.queue_free()
			hazards.remove_at(i)
			i -= 1
		
		i += 1
