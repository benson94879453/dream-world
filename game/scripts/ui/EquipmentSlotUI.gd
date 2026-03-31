class_name EquipmentSlotUI
extends PanelContainer

const EquipmentNode = preload("res://game/scripts/inventory/Equipment.gd")
const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")
const UIColorsResource = preload("res://game/scripts/ui/UIColors.gd")

enum SlotType {
	WEAPON_MAIN,
	HELMET,
	CHESTPLATE,
	LEGGINGS,
	BOOTS
}

signal slot_clicked(slot_type: SlotType)
signal slot_shift_clicked(slot_type: SlotType)

@export var slot_type: SlotType = SlotType.WEAPON_MAIN

var equipment: EquipmentNode = null
var hovered: bool = false

@onready var icon_rect: TextureRect = $Margin/Content/Icon
@onready var slot_label: Label = $Margin/Content/SlotLabel
@onready var fallback_label: Label = $Margin/Content/FallbackLabel

#region Core Lifecycle
func _ready() -> void:
	assert(icon_rect != null, "EquipmentSlotUI requires Icon")
	assert(slot_label != null, "EquipmentSlotUI requires SlotLabel")
	assert(fallback_label != null, "EquipmentSlotUI requires FallbackLabel")

	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_child_mouse_filters(self)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	slot_label.text = _get_slot_label_text()
	_apply_style()
	_update_visual()
#endregion

#region Public
func configure(equipment_: EquipmentNode) -> void:
	if equipment == equipment_:
		_update_visual()
		return

	if equipment != null:
		if equipment.weapon_changed.is_connected(_on_weapon_changed):
			equipment.weapon_changed.disconnect(_on_weapon_changed)
		if equipment.gear_changed.is_connected(_on_gear_changed):
			equipment.gear_changed.disconnect(_on_gear_changed)

	equipment = equipment_
	if equipment != null:
		if not equipment.weapon_changed.is_connected(_on_weapon_changed):
			equipment.weapon_changed.connect(_on_weapon_changed)
		if not equipment.gear_changed.is_connected(_on_gear_changed):
			equipment.gear_changed.connect(_on_gear_changed)

	_update_visual()


func clear() -> void:
	icon_rect.texture = null
	icon_rect.visible = false
	fallback_label.visible = true
	fallback_label.text = _get_slot_fallback_text()
	slot_label.text = _get_slot_label_text()
#endregion

#region Helpers
func _gui_input(event_: InputEvent) -> void:
	var mouse_event_: InputEventMouseButton = event_ as InputEventMouseButton
	if mouse_event_ == null or not mouse_event_.pressed:
		return
	if mouse_event_.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse_event_.shift_pressed:
		slot_shift_clicked.emit(slot_type)
		return

	slot_clicked.emit(slot_type)


func _update_visual() -> void:
	slot_label.text = _get_slot_label_text()
	if equipment == null:
		clear()
		return

	var equipped_instance_ = equipment.get_equipped_in_slot(_get_equipment_slot_enum())
	match slot_type:
		SlotType.WEAPON_MAIN:
			var weapon_: WeaponInstanceResource = equipped_instance_ as WeaponInstanceResource
			if weapon_ != null and weapon_.weapon_data != null and weapon_.weapon_data.weapon_sprite_texture != null:
				icon_rect.texture = weapon_.weapon_data.weapon_sprite_texture
				icon_rect.visible = true
				fallback_label.visible = false
				return
		_:
			var gear_: GearInstanceResource = equipped_instance_ as GearInstanceResource
			if gear_ != null and gear_.gear_data != null and gear_.gear_data.icon != null:
				icon_rect.texture = gear_.gear_data.icon
				icon_rect.visible = true
				fallback_label.visible = false
				return

	clear()


func _get_equipment_slot_enum() -> EquipmentNode.EquipmentSlot:
	match slot_type:
		SlotType.WEAPON_MAIN:
			return EquipmentNode.EquipmentSlot.WEAPON_MAIN
		SlotType.HELMET:
			return EquipmentNode.EquipmentSlot.HELMET
		SlotType.CHESTPLATE:
			return EquipmentNode.EquipmentSlot.CHESTPLATE
		SlotType.LEGGINGS:
			return EquipmentNode.EquipmentSlot.LEGGINGS
		SlotType.BOOTS:
			return EquipmentNode.EquipmentSlot.BOOTS
		_:
			return EquipmentNode.EquipmentSlot.WEAPON_MAIN


func _get_slot_label_text() -> String:
	match slot_type:
		SlotType.WEAPON_MAIN:
			return "武器"
		SlotType.HELMET:
			return "頭盔"
		SlotType.CHESTPLATE:
			return "胸甲"
		SlotType.LEGGINGS:
			return "護腿"
		SlotType.BOOTS:
			return "靴子"
		_:
			return "裝備"


func _get_slot_fallback_text() -> String:
	match slot_type:
		SlotType.WEAPON_MAIN:
			return "武"
		SlotType.HELMET:
			return "盔"
		SlotType.CHESTPLATE:
			return "甲"
		SlotType.LEGGINGS:
			return "褲"
		SlotType.BOOTS:
			return "靴"
		_:
			return "裝"


func _apply_style() -> void:
	var stylebox_: StyleBoxFlat
	if hovered:
		stylebox_ = UIColorsResource.build_panel_style(UIColorsResource.SLOT_HOVER_BG, UIColorsResource.SLOT_ACTIVE_BORDER, 2, 6)
	else:
		stylebox_ = UIColorsResource.build_borderless_style(UIColorsResource.SLOT_BG, 6)
	add_theme_stylebox_override("panel", stylebox_)


func _set_child_mouse_filters(node_: Node) -> void:
	for child_node_ in node_.get_children():
		var child_control_: Control = child_node_ as Control
		if child_control_ != null:
			child_control_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_child_mouse_filters(child_node_)


func _on_weapon_changed(_old_weapon_: WeaponInstanceResource, _new_weapon_: WeaponInstanceResource) -> void:
	_update_visual()


func _on_gear_changed(_slot_: int, _old_gear_: GearInstanceResource, _new_gear_: GearInstanceResource) -> void:
	_update_visual()


func _on_mouse_entered() -> void:
	hovered = true
	_apply_style()


func _on_mouse_exited() -> void:
	hovered = false
	_apply_style()
#endregion
