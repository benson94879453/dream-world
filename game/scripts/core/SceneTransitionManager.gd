extends Node

const FADE_DURATION_SECONDS: float = 0.3
const DEFAULT_SPAWN_POINT_ID: StringName = &"Spawn_default"

signal scene_transition_started(scene_path: String)
signal scene_transition_completed(scene_path: String)

var _is_transitioning: bool = false
var _previous_scene_path: String = ""
var _current_scene_path: String = ""
var _respawn_points: Dictionary = {}
var _cached_player_data: Dictionary = {}
var _cached_inventory_data: Dictionary = {}
var _has_cached_player_state: bool = false

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_fade_overlay()
	call_deferred("_sync_current_scene_path")


func transition_to(scene_path: String, spawn_point_id: StringName = &"", suppress_zone_reset_notifications_: bool = false) -> bool:
	if _is_transitioning:
		push_warning("[SceneTransitionManager] Transition already in progress")
		return false

	if scene_path.is_empty():
		push_warning("[SceneTransitionManager] Cannot transition to an empty scene path")
		return false

	_run_transition(scene_path, spawn_point_id, suppress_zone_reset_notifications_)
	return true


func transition_back() -> bool:
	if _previous_scene_path.is_empty():
		push_warning("[SceneTransitionManager] No previous scene available for transition_back")
		return false

	return transition_to(_previous_scene_path)


func get_current_scene_path() -> String:
	if _current_scene_path.is_empty():
		_sync_current_scene_path()
	return _current_scene_path


func get_spawn_position(spawn_point_id: StringName) -> Vector2:
	var current_scene_ := get_tree().current_scene
	if current_scene_ == null:
		return Vector2.ZERO

	var spawn_marker_: Marker2D = _find_spawn_marker(current_scene_, spawn_point_id)
	if spawn_marker_ != null:
		return spawn_marker_.global_position

	var respawn_position_: Variant = _get_respawn_position(get_current_scene_path(), spawn_point_id)
	if respawn_position_ != null:
		return respawn_position_

	return Vector2.ZERO


func set_respawn_point(scene_path: String, checkpoint_id: StringName, position: Vector2) -> void:
	if scene_path.is_empty() or checkpoint_id.is_empty():
		push_warning("[SceneTransitionManager] Ignored invalid respawn point registration")
		return

	_respawn_points[scene_path] = {
		"checkpoint_id": checkpoint_id,
		"position": position
	}


func get_respawn_point(scene_path_: String = "") -> Dictionary:
	var resolved_scene_path_: String = scene_path_
	if resolved_scene_path_.is_empty():
		resolved_scene_path_ = get_current_scene_path()
	if resolved_scene_path_.is_empty():
		return {}

	var respawn_entry_ = _respawn_points.get(resolved_scene_path_, {})
	if typeof(respawn_entry_) != TYPE_DICTIONARY:
		return {}

	return respawn_entry_.duplicate(true)


func to_save_dict(scene_path_: String = "") -> Dictionary:
	var resolved_scene_path_: String = scene_path_.strip_edges()
	if resolved_scene_path_.is_empty():
		resolved_scene_path_ = get_current_scene_path()
	if resolved_scene_path_.is_empty():
		return _build_default_respawn_save_dict()

	var respawn_entry_: Dictionary = get_respawn_point(resolved_scene_path_)
	if respawn_entry_.is_empty():
		return _build_default_respawn_save_dict(resolved_scene_path_)

	var spawn_point_id_: String = String(respawn_entry_.get("checkpoint_id", "")).strip_edges()
	var spawn_position_data_: Dictionary = _serialize_vector2(respawn_entry_.get("position", null))
	if spawn_point_id_.is_empty() or spawn_position_data_.is_empty():
		return _build_default_respawn_save_dict(resolved_scene_path_)

	return {
		"scene_path": resolved_scene_path_,
		"spawn_point_id": spawn_point_id_,
		"spawn_position": spawn_position_data_
	}


func from_save_dict(data_: Dictionary) -> void:
	_respawn_points.clear()
	if typeof(data_) != TYPE_DICTIONARY:
		return

	var scene_path_: String = String(data_.get("scene_path", "")).strip_edges()
	var spawn_point_id_: StringName = StringName(String(data_.get("spawn_point_id", "")).strip_edges())
	var spawn_position_: Variant = _deserialize_vector2(data_.get("spawn_position", {}))
	if scene_path_.is_empty() or spawn_point_id_.is_empty() or spawn_position_ == null:
		return

	set_respawn_point(scene_path_, spawn_point_id_, spawn_position_)


func apply_saved_respawn(data_: Dictionary) -> bool:
	if typeof(data_) != TYPE_DICTIONARY:
		return false

	var scene_path_: String = String(data_.get("scene_path", "")).strip_edges()
	if scene_path_.is_empty():
		scene_path_ = get_current_scene_path()

	if scene_path_.is_empty() or scene_path_ != get_current_scene_path():
		return false

	var spawn_point_id_: StringName = StringName(String(data_.get("spawn_point_id", "")).strip_edges())
	if spawn_point_id_.is_empty():
		spawn_point_id_ = DEFAULT_SPAWN_POINT_ID

	_move_player_to_spawn(spawn_point_id_)
	return true


func wait_for_transition_completion() -> void:
	if not _is_transitioning:
		return

	await scene_transition_completed


func is_transitioning() -> bool:
	return _is_transitioning


func _run_transition(scene_path: String, spawn_point_id: StringName, suppress_zone_reset_notifications_: bool = false) -> void:
	_is_transitioning = true
	_ensure_fade_overlay()

	var source_scene_path_: String = get_current_scene_path()
	if not suppress_zone_reset_notifications_:
		_notify_zone_scene_exited(source_scene_path_)
		_notify_zone_scene_entered(scene_path)
	scene_transition_started.emit(scene_path)
	print("[SceneTransitionManager] Transition started: %s" % scene_path)

	_cache_player_runtime_state()
	await _fade_to(1.0)

	var error_ := get_tree().change_scene_to_file(scene_path)
	if error_ != OK:
		push_warning("[SceneTransitionManager] Failed to change scene to %s (error=%d)" % [scene_path, error_])
		await _fade_to(0.0)
		_is_transitioning = false
		return

	_previous_scene_path = source_scene_path_
	_current_scene_path = scene_path

	await get_tree().process_frame
	await get_tree().process_frame

	_restore_player_runtime_state()
	_move_player_to_spawn(spawn_point_id)
	await _fade_to(0.0)

	print("[SceneTransitionManager] Transition completed: %s" % scene_path)
	scene_transition_completed.emit(scene_path)
	_is_transitioning = false


func _sync_current_scene_path() -> void:
	var current_scene_ := get_tree().current_scene
	if current_scene_ == null:
		return

	if current_scene_.scene_file_path.is_empty():
		return

	_current_scene_path = current_scene_.scene_file_path


func _ensure_fade_overlay() -> void:
	if _fade_layer != null and is_instance_valid(_fade_layer):
		return

	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "SceneTransitionOverlay"
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_rect.modulate.a = 0.0
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.offset_left = 0.0
	_fade_rect.offset_top = 0.0
	_fade_rect.offset_right = 0.0
	_fade_rect.offset_bottom = 0.0
	_fade_layer.add_child(_fade_rect)


func _fade_to(target_alpha_: float) -> void:
	if _fade_rect == null or not is_instance_valid(_fade_rect):
		return

	var tween_: Tween = create_tween()
	tween_.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_.tween_property(_fade_rect, "modulate:a", clampf(target_alpha_, 0.0, 1.0), FADE_DURATION_SECONDS)
	await tween_.finished


func _cache_player_runtime_state() -> void:
	_has_cached_player_state = false
	_cached_player_data.clear()
	_cached_inventory_data.clear()

	var player_: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		return

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		return

	_cached_player_data = player_.to_save_dict()
	_cached_inventory_data = inventory_.to_save_dict()
	_has_cached_player_state = true


func _restore_player_runtime_state() -> void:
	if not _has_cached_player_state:
		return

	var player_: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		push_warning("[SceneTransitionManager] Player was not found after scene load")
		return

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		push_warning("[SceneTransitionManager] Player inventory missing after scene load")
		return

	inventory_.from_save_dict(_cached_inventory_data)
	var player_load_report_: Dictionary = player_.from_save_dict(_cached_player_data)

	var equipped_restored_: bool = true
	var player_data_ = _cached_player_data
	var equipment_data_ = player_data_.get("equipment", {})
	var has_equipment_save_: bool = typeof(equipment_data_) == TYPE_DICTIONARY and not equipment_data_.is_empty()
	var has_equipment_weapon_: bool = has_equipment_save_ and typeof(equipment_data_.get("weapon_main", null)) == TYPE_DICTIONARY
	if has_equipment_save_:
		if player_.equipment != null:
			var equipment_loaded_: bool = bool(player_load_report_.get("equipment_loaded", false))
			equipped_restored_ = not has_equipment_weapon_ or equipment_loaded_
		else:
			equipped_restored_ = false

	if not equipped_restored_:
		var equipped_weapon_uid_: String = String(player_data_.get("equipped_weapon_uid", ""))
		if not equipped_weapon_uid_.is_empty():
			equipped_restored_ = inventory_.equip_weapon_by_uid(equipped_weapon_uid_)
		if not equipped_restored_:
			equipped_restored_ = player_.restore_equipped_weapon_from_save(player_data_)

	if not equipped_restored_:
		push_warning("[SceneTransitionManager] Equipped weapon could not be fully restored after transition")


func _move_player_to_spawn(spawn_point_id: StringName) -> void:
	var player_: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		push_warning("[SceneTransitionManager] Cannot place player because no player node was found")
		return

	var current_scene_ := get_tree().current_scene
	var spawn_marker_: Marker2D = _find_spawn_marker(current_scene_, spawn_point_id)
	if spawn_marker_ != null:
		player_.global_position = spawn_marker_.global_position
		player_.velocity = Vector2.ZERO
		return

	var respawn_position_: Variant = _get_respawn_position(get_current_scene_path(), spawn_point_id)
	if respawn_position_ != null:
		player_.global_position = respawn_position_
		player_.velocity = Vector2.ZERO
		return

	push_warning("[SceneTransitionManager] Spawn point not found: %s" % String(spawn_point_id))


func _find_spawn_marker(root_: Node, spawn_point_id: StringName) -> Marker2D:
	if root_ == null:
		return null

	var requested_name_: String = String(spawn_point_id)
	if not requested_name_.is_empty():
		var exact_marker_: Marker2D = _find_spawn_marker_by_name(root_, requested_name_)
		if exact_marker_ != null:
			return exact_marker_

	var markers_root_: Node = root_.get_node_or_null("Markers")
	if markers_root_ != null:
		var default_marker_: Marker2D = markers_root_.get_node_or_null("Spawn_default") as Marker2D
		if default_marker_ != null:
			return default_marker_

	return _find_first_named_spawn_marker(root_)


func _find_spawn_marker_by_name(root_: Node, marker_name_: String) -> Marker2D:
	if root_ == null:
		return null

	if root_ is Marker2D and root_.name == marker_name_:
		return root_ as Marker2D

	for child_ in root_.get_children():
		var marker_: Marker2D = _find_spawn_marker_by_name(child_, marker_name_)
		if marker_ != null:
			return marker_

	return null


func _find_first_named_spawn_marker(root_: Node) -> Marker2D:
	if root_ == null:
		return null

	if root_ is Marker2D and String(root_.name).begins_with("Spawn_"):
		return root_ as Marker2D

	for child_ in root_.get_children():
		var marker_: Marker2D = _find_first_named_spawn_marker(child_)
		if marker_ != null:
			return marker_

	return null


func _get_respawn_position(scene_path_: String, checkpoint_id_: StringName) -> Variant:
	if scene_path_.is_empty() or checkpoint_id_.is_empty():
		return null

	var respawn_entry_ = _respawn_points.get(scene_path_, {})
	if typeof(respawn_entry_) != TYPE_DICTIONARY:
		return null

	if StringName(String(respawn_entry_.get("checkpoint_id", ""))) != checkpoint_id_:
		return null

	return respawn_entry_.get("position", Vector2.ZERO)


func _build_default_respawn_save_dict(scene_path_: String = "") -> Dictionary:
	var resolved_scene_path_: String = scene_path_.strip_edges()
	if resolved_scene_path_.is_empty():
		resolved_scene_path_ = get_current_scene_path()
	if resolved_scene_path_.is_empty():
		resolved_scene_path_ = String(ProjectSettings.get_setting("application/run/main_scene", "")).strip_edges()

	var spawn_position_data_: Dictionary = {}
	var current_scene_ := get_tree().current_scene
	if current_scene_ != null and current_scene_.scene_file_path == resolved_scene_path_:
		var spawn_marker_: Marker2D = _find_spawn_marker(current_scene_, DEFAULT_SPAWN_POINT_ID)
		if spawn_marker_ != null:
			spawn_position_data_ = _serialize_vector2(spawn_marker_.global_position)

	return {
		"scene_path": resolved_scene_path_,
		"spawn_point_id": String(DEFAULT_SPAWN_POINT_ID),
		"spawn_position": spawn_position_data_
	}


func _serialize_vector2(value_: Variant) -> Dictionary:
	if typeof(value_) == TYPE_VECTOR2:
		var vector_: Vector2 = value_ as Vector2
		return {
			"x": vector_.x,
			"y": vector_.y
		}

	if typeof(value_) != TYPE_DICTIONARY:
		return {}

	var dictionary_: Dictionary = value_ as Dictionary
	if not dictionary_.has("x") or not dictionary_.has("y"):
		return {}

	var x_: Variant = dictionary_.get("x", null)
	var y_: Variant = dictionary_.get("y", null)
	if typeof(x_) != TYPE_INT and typeof(x_) != TYPE_FLOAT:
		return {}
	if typeof(y_) != TYPE_INT and typeof(y_) != TYPE_FLOAT:
		return {}

	return {
		"x": float(x_),
		"y": float(y_)
	}


func _deserialize_vector2(value_: Variant) -> Variant:
	var serialized_vector_: Dictionary = _serialize_vector2(value_)
	if serialized_vector_.is_empty():
		return null

	return Vector2(
		float(serialized_vector_.get("x", 0.0)),
		float(serialized_vector_.get("y", 0.0))
	)


func _notify_zone_scene_exited(scene_path_: String) -> void:
	if scene_path_.is_empty():
		return

	var zone_reset_manager_: Node = _get_zone_reset_manager()
	if zone_reset_manager_ == null or not zone_reset_manager_.has_method("on_scene_exited"):
		return

	zone_reset_manager_.call("on_scene_exited", scene_path_)


func _notify_zone_scene_entered(scene_path_: String) -> void:
	if scene_path_.is_empty():
		return

	var zone_reset_manager_: Node = _get_zone_reset_manager()
	if zone_reset_manager_ == null or not zone_reset_manager_.has_method("on_scene_entered"):
		return

	zone_reset_manager_.call("on_scene_entered", scene_path_)


func _get_zone_reset_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("ZoneResetManager")
