class_name QuestToastUI
extends Control

const QUEST_MANAGER_PATH: NodePath = NodePath("/root/QuestManager")
const QuestDataResource = preload("res://game/scripts/data/QuestData.gd")
const QuestInstanceResource = preload("res://game/scripts/data/QuestInstance.gd")
const UIColorsResource = preload("res://game/scripts/ui/UIColors.gd")

const MAX_QUEUE_LENGTH: int = 5
const TOAST_FADE_SECONDS: float = 0.3
const TOAST_HOLD_SECONDS: float = 2.0
const TOAST_ACCEPTED_COLOR: Color = UIColorsResource.TOAST_ACCEPTED_COLOR
const TOAST_COMPLETED_COLOR: Color = UIColorsResource.TOAST_COMPLETED_COLOR
const TOAST_TURNED_IN_COLOR: Color = UIColorsResource.TOAST_TURNED_IN_COLOR
const PANEL_BACKGROUND_COLOR: Color = UIColorsResource.TOAST_BG
const PANEL_BORDER_COLOR: Color = UIColorsResource.TOAST_BORDER
const SHADOW_COLOR: Color = UIColorsResource.TOAST_SHADOW

@onready var top_bar: HBoxContainer = $TopBar
@onready var toast_panel: PanelContainer = $TopBar/ToastPanel
@onready var toast_label: Label = $TopBar/ToastPanel/ToastMargin/ToastLabel

var quest_manager: DWQuestManager = null
var toast_queue: Array[Dictionary] = []
var active_tween: Tween = null
var is_showing_toast: bool = false

#region Core Lifecycle
func _ready() -> void:
	assert(top_bar != null, "QuestToastUI requires TopBar")
	assert(toast_panel != null, "QuestToastUI requires ToastPanel")
	assert(toast_label != null, "QuestToastUI requires ToastLabel")

	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)
	_apply_panel_style()
	_reset_toast_visuals()
	_bind_quest_manager()
#endregion

#region Helpers
func _bind_quest_manager() -> void:
	quest_manager = get_node_or_null(QUEST_MANAGER_PATH) as DWQuestManager
	assert(quest_manager != null, "QuestToastUI requires QuestManager autoload")

	if not quest_manager.quest_accepted.is_connected(_on_quest_accepted):
		quest_manager.quest_accepted.connect(_on_quest_accepted)
	if not quest_manager.quest_completed.is_connected(_on_quest_completed):
		quest_manager.quest_completed.connect(_on_quest_completed)
	if not quest_manager.quest_turned_in.is_connected(_on_quest_turned_in):
		quest_manager.quest_turned_in.connect(_on_quest_turned_in)


func _enqueue_toast(text_: String, font_color_: Color) -> void:
	var toast_data_: Dictionary = {
		"text": text_,
		"font_color": font_color_
	}
	if toast_queue.size() >= MAX_QUEUE_LENGTH:
		toast_queue.pop_front()

	toast_queue.append(toast_data_)
	_try_show_next_toast()


func _try_show_next_toast() -> void:
	if is_showing_toast or toast_queue.is_empty():
		return

	var toast_data_: Dictionary = toast_queue.pop_front()
	_show_toast(toast_data_)


func _show_toast(toast_data_: Dictionary) -> void:
	if active_tween != null:
		active_tween.kill()
		active_tween = null

	is_showing_toast = true
	var toast_text_: String = String(toast_data_.get("text", ""))
	var toast_color_: Color = toast_data_.get("font_color", TOAST_ACCEPTED_COLOR)
	toast_label.text = toast_text_
	toast_label.add_theme_color_override("font_color", toast_color_)
	toast_panel.visible = true
	toast_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)

	active_tween = create_tween()
	active_tween.tween_property(toast_panel, "modulate:a", 1.0, TOAST_FADE_SECONDS)
	active_tween.tween_interval(TOAST_HOLD_SECONDS)
	active_tween.tween_property(toast_panel, "modulate:a", 0.0, TOAST_FADE_SECONDS)
	active_tween.finished.connect(_on_toast_animation_finished)


func _on_toast_animation_finished() -> void:
	_reset_toast_visuals()
	is_showing_toast = false
	active_tween = null
	_try_show_next_toast()


func _reset_toast_visuals() -> void:
	toast_panel.visible = false
	toast_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	toast_label.text = ""
	toast_label.add_theme_color_override("font_color", TOAST_ACCEPTED_COLOR)


func _apply_panel_style() -> void:
	var stylebox_: StyleBoxFlat = StyleBoxFlat.new()
	stylebox_.bg_color = PANEL_BACKGROUND_COLOR
	stylebox_.border_color = PANEL_BORDER_COLOR
	stylebox_.border_width_left = 2
	stylebox_.border_width_top = 2
	stylebox_.border_width_right = 2
	stylebox_.border_width_bottom = 2
	stylebox_.corner_radius_top_left = 6
	stylebox_.corner_radius_top_right = 6
	stylebox_.corner_radius_bottom_left = 6
	stylebox_.corner_radius_bottom_right = 6
	stylebox_.shadow_color = SHADOW_COLOR
	stylebox_.shadow_size = 4
	stylebox_.shadow_offset = Vector2(0.0, 2.0)
	toast_panel.add_theme_stylebox_override("panel", stylebox_)


func _set_mouse_filter_recursive(node_: Node, filter_: Control.MouseFilter) -> void:
	var control_: Control = node_ as Control
	if control_ != null:
		control_.mouse_filter = filter_

	for child_ in node_.get_children():
		_set_mouse_filter_recursive(child_, filter_)


func _resolve_quest_data(quest_id_: StringName) -> QuestDataResource:
	if quest_manager == null:
		return null

	var quest_instance_: QuestInstanceResource = quest_manager.get_quest_by_id(quest_id_)
	if quest_instance_ != null and quest_instance_.quest_data != null:
		return quest_instance_.quest_data

	return quest_manager.get_quest_data(quest_id_)


func _get_quest_name(quest_id_: StringName) -> String:
	var quest_data_: QuestDataResource = _resolve_quest_data(quest_id_)
	if quest_data_ != null and not quest_data_.quest_name.is_empty():
		return quest_data_.quest_name
	return String(quest_id_)


func _get_reward_gold(quest_id_: StringName) -> int:
	var quest_data_: QuestDataResource = _resolve_quest_data(quest_id_)
	if quest_data_ == null:
		return 0
	return quest_data_.reward_gold
#endregion

#region Signals
func _on_quest_accepted(quest_id_: StringName) -> void:
	_enqueue_toast("已接取：%s" % _get_quest_name(quest_id_), TOAST_ACCEPTED_COLOR)


func _on_quest_completed(quest_id_: StringName) -> void:
	_enqueue_toast("任務完成：%s" % _get_quest_name(quest_id_), TOAST_COMPLETED_COLOR)


func _on_quest_turned_in(quest_id_: StringName) -> void:
	var quest_name_: String = _get_quest_name(quest_id_)
	var reward_gold_: int = _get_reward_gold(quest_id_)
	_enqueue_toast("任務回報：%s +%d 金" % [quest_name_, reward_gold_], TOAST_TURNED_IN_COLOR)
#endregion
