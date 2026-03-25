class_name EnemyDummy
extends CharacterBody2D

var current_state_name: StringName = &"Idle"

@onready var health_component: HealthComponent = $HealthComponent

#region Core Lifecycle
func _ready() -> void:
	assert(health_component != null, "EnemyDummy requires HealthComponent")

	add_to_group("debug_dummy")
	health_component.died.connect(_on_died)
#endregion

#region Public
func get_current_state_name() -> StringName:
	return current_state_name

func get_health_component() -> HealthComponent:
	return health_component
#endregion

#region Helpers
func _on_died() -> void:
	current_state_name = &"Dead"
	velocity = Vector2.ZERO
#endregion
