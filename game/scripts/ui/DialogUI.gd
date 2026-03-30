class_name DialogUI
extends CanvasLayer

const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")
const DialogChoiceDataResource = preload("res://game/scripts/data/DialogChoiceData.gd")
const CHOICE_BUTTON_MIN_WIDTH: float = 420.0

@export var text_speed: float = 50.0
@export var advance_action: StringName = &"interact"

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var continue_indicator: Control = $Panel/ContinueIndicator
@onready var choices_container: VBoxContainer = $Panel/ChoicesContainer

var is_typing: bool = false
var current_full_text: String = ""
var text_timer: float = 0.0
var char_index: int = 0
var pending_choices: Array[DialogChoiceDataResource] = []

#region Core Lifecycle
func _ready() -> void:
	assert(panel != null, "DialogUI requires Panel")
	assert(speaker_label != null, "DialogUI requires SpeakerLabel")
	assert(text_label != null, "DialogUI requires TextLabel")
	assert(continue_indicator != null, "DialogUI requires ContinueIndicator")
	assert(choices_container != null, "DialogUI requires ChoicesContainer")

	add_to_group("modal_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_dialog()

	var dialog_manager_ = _get_dialog_manager()
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

	var key_event_ := event_ as InputEventKey
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

	var dialog_manager_ = _get_dialog_manager()
	if dialog_manager_ != null:
		dialog_manager_.advance_text()
#endregion

#region Public
func show_dialog() -> void:
	visible = true
	panel.visible = true


func hide_dialog() -> void:
	visible = false
	panel.visible = false
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
	speaker_label.visible = not speaker_.is_empty()
	current_full_text = text_
	text_label.text = ""
	char_index = 0
	text_timer = 0.0
	is_typing = true
	pending_choices.clear()
	continue_indicator.visible = false
	_clear_choices()


func _on_choices_presented(choices_: Array) -> void:
	if is_typing:
		pending_choices = choices_.duplicate()
		return

	_show_choices(choices_)


func _on_choice_selected(choice_index_: int) -> void:
	var dialog_manager_ = _get_dialog_manager()
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
		button_.custom_minimum_size = Vector2(CHOICE_BUTTON_MIN_WIDTH, 44.0)
		button_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button_.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button_.focus_mode = Control.FOCUS_ALL
		button_.pressed.connect(_on_choice_selected.bind(index_))
		choices_container.add_child(button_)

	if choices_container.get_child_count() > 0:
		(choices_container.get_child(0) as Control).grab_focus()


func _clear_choices() -> void:
	for child_ in choices_container.get_children():
		child_.queue_free()


func _get_dialog_manager() -> Node:
	return get_node_or_null(DIALOG_MANAGER_PATH)
#endregion
