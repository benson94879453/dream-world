class_name QuestTrackerUI
extends Control

const QUEST_MANAGER_PATH: NodePath = NodePath("/root/QuestManager")
const QuestInstanceResource = preload("res://game/scripts/data/QuestInstance.gd")

const MAX_VISIBLE_QUESTS: int = 3
const SCREEN_MARGIN: float = 28.0
const PANEL_MIN_WIDTH: float = 352.0
const QUEST_TITLE_COLOR: Color = Color(0.97, 0.92, 0.75, 1.0)
const QUEST_NAME_COLOR: Color = Color(0.93, 0.94, 0.97, 1.0)
const QUEST_PROGRESS_COLOR: Color = Color(0.79, 0.82, 0.88, 0.96)
const QUEST_COMPLETED_NAME_COLOR: Color = Color(1.0, 0.84, 0.0, 1.0)
const QUEST_COMPLETED_PROGRESS_COLOR: Color = Color(1.0, 0.91, 0.42, 1.0)
const PANEL_BACKGROUND_COLOR: Color = Color(0.08, 0.09, 0.11, 0.82)
const PANEL_BORDER_COLOR: Color = Color(0.82, 0.69, 0.42, 0.94)
const ENTRY_BACKGROUND_COLOR: Color = Color(0.12, 0.13, 0.17, 0.92)
const ENTRY_BORDER_COLOR: Color = Color(0.28, 0.30, 0.35, 0.95)
const ENTRY_COLOR_TWEEN_SECONDS: float = 0.18
const ENTRY_COMPLETED_HOLD_SECONDS: float = 2.0

@onready var quest_panel: PanelContainer = $QuestPanel
@onready var title_label: Label = $QuestPanel/PanelMargin/QuestRoot/TitleLabel
@onready var quest_entries: VBoxContainer = $QuestPanel/PanelMargin/QuestRoot/QuestEntries

var quest_manager: DWQuestManager = null
var quest_entry_map: Dictionary = {}

#region Core Lifecycle
func _ready() -> void:
	assert(quest_panel != null, "QuestTrackerUI requires QuestPanel")
	assert(title_label != null, "QuestTrackerUI requires TitleLabel")
	assert(quest_entries != null, "QuestTrackerUI requires QuestEntries")

	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)
	title_label.text = "任務追蹤"
	title_label.add_theme_color_override("font_color", QUEST_TITLE_COLOR)
	_apply_panel_style()
	quest_panel.visible = false

	resized.connect(_on_resized)
	_bind_quest_manager()
	_refresh_entries()
	call_deferred("_sync_panel_layout")
#endregion

#region Helpers
func _bind_quest_manager() -> void:
	quest_manager = get_node_or_null(QUEST_MANAGER_PATH) as DWQuestManager
	assert(quest_manager != null, "QuestTrackerUI requires QuestManager autoload")

	if not quest_manager.quest_accepted.is_connected(_on_quest_accepted):
		quest_manager.quest_accepted.connect(_on_quest_accepted)
	if not quest_manager.quest_progress_updated.is_connected(_on_quest_progress_updated):
		quest_manager.quest_progress_updated.connect(_on_quest_progress_updated)
	if not quest_manager.quest_completed.is_connected(_on_quest_completed):
		quest_manager.quest_completed.connect(_on_quest_completed)
	if not quest_manager.quest_turned_in.is_connected(_on_quest_turned_in):
		quest_manager.quest_turned_in.connect(_on_quest_turned_in)


func _refresh_entries() -> void:
	var visible_quests_ := _get_visible_quests()
	var visible_ids_: Array[StringName] = []

	for index_ in range(visible_quests_.size()):
		var quest_ := visible_quests_[index_]
		if quest_ == null:
			continue

		visible_ids_.append(quest_.quest_id)
		if not quest_entry_map.has(quest_.quest_id):
			var entry_ := _create_entry_widgets()
			quest_entry_map[quest_.quest_id] = entry_
			quest_entries.add_child(entry_.get("container") as Control)

		var entry_data_: Dictionary = quest_entry_map.get(quest_.quest_id, {})
		_update_entry(entry_data_, quest_)
		var entry_container_ := entry_data_.get("container") as Control
		if entry_container_ != null:
			quest_entries.move_child(entry_container_, index_)

	var stale_ids_: Array[StringName] = []
	for quest_id_value_ in quest_entry_map.keys():
		var quest_id_ := StringName(String(quest_id_value_))
		if visible_ids_.has(quest_id_):
			continue
		stale_ids_.append(quest_id_)

	for stale_id_ in stale_ids_:
		_remove_entry(stale_id_)

	quest_panel.visible = not visible_ids_.is_empty()
	call_deferred("_sync_panel_layout")


func _get_visible_quests() -> Array[QuestInstanceResource]:
	if quest_manager == null:
		return []

	var quests_ := quest_manager.get_active_quests()
	quests_.sort_custom(_sort_quests)
	if quests_.size() > MAX_VISIBLE_QUESTS:
		quests_.resize(MAX_VISIBLE_QUESTS)
	return quests_


func _sort_quests(left_: QuestInstanceResource, right_: QuestInstanceResource) -> bool:
	if left_ == null:
		return false
	if right_ == null:
		return true

	if left_.accepted_at != right_.accepted_at:
		return left_.accepted_at < right_.accepted_at
	return String(left_.quest_id) < String(right_.quest_id)


func _create_entry_widgets() -> Dictionary:
	var container_ := PanelContainer.new()
	container_.name = "QuestEntryContainer"
	container_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container_.add_theme_stylebox_override("panel", _build_stylebox(ENTRY_BACKGROUND_COLOR, ENTRY_BORDER_COLOR, 1, 5))

	var margin_ := MarginContainer.new()
	margin_.name = "EntryMargin"
	margin_.add_theme_constant_override("margin_left", 14)
	margin_.add_theme_constant_override("margin_top", 12)
	margin_.add_theme_constant_override("margin_right", 14)
	margin_.add_theme_constant_override("margin_bottom", 12)
	container_.add_child(margin_)

	var root_ := VBoxContainer.new()
	root_.name = "QuestEntryRoot"
	root_.add_theme_constant_override("separation", 4)
	margin_.add_child(root_)

	var name_label_ := Label.new()
	name_label_.name = "QuestNameLabel"
	name_label_.add_theme_font_size_override("font_size", 18)
	name_label_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_.add_child(name_label_)

	var progress_label_ := Label.new()
	progress_label_.name = "QuestProgressLabel"
	progress_label_.add_theme_font_size_override("font_size", 14)
	progress_label_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_.add_child(progress_label_)

	_set_mouse_filter_recursive(container_, Control.MOUSE_FILTER_IGNORE)

	var entry_data_ := {
		"container": container_,
		"name_label": name_label_,
		"progress_label": progress_label_,
		"highlight_tween": null,
		"is_highlighted": false
	}
	_apply_entry_colors(entry_data_, QUEST_NAME_COLOR, QUEST_PROGRESS_COLOR)
	return entry_data_


func _update_entry(entry_data_: Dictionary, quest_: QuestInstanceResource) -> void:
	var quest_name_label_ := entry_data_.get("name_label") as Label
	var quest_progress_label_ := entry_data_.get("progress_label") as Label
	if quest_name_label_ == null or quest_progress_label_ == null or quest_ == null:
		return

	var quest_name_ := quest_.quest_data.quest_name if quest_.quest_data != null else String(quest_.quest_id)
	quest_name_label_.text = quest_name_
	quest_progress_label_.text = quest_.get_progress_text()

	if not bool(entry_data_.get("is_highlighted", false)):
		_apply_entry_colors(entry_data_, QUEST_NAME_COLOR, QUEST_PROGRESS_COLOR)


func _remove_entry(quest_id_: StringName) -> void:
	if not quest_entry_map.has(quest_id_):
		return

	var entry_data_: Dictionary = quest_entry_map.get(quest_id_, {})
	var highlight_tween_ := entry_data_.get("highlight_tween") as Tween
	if highlight_tween_ != null:
		highlight_tween_.kill()

	var entry_container_ := entry_data_.get("container") as Control
	if entry_container_ != null:
		entry_container_.queue_free()

	quest_entry_map.erase(quest_id_)


func _flash_completed_entry(quest_id_: StringName) -> void:
	if not quest_entry_map.has(quest_id_):
		return

	var entry_data_: Dictionary = quest_entry_map.get(quest_id_, {})
	var highlight_tween_ := entry_data_.get("highlight_tween") as Tween
	if highlight_tween_ != null:
		highlight_tween_.kill()

	entry_data_["is_highlighted"] = true
	var tween_ := create_tween()
	entry_data_["highlight_tween"] = tween_
	quest_entry_map[quest_id_] = entry_data_

	tween_.tween_method(_set_entry_highlight_weight.bind(quest_id_), 0.0, 1.0, ENTRY_COLOR_TWEEN_SECONDS)
	tween_.tween_interval(ENTRY_COMPLETED_HOLD_SECONDS)
	tween_.tween_method(_set_entry_highlight_weight.bind(quest_id_), 1.0, 0.0, ENTRY_COLOR_TWEEN_SECONDS)
	tween_.finished.connect(_on_entry_highlight_finished.bind(quest_id_))


func _set_entry_highlight_weight(weight_: float, quest_id_: StringName) -> void:
	if not quest_entry_map.has(quest_id_):
		return

	var entry_data_: Dictionary = quest_entry_map.get(quest_id_, {})
	var quest_name_color_ := QUEST_NAME_COLOR.lerp(QUEST_COMPLETED_NAME_COLOR, weight_)
	var quest_progress_color_ := QUEST_PROGRESS_COLOR.lerp(QUEST_COMPLETED_PROGRESS_COLOR, weight_)
	_apply_entry_colors(entry_data_, quest_name_color_, quest_progress_color_)


func _on_entry_highlight_finished(quest_id_: StringName) -> void:
	if not quest_entry_map.has(quest_id_):
		return

	var entry_data_: Dictionary = quest_entry_map.get(quest_id_, {})
	entry_data_["highlight_tween"] = null
	entry_data_["is_highlighted"] = false
	quest_entry_map[quest_id_] = entry_data_
	_apply_entry_colors(entry_data_, QUEST_NAME_COLOR, QUEST_PROGRESS_COLOR)


func _apply_entry_colors(entry_data_: Dictionary, quest_name_color_: Color, quest_progress_color_: Color) -> void:
	var quest_name_label_ := entry_data_.get("name_label") as Label
	var quest_progress_label_ := entry_data_.get("progress_label") as Label
	if quest_name_label_ == null or quest_progress_label_ == null:
		return

	quest_name_label_.add_theme_color_override("font_color", quest_name_color_)
	quest_progress_label_.add_theme_color_override("font_color", quest_progress_color_)


func _apply_panel_style() -> void:
	quest_panel.add_theme_stylebox_override("panel", _build_stylebox(PANEL_BACKGROUND_COLOR, PANEL_BORDER_COLOR, 2, 6))


func _set_mouse_filter_recursive(node_: Node, filter_: Control.MouseFilter) -> void:
	var control_ := node_ as Control
	if control_ != null:
		control_.mouse_filter = filter_

	for child_ in node_.get_children():
		_set_mouse_filter_recursive(child_, filter_)


func _build_stylebox(background_color_: Color, border_color_: Color, border_width_: int, corner_radius_: int) -> StyleBoxFlat:
	var stylebox_ := StyleBoxFlat.new()
	stylebox_.bg_color = background_color_
	stylebox_.border_color = border_color_
	stylebox_.border_width_left = border_width_
	stylebox_.border_width_top = border_width_
	stylebox_.border_width_right = border_width_
	stylebox_.border_width_bottom = border_width_
	stylebox_.corner_radius_top_left = corner_radius_
	stylebox_.corner_radius_top_right = corner_radius_
	stylebox_.corner_radius_bottom_left = corner_radius_
	stylebox_.corner_radius_bottom_right = corner_radius_
	return stylebox_


func _on_resized() -> void:
	call_deferred("_sync_panel_layout")


func _sync_panel_layout() -> void:
	if quest_panel == null:
		return

	quest_panel.reset_size()
	var panel_width_ := maxf(quest_panel.size.x, PANEL_MIN_WIDTH)
	var panel_position_x_ := maxf(size.x - panel_width_ - SCREEN_MARGIN, SCREEN_MARGIN)
	quest_panel.position = Vector2(panel_position_x_, SCREEN_MARGIN)
#endregion

#region Signals
func _on_quest_accepted(_quest_id_: StringName) -> void:
	_refresh_entries()


func _on_quest_progress_updated(_quest_id_: StringName, _current_: int, _target_: int) -> void:
	_refresh_entries()


func _on_quest_completed(quest_id_: StringName) -> void:
	_refresh_entries()
	_flash_completed_entry(quest_id_)


func _on_quest_turned_in(_quest_id_: StringName) -> void:
	_refresh_entries()
#endregion
