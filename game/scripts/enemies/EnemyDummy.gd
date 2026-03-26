class_name EnemyDummy
extends CharacterBody2D

@export var animation_fps: float = 12.0
@export var frame_count: int = 23

var current_state_name: StringName = &"Idle"
var animation_time: float = 0.0

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var health_component: HealthComponent = $HealthComponent

#region Core Lifecycle
func _ready() -> void:
	assert(sprite != null, "EnemyDummy requires Sprite2D")
	assert(health_component != null, "EnemyDummy requires HealthComponent")

	add_to_group("debug_dummy")
	health_component.died.connect(_on_died)
	_apply_frame()


func _process(delta_: float) -> void:
	if current_state_name == &"Dead":
		return

	animation_time += delta_ * animation_fps
	_apply_frame()
#endregion

#region Public
func get_current_state_name() -> StringName:
	return current_state_name


func get_health_component() -> HealthComponent:
	return health_component
#endregion

#region Helpers
func _apply_frame() -> void:
	var frame_index_: int = int(animation_time) % frame_count
	var frame_column_: int = frame_index_ % sprite.hframes
	@warning_ignore("integer_division")
	var frame_row_ : int = frame_index_ / sprite.hframes
	
	sprite.frame_coords = Vector2i(frame_column_, frame_row_)


func _on_died() -> void:
	current_state_name = &"Dead"
	velocity = Vector2.ZERO
	animation_time = 0.0
	_apply_frame()
#endregion
