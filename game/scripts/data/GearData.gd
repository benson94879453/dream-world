class_name GearData
extends ItemData

enum GearType {
	HELMET,
	CHESTPLATE,
	LEGGINGS,
	BOOTS
}

@export var gear_id: StringName = &""
@export var gear_type: GearType = GearType.HELMET
@export var defense: float = 0.0
@export var max_durability: int = -1
@export var stat_modifiers: Dictionary = {}

func _init() -> void:
	item_type = ItemType.EQUIPMENT
	max_stack = 1


#region Public
func get_equipment_slot_id() -> StringName:
	match gear_type:
		GearType.HELMET:
			return &"helmet"
		GearType.CHESTPLATE:
			return &"chestplate"
		GearType.LEGGINGS:
			return &"leggings"
		GearType.BOOTS:
			return &"boots"
		_:
			return &""
#endregion
