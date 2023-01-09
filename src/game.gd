extends Node2D

# Helmet bonks off stuff. have a variable that measures distance that can be
# reversed

# most horizontal measurements are in meters (distance counter thing not pixels)

@export var scroll_speed: float = 5
@export var pixels_per_meter: float = 15

@export var hazard_distance_min: float = 3
@export var hazard_distance_max: float = 5
@export var hazard_gap_min: int = 40
@export var hazard_gap_max: int = 70
# to make sure it doesn't spawn on screen spawn it a bit further
@export var hazard_spawn_offset: float = 3

@export var distance_label_prefix: String = "Distance: "

var distance: float = 0
var hazards: Array[Hazard] = []
var next_hazard_distance: float = randf_range(
	hazard_distance_min, hazard_distance_max)

const stalactite: PackedScene = preload("res://src/hazards/stalactite.tscn")
const stalagmite: PackedScene = preload("res://src/hazards/stalagmite.tscn")

@onready var distance_label: Label = %DistanceLabel


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


func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_0):
		distance += -scroll_speed * delta
	else:
		distance += scroll_speed * delta
	
	distance_label.text = distance_label_prefix + str(roundi(distance))
	
	$ParallaxBackground.scroll_offset.x = -distance * pixels_per_meter
	
	
	var viewport_meter_width = get_viewport_rect().size.x / pixels_per_meter
	var last_hazard_to_screen_left_distance
	if not hazards.is_empty():
		last_hazard_to_screen_left_distance = hazards.back().position - distance
	
	var spawn_new_hazard: bool = hazards.is_empty() or (
		last_hazard_to_screen_left_distance and (viewport_meter_width -
			last_hazard_to_screen_left_distance + 0) > next_hazard_distance)
	
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
