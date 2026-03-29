class_name PersistentObject
extends Node

@export var state_id: String = ""
@export var persistent_type: String = "generic"
@export var target_node_path: NodePath = NodePath("..")
@export var track_parent_death: bool = true

var _state_loaded: bool = false


func _ready() -> void:
	add_to_group("persistent_object")

	if state_id.is_empty():
		state_id = _auto_generate_id()

	_connect_runtime_hooks()
	_load_state()


func _auto_generate_id() -> String:
	var target_node_ := _get_target_node()
	if target_node_ == null:
		return ""

	var scene_path_: String = _get_current_scene_path()
	if scene_path_.is_empty():
		return ""

	var sibling_index_: int = 0
	var target_parent_ := target_node_.get_parent()
	if target_parent_ != null:
		for sibling_ in target_parent_.get_children():
			if sibling_ == target_node_:
				break
			if sibling_.name == target_node_.name:
				sibling_index_ += 1

	var scene_state_manager_ := _get_scene_state_manager()
	if scene_state_manager_ == null:
		return ""

	return scene_state_manager_.generate_state_id(scene_path_, String(target_node_.name), sibling_index_)


func reload_persistent_state() -> void:
	_load_state()


func save_custom_state(state_data: Dictionary) -> void:
	_save_state(state_data)


func _load_state() -> void:
	_state_loaded = false

	if state_id.is_empty():
		return

	var scene_state_manager_ := _get_scene_state_manager()
	if scene_state_manager_ == null:
		return

	var state_data_: Dictionary = scene_state_manager_.get_state(state_id)
	if state_data_.is_empty():
		return

	_state_loaded = true
	_apply_state(state_data_)


func _save_state(state_data: Dictionary) -> void:
	if state_id.is_empty():
		state_id = _auto_generate_id()
	if state_id.is_empty():
		push_warning("[PersistentObject] Failed to generate state_id for %s" % name)
		return

	var scene_state_manager_ := _get_scene_state_manager()
	if scene_state_manager_ == null:
		return

	var next_state_data_: Dictionary = state_data.duplicate(true)
	next_state_data_["type"] = persistent_type
	scene_state_manager_.record_state(state_id, next_state_data_)


func _apply_state(state_data: Dictionary) -> void:
	if typeof(state_data) != TYPE_DICTIONARY:
		return

	if persistent_type == "boss" or persistent_type == "enemy":
		if bool(state_data.get("defeated", false)):
			_deactivate_target()


func _connect_runtime_hooks() -> void:
	if not track_parent_death:
		return

	if persistent_type != "boss" and persistent_type != "enemy":
		return

	var target_node_ := _get_target_node()
	if target_node_ == null:
		return

	var health_component_ := target_node_.get_node_or_null("HealthComponent") as HealthComponent
	if health_component_ == null:
		return

	if not health_component_.died.is_connected(_on_target_died):
		health_component_.died.connect(_on_target_died)


func _on_target_died() -> void:
	_save_state({
		"defeated": true
	})


func _deactivate_target() -> void:
	var target_node_ := _get_target_node()
	if target_node_ == null:
		return

	if target_node_.has_method("hide"):
		target_node_.call("hide")

	_disable_subtree(target_node_)
	target_node_.call_deferred("queue_free")


func _disable_subtree(node_: Node) -> void:
	node_.process_mode = Node.PROCESS_MODE_DISABLED

	var canvas_item_ := node_ as CanvasItem
	if canvas_item_ != null:
		canvas_item_.visible = false

	var collision_shape_ := node_ as CollisionShape2D
	if collision_shape_ != null:
		collision_shape_.set_deferred("disabled", true)

	var character_body_ := node_ as CharacterBody2D
	if character_body_ != null:
		character_body_.set_deferred("collision_layer", 0)
		character_body_.set_deferred("collision_mask", 0)
		character_body_.set_deferred("velocity", Vector2.ZERO)

	var area_ := node_ as Area2D
	if area_ != null:
		area_.set_deferred("monitoring", false)
		area_.set_deferred("monitorable", false)
		area_.set_deferred("collision_layer", 0)
		area_.set_deferred("collision_mask", 0)

	if node_.has_method("set_controls_locked"):
		node_.call("set_controls_locked", true)

	if _has_property(node_, "has_died"):
		node_.set("has_died", true)

	for child_ in node_.get_children():
		_disable_subtree(child_)


func _get_target_node() -> Node:
	return get_node_or_null(target_node_path)


func _get_current_scene_path() -> String:
	var scene_transition_manager_ := _get_scene_transition_manager()
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("get_current_scene_path"):
		var scene_path_ := String(scene_transition_manager_.call("get_current_scene_path"))
		if not scene_path_.is_empty():
			return scene_path_

	var current_scene_ := get_tree().current_scene
	if current_scene_ == null:
		return ""

	return current_scene_.scene_file_path


func _get_scene_transition_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SceneTransitionManager")


func _get_scene_state_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SceneStateManager")


func _has_property(node_: Object, property_name_: String) -> bool:
	for property_ in node_.get_property_list():
		if String(property_.get("name", "")) == property_name_:
			return true
	return false
