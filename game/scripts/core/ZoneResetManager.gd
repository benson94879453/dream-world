extends Node

enum ResetStrategy {
	NEVER,
	ON_EXIT,
	ON_REENTER,
	TIMER_BASED
}

var zone_configs: Dictionary = {
	"res://game/scenes/levels/Dungeon01.tscn": {
		"enemies": ResetStrategy.ON_REENTER,
		"pickups": ResetStrategy.ON_REENTER,
		"chests": ResetStrategy.NEVER,
		"boss": ResetStrategy.NEVER
	}
}


func on_scene_exited(scene_path: String) -> void:
	_apply_reset_strategy(scene_path, ResetStrategy.ON_EXIT)


func on_scene_entered(scene_path: String) -> void:
	_apply_reset_strategy(scene_path, ResetStrategy.ON_REENTER)


func should_reset_object(scene_path: String, object_type: String) -> bool:
	if scene_path.is_empty() or object_type.is_empty():
		return false

	var zone_config_: Dictionary = zone_configs.get(scene_path, {})
	if typeof(zone_config_) != TYPE_DICTIONARY:
		return false

	var normalized_type_: String = _normalize_object_type(object_type)
	var strategy_: int = int(zone_config_.get(normalized_type_, ResetStrategy.NEVER))
	return strategy_ != ResetStrategy.NEVER


func to_save_dict() -> Dictionary:
	return {}


func from_save_dict(_data: Dictionary) -> void:
	pass


func _apply_reset_strategy(scene_path: String, strategy: int) -> void:
	if scene_path.is_empty():
		return

	var zone_config_: Dictionary = zone_configs.get(scene_path, {})
	if typeof(zone_config_) != TYPE_DICTIONARY or zone_config_.is_empty():
		return

	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null:
		return

	for object_type_ in zone_config_.keys():
		if int(zone_config_.get(object_type_, ResetStrategy.NEVER)) != strategy:
			continue
		var normalized_type_: String = _normalize_object_type(String(object_type_))
		scene_state_manager_.clear_scene_state(scene_path, normalized_type_)
		print("[ZoneResetManager] Cleared %s state for %s" % [normalized_type_, scene_path])


func _get_scene_state_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SceneStateManager")


func _normalize_object_type(object_type_: String) -> String:
	match object_type_:
		"enemies":
			return "enemy"
		"enemy":
			return "enemy"
		"chests":
			return "chest"
		"chest":
			return "chest"
		"pickups":
			return "pickup"
		"pickup":
			return "pickup"
		_:
			return object_type_
