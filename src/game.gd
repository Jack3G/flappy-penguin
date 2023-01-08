extends Node2D

# Helmet bonks off stuff. have a variable that measures distance that can be
# reversed

# most horizontal measurements are in meters (distance counter thing not pixels)

@export var scroll_speed: float = 5
@export var pixels_per_meter: float = 15

@export var hazard_distance_min: float = 4
@export var hazard_distance_max: float = 6
@export var hazard_gap_min: int = 100
@export var hazard_gap_max: int = 200
# to make sure it doesn't spawn on screen spawn it a bit further
@export var hazard_spawn_offset: float = 3

var distance: float = 0
var hazards: Array[Hazard] = []

var stalactite: PackedScene = preload("res://src/hazards/stalactite.tscn")
var stalagmite: PackedScene = preload("res://src/hazards/stalagmite.tscn")


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
	
	var half_gap = randi_range(hazard_gap_min, hazard_distance_max)/2
	var gap_center = randi_range(
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
		+ hazard_spawn_offset
	new_hazard.update_pixel_position(distance, pixels_per_meter)
	
	hazards.append(new_hazard)
	self.add_child(new_hazard.top)
	self.add_child(new_hazard.bottom)


func _process(delta: float) -> void:
	distance += scroll_speed * delta
	
	$ParallaxBackground.scroll_offset.x = -distance * pixels_per_meter
	
	if hazards.is_empty():
		spawn_new_hazard_pair()
	
	for h in hazards:
		h.update_pixel_position(distance, pixels_per_meter)
