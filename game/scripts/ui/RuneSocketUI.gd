class_name RuneSocketUI
extends Control

const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const RuneSlotResource = preload("res://game/scripts/data/RuneSlot.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")
const WRAPPED_TEXT_MIN_WIDTH: float = 220.0

var current_weapon: WeaponInstanceResource = null
var current_inventory: InventoryResource = null
var selected_slot_index: int = -1
var selected_rune: RuneDataResource = null

@onready var slot_button_1: Button = $Root/SlotContainer/SlotButton1
@onready var slot_button_2: Button = $Root/SlotContainer/SlotButton2
@onready var slot_button_3: Button = $Root/SlotContainer/SlotButton3
@onready var slot_button_4: Button = $Root/SlotContainer/SlotButton4
@onready var slot_button_5: Button = $Root/SlotContainer/SlotButton5
@onready var gold_label: Label = $Root/GoldLabel
@onready var selected_slot_label: Label = $Root/SelectedSlotLabel
@onready var equipped_rune_info: Label = $Root/EquippedRuneInfo
@onready var empty_state_label: Label = $Root/RuneListPanel/RuneListContent/EmptyStateLabel
@onready var rune_list: VBoxContainer = $Root/RuneListPanel/RuneListContent/RuneList
@onready var status_label: Label = $Root/StatusLabel
@onready var equip_button: Button = $Root/ActionRow/EquipButton
@onready var unequip_button: Button = $Root/ActionRow/UnequipButton

var slot_buttons: Array[Button] = []

#region Core Lifecycle
func _ready() -> void:
	assert(slot_button_1 != null, "RuneSocketUI requires SlotButton1")
	assert(slot_button_2 != null, "RuneSocketUI requires SlotButton2")
	assert(slot_button_3 != null, "RuneSocketUI requires SlotButton3")
	assert(slot_button_4 != null, "RuneSocketUI requires SlotButton4")
	assert(slot_button_5 != null, "RuneSocketUI requires SlotButton5")
	assert(gold_label != null, "RuneSocketUI requires GoldLabel")
	assert(selected_slot_label != null, "RuneSocketUI requires SelectedSlotLabel")
	assert(equipped_rune_info != null, "RuneSocketUI requires EquippedRuneInfo")
	assert(empty_state_label != null, "RuneSocketUI requires EmptyStateLabel")
	assert(rune_list != null, "RuneSocketUI requires RuneList")
	assert(status_label != null, "RuneSocketUI requires StatusLabel")
	assert(equip_button != null, "RuneSocketUI requires EquipButton")
	assert(unequip_button != null, "RuneSocketUI requires UnequipButton")

	_configure_wrapped_labels()
	slot_buttons = [slot_button_1, slot_button_2, slot_button_3, slot_button_4, slot_button_5]
	for slot_index_ in range(slot_buttons.size()):
		slot_buttons[slot_index_].pressed.connect(_on_slot_button_pressed.bind(slot_index_))

	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	refresh_ui()
#endregion

#region Public
func setup(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> void:
	current_weapon = weapon_
	current_inventory = inventory_

	if current_weapon == null or current_weapon.rune_slots.is_empty():
		selected_slot_index = -1
		selected_rune = null
	elif selected_slot_index < 0 or selected_slot_index >= current_weapon.rune_slots.size():
		selected_slot_index = _get_first_unlocked_slot_index()
		selected_rune = null

	refresh_ui()


func refresh_ui() -> void:
	_update_slot_buttons()
	_update_selected_slot_info()
	_update_rune_list()
	_update_action_buttons()
#endregion

#region Helpers
func _update_slot_buttons() -> void:
	for slot_index_ in range(slot_buttons.size()):
		var button_: Button = slot_buttons[slot_index_]
		var slot_ := _get_slot(slot_index_)
		if slot_ == null:
			button_.disabled = true
			button_.text = "🔒 %d" % (slot_index_ + 1)
			button_.tooltip_text = "需 %d 星開放" % (slot_index_ + 1)
			continue

		button_.disabled = false
		var label_prefix_: String = "> " if slot_index_ == selected_slot_index else ""
		var type_text_: String = _get_slot_type_text(slot_)
		if slot_.is_empty():
			button_.text = "%s%d:%s" % [label_prefix_, slot_index_ + 1, type_text_]
			button_.tooltip_text = "空槽位\n%s" % _get_slot_requirement_text(slot_)
			continue

		button_.text = "%s%d:%s" % [label_prefix_, slot_index_ + 1, slot_.equipped_rune.rune_data.display_name]
		button_.tooltip_text = "%s\n%s" % [type_text_, slot_.equipped_rune.rune_data.description]


func _update_selected_slot_info() -> void:
	var player_ = _get_player()
	var current_gold_: int = player_.get_gold() if player_ != null else 0
	gold_label.text = "持有金幣：%d" % current_gold_

	var slot_ := _get_slot(selected_slot_index)
	if slot_ == null:
		selected_slot_label.text = "請先選擇已解鎖的符文槽。"
		equipped_rune_info.text = "目前沒有可操作的槽位。"
		return

	selected_slot_label.text = "槽位 %d [%s]" % [selected_slot_index + 1, _get_slot_type_text(slot_)]
	if slot_.is_empty():
		equipped_rune_info.text = "空槽位\n需求：%s" % _get_slot_requirement_text(slot_)
		if selected_rune != null:
			equipped_rune_info.text += "\n\n準備鑲嵌：%s\n%s" % [selected_rune.display_name, selected_rune.description]
		return

	var rune_data_: RuneDataResource = slot_.equipped_rune.rune_data
	assert(rune_data_ != null, "RuneSocketUI slot rune data must exist")
	equipped_rune_info.text = "已鑲嵌：%s\n%s\n\n拆卸成本：%d 金幣" % [
		rune_data_.display_name,
		rune_data_.description,
		_get_rune_manager().get_unequip_cost(selected_slot_index)
	]


func _update_rune_list() -> void:
	_clear_rune_list()
	_set_empty_state("")

	var rune_manager_ = _get_rune_manager()
	if rune_manager_ == null or current_inventory == null:
		_set_empty_state("找不到符文背包資料。")
		return

	var rune_entries_: Array[Dictionary] = rune_manager_.get_available_runes_from_inventory(current_inventory)
	if rune_entries_.is_empty():
		_set_empty_state("背包裡沒有符文。")
		return

	var selected_slot_ := _get_slot(selected_slot_index)
	var created_button_count_: int = 0
	for rune_entry_ in rune_entries_:
		var rune_data_ := rune_entry_.get("rune_data", null) as RuneDataResource
		var amount_: int = int(rune_entry_.get("amount", 0))
		if rune_data_ == null or amount_ <= 0:
			continue

		var can_equip_selected_slot_: bool = selected_slot_ != null and selected_slot_.can_equip(rune_data_)
		var button_ := Button.new()
		button_.text = _build_rune_button_text(rune_data_, amount_)
		button_.custom_minimum_size = Vector2(WRAPPED_TEXT_MIN_WIDTH, 68.0)
		button_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button_.tooltip_text = rune_data_.description
		button_.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button_.disabled = false
		if selected_slot_ == null:
			button_.tooltip_text += "\n\n先選擇符文槽，再進行鑲嵌。"
		elif not can_equip_selected_slot_:
			button_.tooltip_text += "\n\n目前選中的槽位無法鑲嵌這顆符文。"
			button_.modulate = Color(0.78, 0.78, 0.78, 0.92)
		if selected_rune == rune_data_:
			button_.text = "> " + button_.text
		button_.pressed.connect(_on_rune_button_pressed.bind(rune_data_))
		rune_list.add_child(button_)
		created_button_count_ += 1

	if created_button_count_ == 0:
		_set_empty_state("背包內沒有可用的符文條目。")


func _update_action_buttons() -> void:
	var rune_manager_ = _get_rune_manager()
	if rune_manager_ == null:
		equip_button.disabled = true
		unequip_button.disabled = true
		status_label.text = "RuneManager 尚未就緒。"
		return

	var equip_reason_: String = rune_manager_.get_equip_failure_reason(current_weapon, current_inventory, selected_slot_index, selected_rune)
	var unequip_reason_: String = rune_manager_.get_unequip_failure_reason(current_weapon, current_inventory, selected_slot_index)
	equip_button.disabled = not equip_reason_.is_empty()
	unequip_button.disabled = not unequip_reason_.is_empty()

	if selected_slot_index < 0:
		status_label.text = "選擇槽位後即可開始鑲嵌。"
	elif not equip_reason_.is_empty() and selected_rune != null:
		status_label.text = equip_reason_
	elif _get_slot(selected_slot_index) != null and not _get_slot(selected_slot_index).is_empty():
		var player_ = _get_player()
		var gold_reason_: String = rune_manager_.get_unequip_failure_reason_with_gold(current_weapon, current_inventory, selected_slot_index, player_)
		if not gold_reason_.is_empty():
			status_label.text = gold_reason_
		else:
			var gold_cost_: int = rune_manager_.get_unequip_cost(selected_slot_index)
			var current_gold_: int = player_.get_gold() if player_ != null else 0
			status_label.text = "拆卸將消耗 %d 金幣，目前持有 %d。" % [gold_cost_, current_gold_]
	elif not unequip_reason_.is_empty():
		status_label.text = unequip_reason_
	else:
		status_label.text = "選擇符文後即可鑲嵌。"


func _on_slot_button_pressed(slot_index_: int) -> void:
	selected_slot_index = slot_index_
	selected_rune = null
	refresh_ui()


func _on_rune_button_pressed(rune_data_: RuneDataResource) -> void:
	selected_rune = rune_data_
	refresh_ui()


func _on_equip_pressed() -> void:
	var rune_manager_ = _get_rune_manager()
	assert(rune_manager_ != null, "RuneSocketUI requires RuneManager")

	var failure_reason_: String = rune_manager_.get_equip_failure_reason(current_weapon, current_inventory, selected_slot_index, selected_rune)
	if not failure_reason_.is_empty():
		status_label.text = failure_reason_
		refresh_ui()
		return

	var equip_ok_: bool = rune_manager_.equip_rune(current_weapon, current_inventory, selected_slot_index, selected_rune)
	assert(equip_ok_, "RuneSocketUI validated equip before executing it")
	status_label.text = "鑲嵌成功。"
	selected_rune = null
	refresh_ui()


func _on_unequip_pressed() -> void:
	var rune_manager_ = _get_rune_manager()
	assert(rune_manager_ != null, "RuneSocketUI requires RuneManager")
	var player_ = _get_player()

	var failure_reason_: String = rune_manager_.get_unequip_failure_reason_with_gold(current_weapon, current_inventory, selected_slot_index, player_)
	if not failure_reason_.is_empty():
		status_label.text = failure_reason_
		refresh_ui()
		return

	var result_: Dictionary = rune_manager_.unequip_rune_with_cost(current_weapon, current_inventory, selected_slot_index, player_)
	assert(bool(result_.get("success", false)), "RuneSocketUI validated unequip before executing it")
	status_label.text = "拆卸成功，消耗 %d 金幣。" % int(result_.get("gold_cost", 0))
	refresh_ui()


func _build_rune_button_text(rune_data_: RuneDataResource, amount_: int) -> String:
	var tier_text_: String = "核心" if rune_data_.tier == RuneDataResource.RuneTier.CORE else "普通"
	return "%s x%d\n[%s] %s" % [
		rune_data_.display_name,
		amount_,
		tier_text_,
		rune_data_.description
	]


func _clear_rune_list() -> void:
	for child_ in rune_list.get_children():
		rune_list.remove_child(child_)
		child_.queue_free()


func _configure_wrapped_labels() -> void:
	var wrapped_labels_: Array[Label] = [equipped_rune_info, empty_state_label, status_label]
	for label_ in wrapped_labels_:
		label_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_.custom_minimum_size = Vector2(maxf(label_.custom_minimum_size.x, WRAPPED_TEXT_MIN_WIDTH), label_.custom_minimum_size.y)


func _set_empty_state(text_: String) -> void:
	empty_state_label.text = text_
	empty_state_label.visible = not text_.is_empty()


func _get_slot(slot_index_: int) -> RuneSlotResource:
	if current_weapon == null:
		return null
	if slot_index_ < 0 or slot_index_ >= current_weapon.rune_slots.size():
		return null
	return current_weapon.rune_slots[slot_index_]


func _get_first_unlocked_slot_index() -> int:
	if current_weapon == null:
		return -1
	if current_weapon.rune_slots.is_empty():
		return -1
	return 0


func _get_slot_type_text(slot_: RuneSlotResource) -> String:
	match slot_.slot_type:
		RuneSlotResource.SlotType.FREE:
			return "自由槽"
		RuneSlotResource.SlotType.TYPED:
			return "類型槽"
		RuneSlotResource.SlotType.CORE:
			return "核心槽"
		_:
			return "未知槽位"


func _get_slot_requirement_text(slot_: RuneSlotResource) -> String:
	match slot_.slot_type:
		RuneSlotResource.SlotType.FREE:
			return "任意普通符文"
		RuneSlotResource.SlotType.TYPED:
			return "需 %s 類型符文" % _get_rune_tag_text(slot_.required_tag)
		RuneSlotResource.SlotType.CORE:
			return "僅限核心級符文"
		_:
			return "未知限制"


func _get_rune_tag_text(tag_: RuneDataResource.RuneTag) -> String:
	match tag_:
		RuneDataResource.RuneTag.ATTACK:
			return "攻擊"
		RuneDataResource.RuneTag.DEFENSE:
			return "防禦"
		RuneDataResource.RuneTag.ELEMENT:
			return "元素"
		RuneDataResource.RuneTag.UTILITY:
			return "功能"
		_:
			return "通用"


func _get_rune_manager() -> Node:
	var tree_: SceneTree = get_tree()
	assert(tree_ != null and tree_.root != null, "RuneSocketUI requires SceneTree root")
	return tree_.root.get_node_or_null("RuneManager")


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")
#endregion
