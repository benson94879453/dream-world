class_name RuneSlot
extends RefCounted

const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const RuneInstanceResource = preload("res://game/scripts/data/RuneInstance.gd")

enum SlotType {
	FREE,
	TYPED,
	CORE
}

var slot_index: int = 0
var slot_type: SlotType = SlotType.FREE
var required_tag: RuneDataResource.RuneTag = RuneDataResource.RuneTag.NONE
var equipped_rune: RuneInstanceResource = null

# Locked slots are represented by a missing slot object; existing slots should always allow interaction.
func is_empty() -> bool:
	return equipped_rune == null


func can_equip(rune_: RuneDataResource) -> bool:
	if rune_ == null or not is_empty():
		return false
	return rune_.can_equip_in_slot(slot_type, required_tag)


func equip(rune_instance_: RuneInstanceResource) -> bool:
	if rune_instance_ == null:
		return false
	if not can_equip(rune_instance_.rune_data):
		return false

	equipped_rune = rune_instance_
	return true


func unequip() -> RuneInstanceResource:
	var rune_instance_: RuneInstanceResource = equipped_rune
	equipped_rune = null
	return rune_instance_
