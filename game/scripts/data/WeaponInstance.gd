class_name WeaponInstance
extends RefCounted

const AffixInstanceResource = preload("res://game/scripts/data/AffixInstance.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const RuneInstanceResource = preload("res://game/scripts/data/RuneInstance.gd")
const RuneSlotResource = preload("res://game/scripts/data/RuneSlot.gd")

var instance_uid: String = ""
var weapon_id: StringName = &""
var enhance_level: int = 0
var _star_level: int = 0
var temporary_enchants: Array[StringName] = []
var socketed_gems: Array[StringName] = []
var affixes: Array[AffixInstanceResource] = []
var rune_slots: Array[RuneSlotResource] = []
var weapon_data: WeaponData = null

var star_level: int:
	get:
		return _star_level
	set(value_):
		_star_level = clampi(value_, 0, 5)
		_rebuild_rune_slots()

func _init() -> void:
	_rebuild_rune_slots()

#region Public
static func create_from_data(weapon_data_: WeaponData) -> WeaponInstance:
	assert(weapon_data_ != null, "WeaponInstance requires WeaponData")

	var weapon_instance_: WeaponInstance = WeaponInstance.new()
	weapon_instance_.instance_uid = _generate_instance_uid(weapon_data_)
	weapon_instance_.weapon_id = weapon_data_.weapon_id
	weapon_instance_.weapon_data = weapon_data_

	return weapon_instance_


static func create_from_save_dict(weapon_data_: WeaponData, data_: Dictionary) -> WeaponInstance:
	var weapon_instance_ := create_from_data(weapon_data_)
	weapon_instance_.instance_uid = String(data_.get("instance_uid", weapon_instance_.instance_uid))
	weapon_instance_.weapon_id = StringName(data_.get("weapon_id", weapon_data_.weapon_id))
	weapon_instance_.enhance_level = int(data_.get("enhance_level", 0))
	weapon_instance_.star_level = int(data_.get("star_level", 0))

	var temporary_enchants_ = data_.get("temporary_enchants", [])
	weapon_instance_.temporary_enchants.clear()
	for enchant_ in temporary_enchants_:
		weapon_instance_.temporary_enchants.append(StringName(enchant_))

	var socketed_gems_ = data_.get("socketed_gems", [])
	weapon_instance_.socketed_gems.clear()
	for gem_ in socketed_gems_:
		weapon_instance_.socketed_gems.append(StringName(gem_))

	var affixes_ = data_.get("affixes", [])
	weapon_instance_.affixes.clear()
	for affix_data_ in affixes_:
		if typeof(affix_data_) != TYPE_DICTIONARY:
			continue
		weapon_instance_.affixes.append(AffixInstanceResource.create_from_save_dict(affix_data_))

	var runes_ = data_.get("runes", [])
	if typeof(runes_) == TYPE_ARRAY:
		for slot_index_ in range(mini(runes_.size(), weapon_instance_.rune_slots.size())):
			var rune_id_: StringName = StringName(String(runes_[slot_index_]))
			if rune_id_.is_empty():
				continue

			var save_manager_ = _get_save_manager()
			assert(save_manager_ != null, "WeaponInstance restore requires SaveManager")
			var rune_data_: RuneDataResource = save_manager_.resolve_rune_data(rune_id_) as RuneDataResource
			if rune_data_ == null:
				push_warning("[WeaponInstance] Missing rune data during load: %s" % String(rune_id_))
				continue

			weapon_instance_.rune_slots[slot_index_].equipped_rune = RuneInstanceResource.create_from_data(rune_data_)

	return weapon_instance_


func to_save_dict() -> Dictionary:
	return {
		"instance_uid": instance_uid,
		"weapon_id": String(weapon_id),
		"enhance_level": enhance_level,
		"star_level": star_level,
		"temporary_enchants": temporary_enchants.map(func(value_: StringName) -> String: return String(value_)),
		"socketed_gems": socketed_gems.map(func(value_: StringName) -> String: return String(value_)),
		"affixes": affixes.map(func(value_: AffixInstanceResource) -> Dictionary: return value_.to_save_dict()),
		"runes": get_equipped_rune_ids().map(func(value_: StringName) -> String: return String(value_))
	}


func get_base_attack() -> float:
	assert(weapon_data != null, "WeaponInstance requires WeaponData")
	return (weapon_data.base_atk + enhance_level) * (1.0 + get_total_attack_bonus())


func get_attack_cooldown() -> float:
	assert(weapon_data != null, "WeaponInstance requires WeaponData")
	var attack_speed_bonus_: float = get_total_stat_modifier(&"attack_speed_bonus_pct")
	var attack_speed_ := weapon_data.attack_speed * maxf(1.0 + attack_speed_bonus_, 0.1)
	return 1.0 / maxf(attack_speed_, 0.001)


func get_attack_range() -> float:
	assert(weapon_data != null, "WeaponInstance requires WeaponData")
	return weapon_data.attack_range


func get_total_attack_bonus() -> float:
	return _get_star_attack_bonus() + get_total_stat_modifier(&"attack_bonus_pct")


func get_max_rune_slots() -> int:
	return rune_slots.size()


func can_upgrade() -> bool:
	return star_level < 5


func get_total_stat_modifier(stat_key_: StringName) -> float:
	var total_modifier_: float = 0.0
	var rune_modifiers_: Dictionary = get_rune_stat_modifiers()

	for affix_ in affixes:
		if affix_ == null:
			continue
		if affix_.stat_modifiers.has(stat_key_):
			total_modifier_ += float(affix_.stat_modifiers.get(stat_key_, 0.0))
			continue
		total_modifier_ += float(affix_.stat_modifiers.get(String(stat_key_), 0.0))

	for modifier_key_ in rune_modifiers_:
		if StringName(String(modifier_key_)) != stat_key_:
			continue
		total_modifier_ += float(rune_modifiers_.get(modifier_key_, 0.0))

	return total_modifier_


func get_affix_ids() -> Array[StringName]:
	var affix_ids_: Array[StringName] = []

	for affix_ in affixes:
		if affix_ == null or affix_.affix_id.is_empty():
			continue
		affix_ids_.append(affix_.affix_id)

	return affix_ids_


func get_rune_stat_modifiers() -> Dictionary:
	var total_modifiers_: Dictionary = {}

	for slot_ in rune_slots:
		if slot_ == null or slot_.equipped_rune == null or slot_.equipped_rune.rune_data == null:
			continue

		for modifier_key_ in slot_.equipped_rune.rune_data.stat_modifiers:
			var current_value_: float = float(total_modifiers_.get(modifier_key_, 0.0))
			var add_value_: float = float(slot_.equipped_rune.rune_data.stat_modifiers.get(modifier_key_, 0.0))
			total_modifiers_[modifier_key_] = current_value_ + add_value_

	return total_modifiers_


func get_active_rune_effects() -> Array[StringName]:
	var effect_ids_: Array[StringName] = []

	for slot_ in rune_slots:
		if slot_ == null or slot_.equipped_rune == null or slot_.equipped_rune.rune_data == null:
			continue

		for effect_id_ in slot_.equipped_rune.rune_data.special_effects:
			effect_ids_.append(effect_id_)

	return effect_ids_


func has_active_rune_effect(effect_id_: StringName) -> bool:
	if effect_id_.is_empty():
		return false

	for active_effect_id_ in get_active_rune_effects():
		if active_effect_id_ == effect_id_:
			return true

	return false


func get_equipped_rune_ids() -> Array[StringName]:
	var rune_ids_: Array[StringName] = []

	for slot_ in rune_slots:
		if slot_ == null or slot_.equipped_rune == null or slot_.equipped_rune.rune_data == null:
			rune_ids_.append(&"")
			continue

		rune_ids_.append(slot_.equipped_rune.rune_data.get_runtime_rune_id())

	return rune_ids_


func get_attack_element_tags() -> Array[StringName]:
	var element_tags_: Array[StringName] = []

	for rune_id_ in get_equipped_rune_ids():
		match rune_id_:
			&"rune_fire":
				_append_attack_element_tag(element_tags_, &"elemental")
				_append_attack_element_tag(element_tags_, &"fire")
			&"rune_ice":
				_append_attack_element_tag(element_tags_, &"elemental")
				_append_attack_element_tag(element_tags_, &"ice")
			&"rune_lightning":
				_append_attack_element_tag(element_tags_, &"elemental")
				_append_attack_element_tag(element_tags_, &"lightning")
			&"rune_poison":
				_append_attack_element_tag(element_tags_, &"elemental")
				_append_attack_element_tag(element_tags_, &"poison")

	return element_tags_
#endregion

#region Helpers
static func _generate_instance_uid(weapon_data_: WeaponData) -> String:
	return "%s_%s_%d" % [
		String(weapon_data_.weapon_id),
		str(Time.get_unix_time_from_system()).replace(".", "_"),
		randi()
	]


func _get_star_attack_bonus() -> float:
	return float(clampi(star_level, 0, 5)) * 0.05


func _rebuild_rune_slots() -> void:
	var previous_runes_: Array[RuneInstanceResource] = []
	for slot_ in rune_slots:
		previous_runes_.append(slot_.equipped_rune if slot_ != null else null)

	rune_slots.clear()
	for slot_index_ in range(_star_level):
		var slot_: RuneSlotResource = RuneSlotResource.new()
		slot_.slot_index = slot_index_

		match slot_index_:
			0, 1:
				slot_.slot_type = RuneSlotResource.SlotType.FREE
			2, 3:
				slot_.slot_type = RuneSlotResource.SlotType.TYPED
				slot_.required_tag = _get_default_tag_for_index(slot_index_)
			4:
				slot_.slot_type = RuneSlotResource.SlotType.CORE
			_:
				assert(false, "WeaponInstance encountered unsupported rune slot index")

		if slot_index_ < previous_runes_.size():
			var rune_instance_: RuneInstanceResource = previous_runes_[slot_index_]
			if rune_instance_ != null and rune_instance_.rune_data != null and rune_instance_.rune_data.can_equip_in_slot(slot_.slot_type, slot_.required_tag):
				slot_.equipped_rune = rune_instance_

		rune_slots.append(slot_)


func _get_default_tag_for_index(index_: int) -> RuneDataResource.RuneTag:
	if weapon_data == null:
		return RuneDataResource.RuneTag.ATTACK

	match weapon_data.weapon_type:
		&"sword":
			return RuneDataResource.RuneTag.ATTACK if index_ == 2 else RuneDataResource.RuneTag.UTILITY
		&"staff":
			return RuneDataResource.RuneTag.ELEMENT if index_ == 2 else RuneDataResource.RuneTag.UTILITY
		_:
			return RuneDataResource.RuneTag.ATTACK


static func _get_save_manager() -> Node:
	var main_loop_: SceneTree = Engine.get_main_loop() as SceneTree
	if main_loop_ == null or main_loop_.root == null:
		return null
	return main_loop_.root.get_node_or_null("SaveManager")


static func _append_attack_element_tag(tags_: Array[StringName], tag_: StringName) -> void:
	if not tags_.has(tag_):
		tags_.append(tag_)
#endregion
