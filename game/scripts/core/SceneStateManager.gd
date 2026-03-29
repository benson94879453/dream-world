extends Node

var scene_states: Dictionary = {}


func generate_state_id(scene_path: String, object_name: String, index: int = 0) -> String:
	var safe_scene_path_: String = scene_path.strip_edges()
	var safe_object_name_: String = object_name.strip_edges()
	var safe_index_: int = maxi(index, 0)
	return "%s:%s:%d" % [safe_scene_path_, safe_object_name_, safe_index_]


func record_state(state_id: String, state_data: Dictionary) -> void:
	if state_id.is_empty():
		push_warning("[SceneStateManager] Ignored empty state_id during record_state")
		return

	var scene_path_: String = _extract_scene_path_from_state_id(state_id)
	if scene_path_.is_empty():
		push_warning("[SceneStateManager] Failed to extract scene path from state_id: %s" % state_id)
		return

	var scene_bucket_: Dictionary = scene_states.get(scene_path_, {})
	if typeof(scene_bucket_) != TYPE_DICTIONARY:
		scene_bucket_ = {}

	var next_state_data_: Dictionary = state_data.duplicate(true)
	next_state_data_["type"] = String(next_state_data_.get("type", "generic"))
	scene_bucket_[state_id] = next_state_data_
	scene_states[scene_path_] = scene_bucket_


func get_state(state_id: String) -> Dictionary:
	if state_id.is_empty():
		return {}

	var scene_path_: String = _extract_scene_path_from_state_id(state_id)
	if scene_path_.is_empty():
		return {}

	var scene_bucket_: Dictionary = scene_states.get(scene_path_, {})
	if typeof(scene_bucket_) != TYPE_DICTIONARY:
		return {}

	var state_data_ = scene_bucket_.get(state_id, {})
	if typeof(state_data_) != TYPE_DICTIONARY:
		return {}

	return state_data_.duplicate(true)


func clear_scene_state(scene_path: String, object_type: String = "") -> void:
	if scene_path.is_empty():
		return

	if object_type.is_empty():
		scene_states.erase(scene_path)
		return

	var scene_bucket_: Dictionary = scene_states.get(scene_path, {})
	if typeof(scene_bucket_) != TYPE_DICTIONARY or scene_bucket_.is_empty():
		return

	var filtered_bucket_: Dictionary = {}
	for state_id_ in scene_bucket_.keys():
		var state_data_ = scene_bucket_.get(state_id_, {})
		if typeof(state_data_) != TYPE_DICTIONARY:
			continue
		if String(state_data_.get("type", "")) == object_type:
			continue
		filtered_bucket_[state_id_] = state_data_

	if filtered_bucket_.is_empty():
		scene_states.erase(scene_path)
		return

	scene_states[scene_path] = filtered_bucket_


func to_save_dict() -> Dictionary:
	return scene_states.duplicate(true)


func from_save_dict(data: Dictionary) -> void:
	scene_states.clear()
	if typeof(data) != TYPE_DICTIONARY:
		return

	for scene_path_ in data.keys():
		var raw_scene_bucket_ = data.get(scene_path_, {})
		if typeof(raw_scene_bucket_) != TYPE_DICTIONARY:
			continue
		scene_states[String(scene_path_)] = raw_scene_bucket_.duplicate(true)


func reapply_current_scene_state() -> void:
	var current_scene_ := get_tree().current_scene
	if current_scene_ == null:
		return

	for node_ in get_tree().get_nodes_in_group("persistent_object"):
		var persistent_object_ := node_ as PersistentObject
		if persistent_object_ == null:
			continue
		if not current_scene_.is_ancestor_of(persistent_object_):
			continue
		persistent_object_.reload_persistent_state()


func _extract_scene_path_from_state_id(state_id: String) -> String:
	var parts_: PackedStringArray = state_id.split(":")
	if parts_.size() < 3:
		return ""

	var scene_parts_: PackedStringArray = PackedStringArray()
	for part_index_ in range(parts_.size() - 2):
		scene_parts_.append(parts_[part_index_])

	return ":".join(scene_parts_)
