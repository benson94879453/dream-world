class_name QuestJournalUI
extends CanvasLayer

const QUEST_MANAGER_PATH: NodePath = NodePath("/root/QuestManager")
const SAVE_MANAGER_PATH: NodePath = NodePath("/root/SaveManager")

const QuestDataResource = preload("res://game/scripts/data/QuestData.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponDataResource = preload("res://game/scripts/data/WeaponData.gd")
const EnemyDataResource = preload("res://game/scripts/data/EnemyData.gd")
const UIColorsResource = preload("res://game/scripts/ui/UIColors.gd")

const ENEMY_DATA_ROOT: String = "res://game/data/enemies"

const PANEL_BACKGROUND_COLOR: Color = UIColorsResource.PANEL_BG
const PANEL_BORDER_COLOR: Color = UIColorsResource.PANEL_BORDER
const SECTION_PANEL_COLOR: Color = UIColorsResource.PANEL_BG_LIGHT
const DETAIL_PANEL_COLOR: Color = UIColorsResource.PANEL_BG_DARK
const ENTRY_BACKGROUND_COLOR: Color = UIColorsResource.ENTRY_BG
const ENTRY_SELECTED_BACKGROUND_COLOR: Color = UIColorsResource.ENTRY_SELECTED_BG
const ENTRY_SELECTED_BORDER_COLOR: Color = UIColorsResource.ENTRY_SELECTED_BORDER
const ENTRY_BORDER_COLOR: Color = UIColorsResource.PANEL_BORDER_DIM
const ENTRY_COMPLETED_BACKGROUND_COLOR: Color = UIColorsResource.ENTRY_COMPLETED_BG
const ENTRY_COMPLETED_BORDER_COLOR: Color = UIColorsResource.ENTRY_COMPLETED_BORDER
const TITLE_COLOR: Color = UIColorsResource.TITLE_COLOR
const BODY_TEXT_COLOR: Color = UIColorsResource.BODY_TEXT
const MUTED_TEXT_COLOR: Color = UIColorsResource.MUTED_TEXT
const COMPLETED_TEXT_COLOR: Color = UIColorsResource.COMPLETED_TEXT
const ACCENT_TEXT_COLOR: Color = UIColorsResource.ACCENT
const SUCCESS_TEXT_COLOR: Color = UIColorsResource.SUCCESS
const PROGRESS_BAR_FILL_COLOR: Color = UIColorsResource.PROGRESS_FILL
const PROGRESS_BAR_BG_COLOR: Color = UIColorsResource.PROGRESS_BG

const NPC_NAME_OVERRIDES: Dictionary = {
	&"npc_blacksmith": "鐵匠",
	&"npc_quest_board": "任務板",
	&"npc_instructor": "教官"
}

const QUEST_TYPE_LABELS: Dictionary = {
	QuestDataResource.QuestType.KILL: "討伐",
	QuestDataResource.QuestType.COLLECT: "收集",
	QuestDataResource.QuestType.TALK: "交談",
	QuestDataResource.QuestType.DELIVER: "交付"
}

@onready var backdrop: ColorRect = $Backdrop
@onready var main_panel: PanelContainer = $MainPanel
@onready var title_label: Label = $MainPanel/PanelMargin/Root/TitleBar/TitleBlock/TitleLabel
@onready var subtitle_label: Label = $MainPanel/PanelMargin/Root/TitleBar/TitleBlock/SubtitleLabel
@onready var close_hint_label: Label = $MainPanel/PanelMargin/Root/TitleBar/CloseHintLabel
@onready var left_panel: PanelContainer = $MainPanel/PanelMargin/Root/ContentRow/LeftPanel
@onready var active_count_label: Label = $MainPanel/PanelMargin/Root/ContentRow/LeftPanel/LeftMargin/LeftContent/ActiveSection/ActiveHeader/ActiveCountLabel
@onready var active_quest_list: VBoxContainer = $MainPanel/PanelMargin/Root/ContentRow/LeftPanel/LeftMargin/LeftContent/ActiveSection/ActiveQuestList
@onready var completed_count_label: Label = $MainPanel/PanelMargin/Root/ContentRow/LeftPanel/LeftMargin/LeftContent/CompletedSection/CompletedHeader/CompletedCountLabel
@onready var completed_quest_list: VBoxContainer = $MainPanel/PanelMargin/Root/ContentRow/LeftPanel/LeftMargin/LeftContent/CompletedSection/CompletedQuestList
@onready var right_panel: PanelContainer = $MainPanel/PanelMargin/Root/ContentRow/RightPanel
@onready var empty_state_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/EmptyStateLabel
@onready var quest_status_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestStatusLabel
@onready var quest_name_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestNameLabel
@onready var quest_meta_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestMetaLabel
@onready var quest_description_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestDescriptionLabel
@onready var progress_panel: PanelContainer = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestProgressPanel
@onready var progress_status_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestProgressPanel/ProgressMargin/ProgressContent/ProgressStatusLabel
@onready var progress_label: Label = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestProgressPanel/ProgressMargin/ProgressContent/ProgressLabel
@onready var progress_bar: ProgressBar = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestProgressPanel/ProgressMargin/ProgressContent/ProgressBar
@onready var quest_objectives_panel: PanelContainer = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestObjectivesPanel
@onready var quest_objectives_list: VBoxContainer = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestObjectivesPanel/ObjectivesMargin/ObjectivesContent/QuestObjectivesList
@onready var quest_rewards_panel: PanelContainer = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestRewardsPanel
@onready var quest_rewards_list: VBoxContainer = $MainPanel/PanelMargin/Root/ContentRow/RightPanel/DetailsMargin/DetailsContent/QuestRewardsPanel/RewardsMargin/RewardsContent/QuestRewardsList

var quest_manager: DWQuestManager = null
var save_manager: Node = null
var enemy_name_cache: Dictionary = {}
var active_records: Array[Dictionary] = []
var completed_records: Array[Dictionary] = []
var selected_quest_id: StringName = &""

#region Core Lifecycle
func _ready() -> void:
	assert(backdrop != null, "QuestJournalUI requires Backdrop")
	assert(main_panel != null, "QuestJournalUI requires MainPanel")
	assert(title_label != null, "QuestJournalUI requires TitleLabel")
	assert(subtitle_label != null, "QuestJournalUI requires SubtitleLabel")
	assert(close_hint_label != null, "QuestJournalUI requires CloseHintLabel")
	assert(left_panel != null, "QuestJournalUI requires LeftPanel")
	assert(active_count_label != null, "QuestJournalUI requires ActiveCountLabel")
	assert(active_quest_list != null, "QuestJournalUI requires ActiveQuestList")
	assert(completed_count_label != null, "QuestJournalUI requires CompletedCountLabel")
	assert(completed_quest_list != null, "QuestJournalUI requires CompletedQuestList")
	assert(right_panel != null, "QuestJournalUI requires RightPanel")
	assert(empty_state_label != null, "QuestJournalUI requires EmptyStateLabel")
	assert(quest_status_label != null, "QuestJournalUI requires QuestStatusLabel")
	assert(quest_name_label != null, "QuestJournalUI requires QuestNameLabel")
	assert(quest_meta_label != null, "QuestJournalUI requires QuestMetaLabel")
	assert(quest_description_label != null, "QuestJournalUI requires QuestDescriptionLabel")
	assert(progress_panel != null, "QuestJournalUI requires QuestProgressPanel")
	assert(progress_status_label != null, "QuestJournalUI requires ProgressStatusLabel")
	assert(progress_label != null, "QuestJournalUI requires ProgressLabel")
	assert(progress_bar != null, "QuestJournalUI requires ProgressBar")
	assert(quest_objectives_panel != null, "QuestJournalUI requires QuestObjectivesPanel")
	assert(quest_objectives_list != null, "QuestJournalUI requires QuestObjectivesList")
	assert(quest_rewards_panel != null, "QuestJournalUI requires QuestRewardsPanel")
	assert(quest_rewards_list != null, "QuestJournalUI requires QuestRewardsList")

	add_to_group("modal_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	_apply_theme()
	_bind_managers()
	_load_enemy_name_cache()
	_refresh_quest_lists()
#endregion

#region Input
func _input(event_: InputEvent) -> void:
	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	if visible and event_.is_action_pressed("ui_cancel"):
		set_journal_open(false)
		get_viewport().set_input_as_handled()
		return

	if not event_.is_action_pressed("ui_quest_journal"):
		return

	if visible:
		set_journal_open(false)
		get_viewport().set_input_as_handled()
		return

	if _is_other_modal_ui_open():
		return

	set_journal_open(true)
	get_viewport().set_input_as_handled()
#endregion

#region Public
func is_open() -> bool:
	return visible


func set_journal_open(open_: bool) -> void:
	if visible == open_ and not open_:
		return

	visible = open_
	if open_:
		_refresh_quest_lists()
#endregion

#region Helpers
func _bind_managers() -> void:
	quest_manager = get_node_or_null(QUEST_MANAGER_PATH) as DWQuestManager
	assert(quest_manager != null, "QuestJournalUI requires QuestManager autoload")
	save_manager = get_node_or_null(SAVE_MANAGER_PATH)

	if not quest_manager.quest_accepted.is_connected(_on_quest_changed):
		quest_manager.quest_accepted.connect(_on_quest_changed)
	if not quest_manager.quest_progress_updated.is_connected(_on_quest_progress_updated):
		quest_manager.quest_progress_updated.connect(_on_quest_progress_updated)
	if not quest_manager.quest_completed.is_connected(_on_quest_changed):
		quest_manager.quest_completed.connect(_on_quest_changed)
	if not quest_manager.quest_turned_in.is_connected(_on_quest_changed):
		quest_manager.quest_turned_in.connect(_on_quest_changed)


func _apply_theme() -> void:
	title_label.text = "任務日誌"
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	subtitle_label.text = ""
	subtitle_label.visible = false
	close_hint_label.text = "[J] 關閉"
	close_hint_label.add_theme_color_override("font_color", ACCENT_TEXT_COLOR)

	empty_state_label.text = "目前沒有可顯示的任務。"
	empty_state_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	quest_status_label.add_theme_color_override("font_color", ACCENT_TEXT_COLOR)
	quest_name_label.add_theme_color_override("font_color", BODY_TEXT_COLOR)
	quest_meta_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	quest_description_label.add_theme_color_override("font_color", BODY_TEXT_COLOR)
	progress_status_label.add_theme_color_override("font_color", ACCENT_TEXT_COLOR)
	progress_label.add_theme_color_override("font_color", BODY_TEXT_COLOR)

	backdrop.color = UIColorsResource.BACKDROP
	main_panel.add_theme_stylebox_override("panel", _build_panel_style(PANEL_BACKGROUND_COLOR, PANEL_BORDER_COLOR, UIColorsResource.MODAL_BORDER_WIDTH, UIColorsResource.MODAL_CORNER_RADIUS))
	left_panel.add_theme_stylebox_override("panel", _build_panel_style(SECTION_PANEL_COLOR, ENTRY_BORDER_COLOR, UIColorsResource.SUBPANEL_BORDER_WIDTH, UIColorsResource.SUBPANEL_CORNER_RADIUS))
	right_panel.add_theme_stylebox_override("panel", _build_panel_style(DETAIL_PANEL_COLOR, ENTRY_BORDER_COLOR, UIColorsResource.SUBPANEL_BORDER_WIDTH, UIColorsResource.SUBPANEL_CORNER_RADIUS))
	progress_panel.add_theme_stylebox_override("panel", _build_panel_style(SECTION_PANEL_COLOR, ENTRY_BORDER_COLOR, UIColorsResource.SUBPANEL_BORDER_WIDTH, UIColorsResource.SUBPANEL_CORNER_RADIUS))
	quest_objectives_panel.add_theme_stylebox_override("panel", _build_panel_style(SECTION_PANEL_COLOR, ENTRY_BORDER_COLOR, UIColorsResource.SUBPANEL_BORDER_WIDTH, UIColorsResource.SUBPANEL_CORNER_RADIUS))
	quest_rewards_panel.add_theme_stylebox_override("panel", _build_panel_style(SECTION_PANEL_COLOR, ENTRY_BORDER_COLOR, UIColorsResource.SUBPANEL_BORDER_WIDTH, UIColorsResource.SUBPANEL_CORNER_RADIUS))

	var progress_style_: StyleBoxFlat = StyleBoxFlat.new()
	progress_style_.bg_color = PROGRESS_BAR_BG_COLOR
	progress_style_.corner_radius_top_left = 4
	progress_style_.corner_radius_top_right = 4
	progress_style_.corner_radius_bottom_left = 4
	progress_style_.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", progress_style_)

	var fill_style_: StyleBoxFlat = StyleBoxFlat.new()
	fill_style_.bg_color = PROGRESS_BAR_FILL_COLOR
	fill_style_.corner_radius_top_left = 4
	fill_style_.corner_radius_top_right = 4
	fill_style_.corner_radius_bottom_left = 4
	fill_style_.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", fill_style_)
	progress_bar.show_percentage = false


func _refresh_quest_lists() -> void:
	if quest_manager == null:
		return

	active_records = _build_active_records()
	completed_records = _build_completed_records()

	active_count_label.text = "%d" % active_records.size()
	completed_count_label.text = "%d" % completed_records.size()

	_populate_quest_list(active_quest_list, active_records, false)
	_populate_quest_list(completed_quest_list, completed_records, true)
	_restore_or_select_default_quest()
	_refresh_details()


func _build_active_records() -> Array[Dictionary]:
	var records_: Array[Dictionary] = []
	for quest_ in quest_manager.get_active_quests():
		if quest_ == null or quest_.quest_data == null:
			continue

		records_.append({
			"quest_id": quest_.quest_id,
			"quest_data": quest_.quest_data,
			"quest_instance": quest_,
			"status": quest_.status,
			"current_progress": quest_.current_progress,
			"target_amount": maxi(quest_.target_amount, 1),
			"accepted_at": quest_.accepted_at
		})

	records_.sort_custom(func(left_: Dictionary, right_: Dictionary) -> bool:
		var left_time_: String = String(left_.get("accepted_at", ""))
		var right_time_: String = String(right_.get("accepted_at", ""))
		if left_time_ != right_time_:
			return left_time_ < right_time_
		return String(left_.get("quest_id", &"")) < String(right_.get("quest_id", &""))
	)
	return records_


func _build_completed_records() -> Array[Dictionary]:
	var records_: Array[Dictionary] = []
	for index_ in range(quest_manager.completed_quests.size() - 1, -1, -1):
		var quest_id_ := quest_manager.completed_quests[index_]
		var quest_data_: QuestDataResource = quest_manager.get_quest_data(quest_id_) as QuestDataResource
		if quest_data_ == null:
			continue

		records_.append({
			"quest_id": quest_id_,
			"quest_data": quest_data_,
			"quest_instance": null,
			"status": QuestDataResource.QuestStatus.TURNED_IN,
			"current_progress": maxi(quest_data_.target_amount, 1),
			"target_amount": maxi(quest_data_.target_amount, 1),
			"accepted_at": ""
		})

	return records_


func _populate_quest_list(container_: VBoxContainer, records_: Array[Dictionary], completed_section_: bool) -> void:
	_clear_container(container_)

	if records_.is_empty():
		var empty_label_: Label = Label.new()
		empty_label_.text = "尚無已回報任務" if completed_section_ else "目前沒有進行中的任務"
		empty_label_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label_.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
		empty_label_.add_theme_font_size_override("font_size", 13)
		container_.add_child(empty_label_)
		return

	for record_ in records_:
		container_.add_child(_create_quest_entry(record_, completed_section_))


func _create_quest_entry(record_: Dictionary, completed_section_: bool) -> Control:
	var quest_data_: QuestDataResource = record_.get("quest_data") as QuestDataResource
	var quest_id_: StringName = StringName(String(record_.get("quest_id", "")))
	var selected_: bool = quest_id_ == selected_quest_id
	var status_: QuestDataResource.QuestStatus = record_.get("status", QuestDataResource.QuestStatus.ACTIVE)

	var panel_: PanelContainer = PanelContainer.new()
	panel_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_.add_theme_stylebox_override("panel", _build_entry_style(selected_, completed_section_))

	var margin_: MarginContainer = MarginContainer.new()
	margin_.add_theme_constant_override("margin_left", 12)
	margin_.add_theme_constant_override("margin_top", 12)
	margin_.add_theme_constant_override("margin_right", 12)
	margin_.add_theme_constant_override("margin_bottom", 12)
	panel_.add_child(margin_)

	var content_: VBoxContainer = VBoxContainer.new()
	content_.add_theme_constant_override("separation", 6)
	margin_.add_child(content_)

	var button_: Button = Button.new()
	button_.flat = true
	button_.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_.text = quest_data_.quest_name if quest_data_ != null else String(quest_id_)
	button_.pressed.connect(_on_quest_selected.bind(quest_id_))
	button_.add_theme_font_size_override("font_size", 16)
	button_.add_theme_color_override("font_color", _get_entry_title_color(selected_, completed_section_, status_))
	button_.add_theme_stylebox_override("normal", _build_flat_button_style())
	button_.add_theme_stylebox_override("hover", _build_flat_button_style())
	button_.add_theme_stylebox_override("pressed", _build_flat_button_style())
	button_.add_theme_stylebox_override("focus", _build_flat_button_style())
	content_.add_child(button_)

	var meta_label_: Label = Label.new()
	meta_label_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label_.add_theme_font_size_override("font_size", 12)
	meta_label_.add_theme_color_override("font_color", _get_entry_meta_color(completed_section_, status_))
	meta_label_.text = "%s  ·  %s" % [_get_quest_type_label(quest_data_), _get_status_text(status_)]
	content_.add_child(meta_label_)

	var progress_text_label_: Label = Label.new()
	progress_text_label_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_text_label_.add_theme_font_size_override("font_size", 13)
	progress_text_label_.add_theme_color_override("font_color", _get_entry_progress_color(completed_section_, status_))
	progress_text_label_.text = _get_entry_progress_text(record_, completed_section_)
	content_.add_child(progress_text_label_)

	if not completed_section_:
		var progress_bar_: ProgressBar = ProgressBar.new()
		progress_bar_.show_percentage = false
		progress_bar_.max_value = float(maxi(int(record_.get("target_amount", 1)), 1))
		progress_bar_.value = float(_get_progress_value(record_))
		progress_bar_.custom_minimum_size = Vector2(0.0, 10.0)
		progress_bar_.add_theme_stylebox_override("background", _build_progress_style(PROGRESS_BAR_BG_COLOR))
		progress_bar_.add_theme_stylebox_override("fill", _build_progress_style(PROGRESS_BAR_FILL_COLOR))
		content_.add_child(progress_bar_)

	return panel_


func _restore_or_select_default_quest() -> void:
	if not _find_record_by_id(selected_quest_id).is_empty():
		return

	if not active_records.is_empty():
		selected_quest_id = StringName(String(active_records[0].get("quest_id", "")))
		return

	if not completed_records.is_empty():
		selected_quest_id = StringName(String(completed_records[0].get("quest_id", "")))
		return

	selected_quest_id = &""


func _refresh_details() -> void:
	var record_: Dictionary = _find_record_by_id(selected_quest_id)
	if record_.is_empty():
		_show_empty_state()
		return

	var quest_data_: QuestDataResource = record_.get("quest_data") as QuestDataResource
	if quest_data_ == null:
		_show_empty_state()
		return

	var status_: QuestDataResource.QuestStatus = record_.get("status", QuestDataResource.QuestStatus.ACTIVE)
	var target_amount_: int = maxi(int(record_.get("target_amount", 1)), 1)
	var current_progress_: int = _get_progress_value(record_)

	empty_state_label.visible = false
	quest_status_label.visible = true
	quest_name_label.visible = true
	quest_meta_label.visible = true
	quest_description_label.visible = true
	progress_panel.visible = true
	quest_objectives_panel.visible = true
	quest_rewards_panel.visible = true

	quest_status_label.text = _get_status_text(status_)
	quest_status_label.add_theme_color_override("font_color", _get_status_color(status_))
	quest_name_label.text = quest_data_.quest_name
	quest_meta_label.text = "類型：%s" % _get_quest_type_label(quest_data_)
	quest_description_label.text = quest_data_.quest_description

	progress_status_label.text = "任務進度"
	progress_label.text = _get_detail_progress_text(record_)
	progress_bar.max_value = float(target_amount_)
	progress_bar.value = float(current_progress_)

	_populate_detail_lines(quest_objectives_list, _build_objective_lines(record_), BODY_TEXT_COLOR)
	_populate_detail_lines(quest_rewards_list, _build_reward_lines(quest_data_), BODY_TEXT_COLOR)


func _show_empty_state() -> void:
	empty_state_label.visible = true
	quest_status_label.visible = false
	quest_name_label.visible = false
	quest_meta_label.visible = false
	quest_description_label.visible = false
	progress_panel.visible = false
	quest_objectives_panel.visible = false
	quest_rewards_panel.visible = false


func _build_objective_lines(record_: Dictionary) -> PackedStringArray:
	var lines_: PackedStringArray = []
	var quest_data_: QuestDataResource = record_.get("quest_data") as QuestDataResource
	if quest_data_ == null:
		return lines_

	var target_amount_: int = maxi(int(record_.get("target_amount", 1)), 1)
	var current_progress_: int = _get_progress_value(record_)
	var status_: QuestDataResource.QuestStatus = record_.get("status", QuestDataResource.QuestStatus.ACTIVE)

	match quest_data_.quest_type:
		QuestDataResource.QuestType.KILL:
			lines_.append("目標：擊敗 %s %d 次" % [_resolve_enemy_name(quest_data_.target_enemy_id), target_amount_])
		QuestDataResource.QuestType.COLLECT:
			lines_.append("目標：收集 %s %d 個" % [_resolve_item_name(quest_data_.target_item_id), target_amount_])
		QuestDataResource.QuestType.TALK:
			lines_.append("目標：與 %s 交談" % _resolve_npc_name(quest_data_.target_npc_id))
		QuestDataResource.QuestType.DELIVER:
			lines_.append("目標：交付 %s %d 個給 %s" % [
				_resolve_item_name(quest_data_.target_item_id),
				target_amount_,
				_resolve_npc_name(quest_data_.target_npc_id)
			])
		_:
			lines_.append("目標：完成任務需求")

	if status_ == QuestDataResource.QuestStatus.TURNED_IN:
		lines_.append("狀態：任務已回報")
	elif status_ == QuestDataResource.QuestStatus.COMPLETED:
		lines_.append("狀態：條件已完成，回到 %s 回報任務" % _resolve_npc_name(quest_data_.target_npc_id))
	else:
		lines_.append("進度：%d/%d" % [current_progress_, target_amount_])

	return lines_


func _build_reward_lines(quest_data_: QuestDataResource) -> PackedStringArray:
	var lines_: PackedStringArray = []
	if quest_data_ == null:
		return lines_

	if quest_data_.reward_gold > 0:
		lines_.append("金幣 x %d" % quest_data_.reward_gold)
	if quest_data_.reward_item_id != &"" and quest_data_.reward_item_amount > 0:
		lines_.append("%s x %d" % [_resolve_item_name(quest_data_.reward_item_id), quest_data_.reward_item_amount])
	if quest_data_.reward_weapon_id != &"":
		lines_.append(_resolve_weapon_name(quest_data_.reward_weapon_id))

	if lines_.is_empty():
		lines_.append("無額外獎勵")

	return lines_


func _populate_detail_lines(container_: VBoxContainer, lines_: PackedStringArray, text_color_: Color) -> void:
	_clear_container(container_)

	for line_ in lines_:
		var label_: Label = Label.new()
		label_.text = "• %s" % line_
		label_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_.add_theme_font_size_override("font_size", 14)
		label_.add_theme_color_override("font_color", text_color_)
		container_.add_child(label_)


func _find_record_by_id(quest_id_: StringName) -> Dictionary:
	if quest_id_.is_empty():
		return {}

	for record_ in active_records:
		if record_.get("quest_id", &"") == quest_id_:
			return record_

	for record_ in completed_records:
		if record_.get("quest_id", &"") == quest_id_:
			return record_

	return {}


func _get_progress_value(record_: Dictionary) -> int:
	var status_: QuestDataResource.QuestStatus = record_.get("status", QuestDataResource.QuestStatus.ACTIVE)
	var target_amount_: int = maxi(int(record_.get("target_amount", 1)), 1)
	if status_ == QuestDataResource.QuestStatus.COMPLETED or status_ == QuestDataResource.QuestStatus.TURNED_IN:
		return target_amount_
	return clampi(int(record_.get("current_progress", 0)), 0, target_amount_)


func _get_entry_progress_text(record_: Dictionary, completed_section_: bool) -> String:
	var status_: QuestDataResource.QuestStatus = record_.get("status", QuestDataResource.QuestStatus.ACTIVE)
	if completed_section_ or status_ == QuestDataResource.QuestStatus.TURNED_IN:
		return "已回報"
	if status_ == QuestDataResource.QuestStatus.COMPLETED:
		return "已完成，等待回報"
	return "進度 %d/%d" % [_get_progress_value(record_), maxi(int(record_.get("target_amount", 1)), 1)]


func _get_detail_progress_text(record_: Dictionary) -> String:
	var status_: QuestDataResource.QuestStatus = record_.get("status", QuestDataResource.QuestStatus.ACTIVE)
	var target_amount_: int = maxi(int(record_.get("target_amount", 1)), 1)
	var current_progress_: int = _get_progress_value(record_)

	match status_:
		QuestDataResource.QuestStatus.TURNED_IN:
			return "已完成並回報"
		QuestDataResource.QuestStatus.COMPLETED:
			return "已達成 %d/%d，等待回報" % [current_progress_, target_amount_]
		_:
			return "%d/%d" % [current_progress_, target_amount_]


func _get_quest_type_label(quest_data_: QuestDataResource) -> String:
	if quest_data_ == null:
		return "未知"
	return String(QUEST_TYPE_LABELS.get(quest_data_.quest_type, "未知"))


func _get_status_text(status_: QuestDataResource.QuestStatus) -> String:
	match status_:
		QuestDataResource.QuestStatus.COMPLETED:
			return "已完成，可回報"
		QuestDataResource.QuestStatus.TURNED_IN:
			return "已回報"
		_:
			return "進行中"


func _get_status_color(status_: QuestDataResource.QuestStatus) -> Color:
	match status_:
		QuestDataResource.QuestStatus.COMPLETED:
			return ACCENT_TEXT_COLOR
		QuestDataResource.QuestStatus.TURNED_IN:
			return SUCCESS_TEXT_COLOR
		_:
			return TITLE_COLOR


func _get_entry_title_color(selected_: bool, completed_section_: bool, status_: QuestDataResource.QuestStatus) -> Color:
	if completed_section_ or status_ == QuestDataResource.QuestStatus.TURNED_IN:
		return ACCENT_TEXT_COLOR if selected_ else COMPLETED_TEXT_COLOR
	if status_ == QuestDataResource.QuestStatus.COMPLETED:
		return ACCENT_TEXT_COLOR
	return TITLE_COLOR if selected_ else BODY_TEXT_COLOR


func _get_entry_meta_color(completed_section_: bool, status_: QuestDataResource.QuestStatus) -> Color:
	if completed_section_ or status_ == QuestDataResource.QuestStatus.TURNED_IN:
		return COMPLETED_TEXT_COLOR
	if status_ == QuestDataResource.QuestStatus.COMPLETED:
		return ACCENT_TEXT_COLOR
	return MUTED_TEXT_COLOR


func _get_entry_progress_color(completed_section_: bool, status_: QuestDataResource.QuestStatus) -> Color:
	if completed_section_ or status_ == QuestDataResource.QuestStatus.TURNED_IN:
		return COMPLETED_TEXT_COLOR
	if status_ == QuestDataResource.QuestStatus.COMPLETED:
		return SUCCESS_TEXT_COLOR
	return BODY_TEXT_COLOR


func _resolve_npc_name(npc_id_: StringName) -> String:
	if npc_id_.is_empty():
		return "目標 NPC"
	if NPC_NAME_OVERRIDES.has(npc_id_):
		return String(NPC_NAME_OVERRIDES[npc_id_])
	return _humanize_identifier(String(npc_id_), "npc_")


func _resolve_item_name(item_id_: StringName) -> String:
	if item_id_.is_empty():
		return "未知物品"
	if save_manager != null and save_manager.has_method("resolve_item_data"):
		var item_data_: ItemDataResource = save_manager.call("resolve_item_data", item_id_) as ItemDataResource
		if item_data_ != null and not item_data_.display_name.is_empty():
			return item_data_.display_name
	return _humanize_identifier(String(item_id_), "")


func _resolve_weapon_name(weapon_id_: StringName) -> String:
	if weapon_id_.is_empty():
		return "未知武器"
	if save_manager != null and save_manager.has_method("resolve_weapon_data"):
		var weapon_data_: WeaponDataResource = save_manager.call("resolve_weapon_data", weapon_id_) as WeaponDataResource
		if weapon_data_ != null and not weapon_data_.display_name.is_empty():
			return weapon_data_.display_name
	return _humanize_identifier(String(weapon_id_), "")


func _resolve_enemy_name(enemy_id_: StringName) -> String:
	if enemy_id_.is_empty():
		return "敵人"
	if enemy_name_cache.has(enemy_id_):
		return String(enemy_name_cache[enemy_id_])
	return _humanize_identifier(String(enemy_id_), "en_")


func _load_enemy_name_cache() -> void:
	enemy_name_cache.clear()

	for resource_path_ in _collect_resource_paths(ENEMY_DATA_ROOT):
		var enemy_data_: EnemyDataResource = load(resource_path_) as EnemyDataResource
		if enemy_data_ == null or enemy_data_.enemy_id.is_empty():
			continue
		if enemy_data_.display_name.is_empty():
			enemy_name_cache[enemy_data_.enemy_id] = _humanize_identifier(String(enemy_data_.enemy_id), "en_")
			continue
		enemy_name_cache[enemy_data_.enemy_id] = enemy_data_.display_name


func _collect_resource_paths(root_path_: String) -> PackedStringArray:
	var resource_paths_: PackedStringArray = []
	var directory_ := DirAccess.open(root_path_)
	if directory_ == null:
		return resource_paths_

	directory_.list_dir_begin()
	while true:
		var entry_name_ := directory_.get_next()
		if entry_name_.is_empty():
			break
		if entry_name_.begins_with("."):
			continue

		var entry_path_ := "%s/%s" % [root_path_, entry_name_]
		if directory_.current_is_dir():
			resource_paths_.append_array(_collect_resource_paths(entry_path_))
			continue

		if entry_name_.ends_with(".tres"):
			resource_paths_.append(entry_path_)

	return resource_paths_


func _humanize_identifier(identifier_: String, prefix_: String) -> String:
	var value_: String = identifier_
	if not prefix_.is_empty() and value_.begins_with(prefix_):
		value_ = value_.trim_prefix(prefix_)
	var parts_: PackedStringArray = value_.split("_", false)
	for index_ in range(parts_.size()):
		parts_[index_] = String(parts_[index_]).capitalize()
	return " ".join(parts_)


func _clear_container(container_: Node) -> void:
	for child_ in container_.get_children():
		child_.queue_free()


func _build_panel_style(background_color_: Color, border_color_: Color, border_width_: int, corner_radius_: int) -> StyleBoxFlat:
	var stylebox_: StyleBoxFlat = StyleBoxFlat.new()
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


func _build_entry_style(selected_: bool, completed_section_: bool) -> StyleBoxFlat:
	if selected_:
		return _build_panel_style(ENTRY_SELECTED_BACKGROUND_COLOR, ENTRY_SELECTED_BORDER_COLOR, 2, 6)
	if completed_section_:
		return _build_panel_style(ENTRY_COMPLETED_BACKGROUND_COLOR, ENTRY_COMPLETED_BORDER_COLOR, 1, 6)
	return _build_panel_style(ENTRY_BACKGROUND_COLOR, ENTRY_BORDER_COLOR, 1, 6)


func _build_flat_button_style() -> StyleBoxFlat:
	var stylebox_: StyleBoxFlat = StyleBoxFlat.new()
	stylebox_.draw_center = false
	return stylebox_


func _build_progress_style(color_: Color) -> StyleBoxFlat:
	var stylebox_: StyleBoxFlat = StyleBoxFlat.new()
	stylebox_.bg_color = color_
	stylebox_.corner_radius_top_left = 4
	stylebox_.corner_radius_top_right = 4
	stylebox_.corner_radius_bottom_left = 4
	stylebox_.corner_radius_bottom_right = 4
	return stylebox_


func _is_other_modal_ui_open() -> bool:
	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		if modal_ui_ == null or modal_ui_ == self:
			continue
		if modal_ui_.visible:
			return true
	return false
#endregion

#region Signals
func _on_quest_selected(quest_id_: StringName) -> void:
	selected_quest_id = quest_id_
	_refresh_quest_lists()


func _on_quest_changed(_quest_id_: StringName) -> void:
	_refresh_quest_lists()


func _on_quest_progress_updated(_quest_id_: StringName, _current_: int, _target_: int) -> void:
	_refresh_quest_lists()
#endregion
