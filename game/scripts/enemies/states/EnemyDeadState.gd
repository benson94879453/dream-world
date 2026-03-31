class_name EnemyDeadState
extends EnemyState

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var enemy_: EnemyAIController = get_actor()
	enemy_.die()


func physics_update(_delta: float) -> void:
	var enemy_: EnemyAIController = get_actor()
	enemy_.stop_movement()
#endregion
