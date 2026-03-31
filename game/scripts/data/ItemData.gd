class_name ItemData
extends Resource

enum ItemType {
	MATERIAL,
	CONSUMABLE,
	WEAPON,
	EQUIPMENT,
	KEY_ITEM
}

enum ConsumableEffect {
	NONE,
	HEAL
}

@export var item_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var item_type: ItemType = ItemType.MATERIAL
@export var max_stack: int = 1
@export var is_consumable: bool = false
@export var consumable_effect: ConsumableEffect = ConsumableEffect.NONE
@export_range(0.0, 9999.0, 0.1, "or_greater") var consumable_heal_amount: float = 0.0
@export var tags: Array[StringName] = []

#region Public
func get_stack_key(_instance_data_: Dictionary = {}) -> StringName:
	return item_id


func is_consumable_item() -> bool:
	return item_type == ItemType.CONSUMABLE or is_consumable


func has_supported_consumable_effect() -> bool:
	if not is_consumable_item():
		return false

	match consumable_effect:
		ConsumableEffect.HEAL:
			return consumable_heal_amount > 0.0
		_:
			return false
#endregion
