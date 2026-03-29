class_name HitEffect
extends Node2D

@export var lifetime_seconds: float = 0.22
@export var start_scale: Vector2 = Vector2(0.45, 0.45)
@export var end_scale: Vector2 = Vector2(1.55, 1.55)

@onready var core: Polygon2D = $Core
@onready var ring: Polygon2D = $Ring

#region Core Lifecycle
func _ready() -> void:
	scale = start_scale
	rotation = randf_range(-0.35, 0.35)

	var tween_ := create_tween()
	tween_.set_parallel(true)
	tween_.tween_property(self, "scale", end_scale, lifetime_seconds)
	tween_.tween_property(core, "modulate:a", 0.0, lifetime_seconds)
	tween_.tween_property(ring, "modulate:a", 0.0, lifetime_seconds)
	tween_.chain().tween_callback(queue_free)
#endregion
