class_name RuneData
extends ItemData

enum RuneTier {
	COMMON,
	CORE
}

enum RuneTag {
	NONE,
	ATTACK,
	DEFENSE,
	ELEMENT,
	UTILITY
}

@export var rune_id: StringName = &""
@export var tier: RuneTier = RuneTier.COMMON
@export var rune_tags: Array[RuneTag] = []
@export var stat_modifiers: Dictionary = {}
@export var special_effects: Array[StringName] = []

# RuneData extends ItemData so it can live inside the existing inventory stack system.
func can_equip_in_slot(slot_type_: int, required_tag_: RuneTag) -> bool:
	match slot_type_:
		0:
			return tier == RuneTier.COMMON
		1:
			return tier == RuneTier.COMMON and rune_tags.has(required_tag_)
		2:
			return tier == RuneTier.CORE
		_:
			return false


func get_runtime_rune_id() -> StringName:
	if not rune_id.is_empty():
		return rune_id
	return item_id
