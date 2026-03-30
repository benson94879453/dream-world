class_name ItemData
extends Resource

enum ItemType {
	MATERIAL,
	CONSUMABLE,
	WEAPON,
	EQUIPMENT,
	KEY_ITEM
}

@export var item_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var item_type: ItemType = ItemType.MATERIAL
@export var max_stack: int = 1
@export var is_consumable: bool = false
@export var tags: Array[StringName] = []

#region Public
func get_stack_key(_instance_data_: Dictionary = {}) -> StringName:
	return item_id
#endregion
