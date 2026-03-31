class_name DialogUI
extends CanvasLayer

const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")
const DialogChoiceDataResource = preload("res://game/scripts/data/DialogChoiceData.gd")
const UIColorsResource = preload("res://game/scripts/ui/UIColors.gd")
const CHOICE_BUTTON_MIN_WIDTH: float = 360.0

@export var text_speed: float = 50.0
@export var advance_action: StringName = &"interact"

@onready var root_control: Control = $Root
@onready var bottom_gradient: Panel = $Root/BottomGradient
@onready var dialog_area: VBoxContainer = $Root/DialogArea
@onready var speaker_badge: PanelContainer = $Root/DialogArea/SpeakerBadge
@onready var speaker_label: Label = $Root/DialogArea/SpeakerBadge/SpeakerMargin/SpeakerLabel
@onready var text_label: Label = $Root/DialogArea/TextLabel
@onready var continue_indicator: Control = $Root/DialogArea/ContinueIndicator
@onready var choices_container: VBoxContainer = $Root/ChoicesContainer

var _speaker_separator: ColorRect = null

var is_typing: bool = false
var current_full_text: String = ""
var text_timer: float = 0.0
var char_index: int = 0
var pending_choices: Array[DialogChoiceDataResource] = []

#region Core Lifecycle
func _ready() -> void:
	assert(root_control != null, "DialogUI requires Root Control")
	assert(bottom_gradient != null, "DialogUI requires BottomGradient")
	assert(dialog_area != null, "DialogUI requires DialogArea")
	assert(speaker_badge != null, "DialogUI requires SpeakerBadge")
	assert(speaker_label != null, "DialogUI requires SpeakerLabel")
	assert(text_label != null, "DialogUI requires TextLabel")
	assert(continue_indicator != null, "DialogUI requires ContinueIndicator")
	assert(choices_container != null, "DialogUI requires ChoicesContainer")

	add_to_group("modal_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_speaker_separator()
	_apply_style()
	hide_dialog()

	var tween_: Tween = create_tween().set_loops()
	tween_.tween_property(continue_indicator, "modulate:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_.tween_property(continue_indicator, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var dialog_manager_: Node = _get_dialog_manager()
	assert(dialog_manager_ != null, "DialogUI requires DialogManager autoload")
	dialog_manager_.text_advanced.connect(_on_text_advanced)
	dialog_manager_.choices_presented.connect(_on_choices_presented)
	dialog_manager_.dialog_ended.connect(_on_dialog_ended)


func _process(delta_: float) -> void:
	if not is_typing:
		return

	text_timer += delta_ * text_speed
	var target_index_: int = mini(int(text_timer), current_full_text.length())
	if target_index_ > char_index:
		char_index = target_index_
		text_label.text = current_full_text.substr(0, char_index)

	if char_index < current_full_text.length():
		return

	is_typing = false
	if not pending_choices.is_empty():
		_show_choices(pending_choices)
		pending_choices.clear()
		return

	continue_indicator.visible = true


func _unhandled_input(event_: InputEvent) -> void:
	if not visible:
		return

	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	if not event_.is_action_pressed(String(advance_action)):
		return

	get_viewport().set_input_as_handled()

	if is_typing:
		_finish_current_text()
		return

	if choices_container.get_child_count() > 0:
		return

	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ != null:
		dialog_manager_.advance_text()
#endregion

#region Public
func show_dialog() -> void:
	visible = true
	root_control.visible = true


func hide_dialog() -> void:
	visible = false
	root_control.visible = false
	is_typing = false
	current_full_text = ""
	text_timer = 0.0
	char_index = 0
	pending_choices.clear()
	text_label.text = ""
	speaker_label.text = ""
	continue_indicator.visible = false
	_clear_choices()
#endregion

#region Helpers
func _on_text_advanced(text_: String, speaker_: String) -> void:
	show_dialog()
	speaker_label.text = speaker_
	speaker_badge.visible = not speaker_.is_empty()
	if _speaker_separator != null:
		_speaker_separator.visible = not speaker_.is_empty()
	current_full_text = text_
	text_label.text = ""
	char_index = 0
	text_timer = 0.0
	is_typing = true
	pending_choices.clear()
	continue_indicator.visible = false
	_clear_choices()
	_resize_dialog_area(text_)


func _on_choices_presented(choices_: Array) -> void:
	if is_typing:
		pending_choices = choices_.duplicate()
		return

	_show_choices(choices_)


func _on_choice_selected(choice_index_: int) -> void:
	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ != null:
		dialog_manager_.select_choice(choice_index_)


func _on_dialog_ended(_dialog_id_: StringName) -> void:
	hide_dialog()


func _finish_current_text() -> void:
	is_typing = false
	char_index = current_full_text.length()
	text_label.text = current_full_text

	if not pending_choices.is_empty():
		_show_choices(pending_choices)
		pending_choices.clear()
		continue_indicator.visible = false
		return

	continue_indicator.visible = true


func _show_choices(choices_: Array) -> void:
	continue_indicator.visible = false
	_clear_choices()

	for index_ in range(choices_.size()):
		var button_: Button = Button.new()
		button_.text = choices_[index_].choice_text
		button_.custom_minimum_size = Vector2(CHOICE_BUTTON_MIN_WIDTH, 38.0)
		button_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button_.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_.focus_mode = Control.FOCUS_ALL
		_apply_choice_style(button_)
		button_.pressed.connect(_on_choice_selected.bind(index_))
		choices_container.add_child(button_)

	if choices_container.get_child_count() > 0:
		(choices_container.get_child(0) as Control).grab_focus()


func _clear_choices() -> void:
	for child_ in choices_container.get_children():
		child_.queue_free()


func _get_dialog_manager() -> Node:
	return get_node_or_null(DIALOG_MANAGER_PATH)


func _resize_dialog_area(full_text_: String) -> void:
	var font_: Font = text_label.get_theme_font("font")
	var font_size_: int = text_label.get_theme_font_size("font_size")
	var available_width_: float = text_label.custom_minimum_size.x
	if available_width_ <= 0.0:
		available_width_ = 800.0

	var text_size_: Vector2 = font_.get_multiline_string_size(full_text_, HORIZONTAL_ALIGNMENT_CENTER, available_width_, font_size_)
	var text_height_: float = text_size_.y
	# speaker(~32) + separator(~12) + text + continue(~24) + spacing(~20) + padding(~40)
	var total_height_: float = clampf(text_height_ + 128.0, 110.0, 280.0)

	dialog_area.offset_top = -total_height_


# Decorative golden line under speaker name
func _build_speaker_separator() -> void:
	_speaker_separator = ColorRect.new()
	_speaker_separator.custom_minimum_size = Vector2(60.0, 1.5)
	_speaker_separator.color = Color(0.84, 0.71, 0.40, 0.5)
	_speaker_separator.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_speaker_separator.visible = false
	dialog_area.add_child(_speaker_separator)
	dialog_area.move_child(_speaker_separator, 1) # After SpeakerBadge, before TextLabel


func _apply_choice_style(button_: Button) -> void:
	var normal_bg_ := UIColorsResource.build_panel_style(Color(0.10, 0.10, 0.12, 0.65), Color(0.84, 0.71, 0.40, 0.25), 1, 22)
	var hover_bg_ := UIColorsResource.build_panel_style(Color(0.16, 0.14, 0.11, 0.82), Color(0.84, 0.71, 0.40, 0.7), 1, 22)
	button_.add_theme_stylebox_override("normal", normal_bg_)
	button_.add_theme_stylebox_override("hover", hover_bg_)
	button_.add_theme_stylebox_override("pressed", hover_bg_)
	button_.add_theme_stylebox_override("focus", hover_bg_)
	button_.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82, 0.9))
	button_.add_theme_color_override("font_hover_color", Color(0.98, 0.94, 0.82, 1.0))
	button_.add_theme_color_override("font_focus_color", Color(0.98, 0.94, 0.82, 1.0))
	button_.add_theme_font_size_override("font_size", 15)


func _apply_style() -> void:
	# Bottom gradient with a thin golden top-edge line
	var gradient_style_: StyleBoxFlat = StyleBoxFlat.new()
	gradient_style_.bg_color = Color(0.0, 0.0, 0.0, 0.40)
	gradient_style_.border_color = Color(0.84, 0.71, 0.40, 0.3)
	gradient_style_.border_width_top = 1
	gradient_style_.border_width_left = 0
	gradient_style_.border_width_right = 0
	gradient_style_.border_width_bottom = 0
	bottom_gradient.add_theme_stylebox_override("panel", gradient_style_)

	# Speaker badge: subtle golden border frame
	var badge_style_ := UIColorsResource.build_panel_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.84, 0.71, 0.40, 0.4), 1, 4)
	speaker_badge.add_theme_stylebox_override("panel", badge_style_)
	speaker_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.55, 1.0))
	text_label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.96, 1.0))
	continue_indicator.add_theme_color_override("font_color", Color(0.94, 0.82, 0.49, 0.7))
#endregion
