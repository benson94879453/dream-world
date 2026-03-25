class_name FeedbackReceiver
extends Node

@export var visual_path: NodePath = NodePath("../Visual")
@export var flash_color: Color = Color(1.0, 0.55, 0.55, 1.0)
@export var flash_duration: float = 0.08

var flash_time_remaining: float = 0.0
var default_modulate: Color = Color.WHITE

@onready var visual: CanvasItem = get_node_or_null(visual_path) as CanvasItem

#region Core Lifecycle
func _ready() -> void:
	assert(visual != null, "FeedbackReceiver visual_path must point to a CanvasItem")

	default_modulate = visual.modulate
	set_process(false)


func _process(delta_: float) -> void:
	flash_time_remaining = maxf(flash_time_remaining - delta_, 0.0)
	if flash_time_remaining > 0.0:
		return

	visual.modulate = default_modulate
	set_process(false)
#endregion

#region Public
func play_hit_feedback(_attack_context_: AttackContext) -> void:
	visual.modulate = flash_color
	flash_time_remaining = flash_duration
	set_process(true)
#endregion
