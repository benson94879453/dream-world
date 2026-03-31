class_name ItemSlotUI
extends PanelContainer

const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const InventorySlotResource = preload("res://game/scripts/inventory/InventorySlot.gd")
const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const HotbarManagerNode = preload("res://game/scripts/core/HotbarManager.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")
const UIColorsResource = preload("res://game/scripts/ui/UIColors.gd")

signal hover_started(slot_ui: ItemSlotUI)
signal hover_ended(slot_ui: ItemSlotUI)
signal slot_clicked(slot_ui: ItemSlotUI)
signal slot_shift_clicked(slot_ui: ItemSlotUI)

@export var slot_index: int = -1
@export var is_hotbar_slot: bool = false
@export var hotbar_index: int = -1

var inventory: InventoryResource = null
var hotbar_manager = null
var current_item: ItemDataResource = null
var current_weapon: WeaponInstanceResource = null
var current_gear: GearInstanceResource = null
var current_amount: int = 0
var bound_inventory_index: int = -1
var filter_hidden: bool = false
var hovered: bool = false

@onready var icon_rect: TextureRect = $Margin/Content/Icon
@onready var fallback_label: Label = $Margin/Content/FallbackLabel
@onready var amount_label: Label = $Margin/Content/AmountLabel
@onready var shortcut_label: Label = $Margin/Content/ShortcutLabel
@onready var bind_label: Label = $Margin/Content/BindLabel

#region Core Lifecycle
func _ready() -> void:
	assert(icon_rect != null, "ItemSlotUI requires Icon")
	assert(fallback_label != null, "ItemSlotUI requires FallbackLabel")
	assert(amount_label != null, "ItemSlotUI requires AmountLabel")
	assert(shortcut_label != null, "ItemSlotUI requires ShortcutLabel")
	assert(bind_label != null, "ItemSlotUI requires BindLabel")

	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_child_mouse_filters(self)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_visual_state()
#endregion

#region Public
func configure_inventory_slot(inventory_: InventoryResource, slot_index_: int) -> void:
	inventory = inventory_
	slot_index = slot_index_
	is_hotbar_slot = false
	hotbar_index = -1
	shortcut_label.visible = false
	bind_label.visible = false


func configure_hotbar_slot(inventory_: InventoryResource, hotbar_manager_, hotbar_index_: int) -> void:
	inventory = inventory_
	hotbar_manager = hotbar_manager_
	is_hotbar_slot = true
	hotbar_index = hotbar_index_
	slot_index = -1
	shortcut_label.visible = true
	shortcut_label.text = str(hotbar_index_ + 1)


func setup_inventory_slot(slot_data_: InventorySlotResource, content_visible_: bool = true) -> void:
	bound_inventory_index = slot_index
	filter_hidden = not content_visible_
	_assign_slot_content(slot_data_)
	shortcut_label.visible = false
	bind_label.visible = false
	_apply_visual_state()


func setup_hotbar_slot(slot_data_: InventorySlotResource, inventory_index_: int) -> void:
	bound_inventory_index = inventory_index_
	filter_hidden = false
	shortcut_label.visible = true
	shortcut_label.text = str(hotbar_index + 1)
	bind_label.visible = inventory_index_ >= 0
	bind_label.text = "S%d" % (inventory_index_ + 1) if inventory_index_ >= 0 else ""
	_assign_slot_content(slot_data_)
	_apply_visual_state()


func clear() -> void:
	current_item = null
	current_weapon = null
	current_gear = null
	current_amount = 0
	bound_inventory_index = -1
	filter_hidden = false
	icon_rect.texture = null
	icon_rect.visible = false
	fallback_label.text = ""
	fallback_label.visible = false
	amount_label.text = ""
	amount_label.visible = false
	bind_label.text = ""
	bind_label.visible = false
	_apply_visual_state()


func has_display_content() -> bool:
	if filter_hidden:
		return false
	return current_item != null or current_weapon != null or current_gear != null


func build_tooltip_payload() -> Dictionary:
	if not has_display_content():
		return {}

	if current_weapon != null:
		var weapon_name_: String = current_weapon.weapon_data.display_name if current_weapon.weapon_data != null else String(current_weapon.weapon_id)
		return {
			"kind": &"weapon",
			"name": weapon_name_,
			"type": "武器",
			"description": _build_weapon_description(),
			"stats": _build_weapon_stats(),
			"slot_text": _get_slot_label()
		}

	if current_gear != null:
		var gear_name_: String = current_gear.gear_data.display_name if current_gear.gear_data != null else String(current_gear.gear_id)
		return {
			"kind": &"gear",
			"name": gear_name_,
			"type": "裝備",
			"description": _build_gear_description(),
			"stats": _build_gear_stats(),
			"slot_text": _get_slot_label()
		}

	if current_item == null:
		return {}

	return {
		"kind": &"item",
		"name": current_item.display_name,
		"type": _get_item_type_text(current_item),
		"description": current_item.description,
		"stats": _build_item_stats(),
		"slot_text": _get_slot_label()
	}
#endregion

#region Drag And Drop
func _gui_input(event_: InputEvent) -> void:
	var mouse_event_: InputEventMouseButton = event_ as InputEventMouseButton
	if mouse_event_ == null or not mouse_event_.pressed:
		return
	if mouse_event_.button_index != MOUSE_BUTTON_LEFT or not has_display_content():
		return

	if mouse_event_.shift_pressed:
		slot_shift_clicked.emit(self)
		return

	slot_clicked.emit(self)


func _get_drag_data(_at_position_: Vector2) -> Variant:
	if not has_display_content():
		return null

	var preview_: Control = _build_drag_preview()
	set_drag_preview(preview_)

	if is_hotbar_slot:
		return {
			"source_type": &"hotbar",
			"hotbar_index": hotbar_index
		}

	return {
		"source_type": &"inventory",
		"slot_index": slot_index
	}


func _can_drop_data(_at_position_: Vector2, data_: Variant) -> bool:
	if typeof(data_) != TYPE_DICTIONARY:
		return false

	var source_type_: StringName = StringName(data_.get("source_type", ""))
	if is_hotbar_slot:
		if hotbar_manager == null:
			return false
		if source_type_ == &"inventory":
			if inventory == null:
				return false
			return hotbar_manager.can_bind_inventory_slot(inventory, int(data_.get("slot_index", -1)))
		if source_type_ == &"hotbar":
			return int(data_.get("hotbar_index", -1)) >= 0
		return false

	if inventory == null:
		return false
	if source_type_ != &"inventory":
		return false

	return int(data_.get("slot_index", -1)) >= 0


func _drop_data(_at_position_: Vector2, data_: Variant) -> void:
	if typeof(data_) != TYPE_DICTIONARY:
		return

	var source_type_: StringName = StringName(data_.get("source_type", ""))
	if is_hotbar_slot:
		if hotbar_manager == null:
			return
		if source_type_ == &"inventory":
			hotbar_manager.bind_slot(hotbar_index, int(data_.get("slot_index", -1)), inventory)
			return
		if source_type_ == &"hotbar":
			hotbar_manager.swap_slots(int(data_.get("hotbar_index", -1)), hotbar_index)
			return
		return

	if inventory == null or source_type_ != &"inventory":
		return

	inventory.swap_slots(int(data_.get("slot_index", -1)), slot_index)
#endregion

#region Helpers
func _assign_slot_content(slot_data_: InventorySlotResource) -> void:
	current_item = null
	current_weapon = null
	current_gear = null
	current_amount = 0
	icon_rect.texture = null
	icon_rect.visible = false
	fallback_label.text = ""
	fallback_label.visible = false
	amount_label.text = ""
	amount_label.visible = false

	if slot_data_ == null or slot_data_.is_empty():
		return

	current_weapon = slot_data_.weapon_instance
	if current_weapon != null:
		current_amount = 1
		icon_rect.texture = current_weapon.weapon_data.weapon_sprite_texture if current_weapon.weapon_data != null else null
		_set_fallback_text(_get_weapon_short_label(current_weapon))
		return

	current_gear = slot_data_.gear_instance
	if current_gear != null:
		current_amount = 1
		icon_rect.texture = current_gear.gear_data.icon if current_gear.gear_data != null else null
		_set_fallback_text(_get_gear_short_label(current_gear))
		return

	current_item = slot_data_.item_data
	current_amount = slot_data_.amount
	if current_item == null:
		return

	icon_rect.texture = current_item.icon
	_set_fallback_text(_get_item_short_label(current_item))
	if current_amount > 1:
		amount_label.text = str(current_amount)
		amount_label.visible = true


func _set_fallback_text(text_: String) -> void:
	if icon_rect.texture != null:
		icon_rect.visible = true
		fallback_label.visible = false
		return

	fallback_label.text = text_
	fallback_label.visible = not text_.is_empty()


func _apply_visual_state() -> void:
	var stylebox_: StyleBoxFlat
	if hovered:
		stylebox_ = UIColorsResource.build_panel_style(UIColorsResource.SLOT_HOVER_BG, UIColorsResource.SLOT_ACTIVE_BORDER, 2, 6)
	elif is_hotbar_slot:
		stylebox_ = UIColorsResource.build_panel_style(Color(0.24, 0.18, 0.12, 0.98), Color(0.72, 0.56, 0.31, 1.0), 1, 6)
	elif has_display_content():
		stylebox_ = UIColorsResource.build_borderless_style(UIColorsResource.SLOT_BG, 6) # Use borderless for occupied slots too, only hover shows border
	else:
		stylebox_ = UIColorsResource.build_borderless_style(UIColorsResource.SLOT_BG, 6)

	if filter_hidden:
		stylebox_.bg_color = Color(0.12, 0.12, 0.12, 0.78)

	add_theme_stylebox_override("panel", stylebox_)
	modulate = Color(1.0, 1.0, 1.0, 0.75) if filter_hidden else Color.WHITE


func _build_drag_preview() -> Control:
	var preview_root_: PanelContainer = PanelContainer.new()
	preview_root_.custom_minimum_size = Vector2(36.0, 36.0)
	preview_root_.modulate = Color(1.0, 1.0, 1.0, 0.7)

	var preview_style_: StyleBoxFlat = StyleBoxFlat.new()
	preview_style_.bg_color = Color(0.18, 0.18, 0.18, 0.95)
	preview_style_.border_color = Color(0.95, 0.85, 0.42, 1.0)
	preview_style_.border_width_left = 2
	preview_style_.border_width_top = 2
	preview_style_.border_width_right = 2
	preview_style_.border_width_bottom = 2
	preview_root_.add_theme_stylebox_override("panel", preview_style_)

	var center_: CenterContainer = CenterContainer.new()
	center_.custom_minimum_size = Vector2(36.0, 36.0)
	preview_root_.add_child(center_)

	if current_weapon != null and current_weapon.weapon_data != null and current_weapon.weapon_data.weapon_sprite_texture != null:
		var icon_preview_: TextureRect = TextureRect.new()
		icon_preview_.texture = current_weapon.weapon_data.weapon_sprite_texture
		icon_preview_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_preview_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_preview_.custom_minimum_size = Vector2(32.0, 32.0)
		center_.add_child(icon_preview_)
		return preview_root_

	if current_gear != null and current_gear.gear_data != null and current_gear.gear_data.icon != null:
		var gear_preview_: TextureRect = TextureRect.new()
		gear_preview_.texture = current_gear.gear_data.icon
		gear_preview_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gear_preview_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gear_preview_.custom_minimum_size = Vector2(32.0, 32.0)
		center_.add_child(gear_preview_)
		return preview_root_

	if current_item != null and current_item.icon != null:
		var item_preview_: TextureRect = TextureRect.new()
		item_preview_.texture = current_item.icon
		item_preview_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_preview_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_preview_.custom_minimum_size = Vector2(32.0, 32.0)
		center_.add_child(item_preview_)
		return preview_root_

	var text_preview_: Label = Label.new()
	text_preview_.text = fallback_label.text
	text_preview_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_preview_.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_.add_child(text_preview_)
	return preview_root_


func _build_weapon_description() -> String:
	if current_weapon == null or current_weapon.weapon_data == null:
		return ""
	return "類型：%s\n%s" % [
		String(current_weapon.weapon_data.weapon_type).capitalize(),
		"已強化 %d 次" % current_weapon.enhance_level
	]


func _build_weapon_stats() -> String:
	if current_weapon == null or current_weapon.weapon_data == null:
		return ""

	var affix_text_: String = "無"
	var affix_names_: Array[String] = []
	for affix_ in current_weapon.affixes:
		if affix_ == null or affix_.affix_name.is_empty():
			continue
		affix_names_.append(affix_.affix_name)
	if not affix_names_.is_empty():
		affix_text_ = "、".join(affix_names_)

	var rune_text_parts_: Array[String] = []
	for slot_ in current_weapon.rune_slots:
		if slot_ == null or slot_.equipped_rune == null or slot_.equipped_rune.rune_data == null:
			rune_text_parts_.append("○")
			continue
		rune_text_parts_.append(slot_.equipped_rune.rune_data.display_name)

	var rune_text_: String = "○"
	if not rune_text_parts_.is_empty():
		rune_text_ = " / ".join(rune_text_parts_)

	return "%s\n攻擊力: %.1f\n攻速: %.2f\n詞綴: %s\n符文槽: %s" % [
		_get_star_text(current_weapon.star_level),
		current_weapon.get_base_attack(),
		current_weapon.weapon_data.attack_speed,
		affix_text_,
		rune_text_
	]


func _build_gear_description() -> String:
	if current_gear == null or current_gear.gear_data == null:
		return ""

	return "部位：%s\n耐久：%s" % [
		_get_gear_slot_text(current_gear),
		"無" if current_gear.current_durability < 0 else str(current_gear.current_durability)
	]


func _build_gear_stats() -> String:
	if current_gear == null:
		return ""

	var details_: Array[String] = ["防禦: %.1f" % current_gear.get_total_defense()]
	if current_gear.gear_data != null:
		for modifier_key_ in current_gear.gear_data.stat_modifiers:
			var modifier_name_: String = _format_stat_key(StringName(String(modifier_key_)))
			var value_: float = float(current_gear.gear_data.stat_modifiers.get(modifier_key_, 0.0))
			details_.append("%s: %+.1f" % [modifier_name_, value_])

	return "\n".join(details_)


func _build_item_stats() -> String:
	if current_item == null:
		return ""

	var details_: Array[String] = []
	if current_amount > 1:
		details_.append("堆疊數量: %d" % current_amount)
	details_.append("最大堆疊: %d" % maxi(current_item.max_stack, 1))

	var rune_data_: RuneDataResource = current_item as RuneDataResource
	if rune_data_ != null:
		var rune_tags_: Array[String] = []
		for tag_ in rune_data_.rune_tags:
			rune_tags_.append(_get_rune_tag_text(tag_))
		if not rune_tags_.is_empty():
			details_.append("標籤: [%s]" % "] [".join(rune_tags_))

	if not current_item.tags.is_empty():
		var item_tags_: Array[String] = []
		for tag_name_ in current_item.tags:
			item_tags_.append(String(tag_name_))
		details_.append("Tags: %s" % ", ".join(item_tags_))

	return "\n".join(details_)


func _get_slot_label() -> String:
	if is_hotbar_slot:
		return "快捷欄 %d" % (hotbar_index + 1)
	return "背包格 %d" % (slot_index + 1)


func _get_item_type_text(item_data_: ItemDataResource) -> String:
	if item_data_ == null:
		return "未知"

	if item_data_ is RuneDataResource:
		return "符文石"

	match item_data_.item_type:
		ItemData.ItemType.MATERIAL:
			return "素材"
		ItemData.ItemType.CONSUMABLE:
			return "消耗品"
		ItemData.ItemType.WEAPON:
			return "武器"
		ItemData.ItemType.EQUIPMENT:
			return "裝備"
		ItemData.ItemType.KEY_ITEM:
			return "鑰匙"
		_:
			return "未知"


func _get_item_short_label(item_data_: ItemDataResource) -> String:
	if item_data_ == null or item_data_.display_name.is_empty():
		return ""
	if item_data_ is RuneDataResource:
		return "符"
	return item_data_.display_name.left(1)


func _get_gear_short_label(gear_: GearInstanceResource) -> String:
	if gear_ == null or gear_.gear_data == null:
		return "裝"

	match gear_.gear_data.get_equipment_slot_id():
		&"helmet":
			return "盔"
		&"chestplate":
			return "甲"
		&"leggings":
			return "褲"
		&"boots":
			return "靴"
		_:
			return gear_.gear_data.display_name.left(1)


func _get_weapon_short_label(weapon_: WeaponInstanceResource) -> String:
	if weapon_ == null or weapon_.weapon_data == null:
		return "武"
	if weapon_.weapon_data.weapon_type == &"staff":
		return "杖"
	if weapon_.weapon_data.weapon_type == &"sword":
		return "劍"
	return weapon_.weapon_data.display_name.left(1)


func _get_gear_slot_text(gear_: GearInstanceResource) -> String:
	if gear_ == null or gear_.gear_data == null:
		return "未知"

	match gear_.gear_data.get_equipment_slot_id():
		&"helmet":
			return "頭盔"
		&"chestplate":
			return "胸甲"
		&"leggings":
			return "護腿"
		&"boots":
			return "靴子"
		_:
			return "裝備"


func _format_stat_key(stat_key_: StringName) -> String:
	match stat_key_:
		&"max_hp_bonus":
			return "最大生命"
		&"move_speed_bonus_pct":
			return "移動速度%"
		_:
			return String(stat_key_)


func _get_rune_tag_text(tag_: int) -> String:
	match tag_:
		RuneDataResource.RuneTag.ATTACK:
			return "攻擊"
		RuneDataResource.RuneTag.DEFENSE:
			return "防禦"
		RuneDataResource.RuneTag.ELEMENT:
			return "元素"
		RuneDataResource.RuneTag.UTILITY:
			return "通用"
		_:
			return "無"


func _get_star_text(star_level_: int) -> String:
	var clamped_star_level_: int = clampi(star_level_, 0, 5)
	return "★".repeat(clamped_star_level_) + "☆".repeat(5 - clamped_star_level_)


func _set_child_mouse_filters(node_: Node) -> void:
	for child_node_ in node_.get_children():
		var child_control_: Control = child_node_ as Control
		if child_control_ != null:
			child_control_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_child_mouse_filters(child_node_)


func _on_mouse_entered() -> void:
	hovered = true
	_apply_visual_state()
	hover_started.emit(self)


func _on_mouse_exited() -> void:
	hovered = false
	_apply_visual_state()
	hover_ended.emit(self)
#endregion
