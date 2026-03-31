class_name PlayerController
extends CharacterBody2D

const EquipmentNode = preload("res://game/scripts/inventory/Equipment.gd")
const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
const InventoryNode = preload("res://game/scripts/inventory/Inventory.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

signal gold_changed(new_amount: int, delta: int)

@export var walk_speed: float = 140.0
@export var run_speed: float = 220.0
@export var walk_animation_fps: float = 7.0
@export var run_animation_fps: float = 10.0
@export var attack_cancel_lock_seconds: float = 0.12
@export var dash_distance: float = 120.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.8
@export var dash_invincible: bool = true
@export var dash_ghost_count: int = 3
@export var dash_ghost_interval: float = 0.05
@export var equipped_weapon_data: WeaponData
@export var enable_debug_weapon_switching: bool = false
@export var debug_equip_slot_1: WeaponData = preload("res://game/data/weapons/wpn_unarmed.tres")
@export var debug_equip_slot_2: WeaponData = preload("res://game/data/weapons/test_weapon.tres")
@export var debug_equip_slot_3: WeaponData = preload("res://game/data/weapons/test_staff_weapon.tres")
@export var debug_equip_slot_4: WeaponData = preload("res://game/data/weapons/test_heal_staff.tres")
@export var debug_equip_slot_5: WeaponData = preload("res://game/data/weapons/test_explosion_staff.tres")
@export var debug_inventory_herb_data: ItemDataResource = preload("res://game/data/items/material_herb.tres")
@export var debug_inventory_potion_data: ItemDataResource = preload("res://game/data/items/consumable_potion.tres")
@export var debug_inventory_iron_ore_data: ItemDataResource = preload("res://game/data/items/material_iron_ore.tres")
@export var debug_inventory_soul_shard_data: ItemDataResource = preload("res://game/data/items/material_soul_shard.tres")
@export var debug_inventory_crystal_data: ItemDataResource = preload("res://game/data/items/material_crystal.tres")
@export var debug_inventory_steel_ingot_data: ItemDataResource = preload("res://game/data/items/material_steel_ingot.tres")
@export var debug_inventory_essence_data: ItemDataResource = preload("res://game/data/items/material_essence.tres")

var facing_left: bool = false
var animation_time: float = 0.0
var controls_locked: bool = false
var transient_lock_time_remaining: float = 0.0
var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var equipped_weapon: WeaponInstance = null
var equipped_weapon_controller: WeaponController = null
var recent_pickup_summary: String = "N/A"
var gold: int = 0
var inventory_ui_open: bool = false
var dash_ghost_enabled: bool = false
var ghost_timer: float = 0.0
var ghost_sprites: Array[Sprite2D] = []
var hurtbox_monitoring_default: bool = true
var hurtbox_monitorable_default: bool = true
var is_respawning: bool = false

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory: InventoryNode = $Inventory
@onready var equipment: EquipmentNode = $Equipment

#region Core Lifecycle
func _ready() -> void:
	assert(sprite != null, "PlayerController requires Sprite2D")
	assert(state_machine != null, "PlayerController requires StateMachine")
	assert(weapon_pivot != null, "PlayerController requires WeaponPivot")
	assert(hurtbox != null, "PlayerController requires Hurtbox")
	assert(health_component != null, "PlayerController requires HealthComponent")
	assert(inventory != null, "PlayerController requires Inventory")
	assert(equipment != null, "PlayerController requires Equipment")
	assert(equipped_weapon_data != null, "PlayerController requires equipped_weapon_data")
	assert(dash_duration > 0.0, "PlayerController dash_duration must be greater than 0")
	assert(dash_distance >= 0.0, "PlayerController dash_distance must be non-negative")
	assert(dash_cooldown >= 0.0, "PlayerController dash_cooldown must be non-negative")
	assert(dash_ghost_count >= 0, "PlayerController dash_ghost_count must be non-negative")
	assert(dash_ghost_interval >= 0.0, "PlayerController dash_ghost_interval must be non-negative")

	hurtbox_monitoring_default = hurtbox.monitoring
	hurtbox_monitorable_default = hurtbox.monitorable
	if not health_component.died.is_connected(_on_health_depleted):
		health_component.died.connect(_on_health_depleted)
	equip_weapon_data(equipped_weapon_data)
	add_to_group("player")
	state_machine.start()


func _physics_process(delta_: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(dash_cooldown_timer - delta_, 0.0)
		if dash_cooldown_timer <= 0.0:
			can_dash = true

	if dash_ghost_enabled:
		_update_dash_ghosts(delta_)

	if transient_lock_time_remaining > 0.0:
		transient_lock_time_remaining = maxf(transient_lock_time_remaining - delta_, 0.0)


func _unhandled_input(event_: InputEvent) -> void:
	if _try_handle_debug_save_load(event_):
		return

	if _try_handle_debug_inventory(event_):
		return

	if event_.is_action_pressed("ui_inventory"):
		get_viewport().set_input_as_handled()
		return

	if inventory_ui_open:
		return

	if _try_handle_hotbar_input(event_):
		return

	if _try_handle_debug_weapon_switch(event_):
		return

	var can_update_attack_facing_: bool = not is_dashing
	if can_update_attack_facing_ and is_controls_locked() and get_current_state_name() != &"Attack":
		can_update_attack_facing_ = false

	if can_update_attack_facing_ and event_.is_action_pressed("attack_mouse"):
		_update_attack_facing_from_mouse()

	state_machine.handle_input(event_)

	if is_controls_locked() or is_dashing:
		return

	if event_.is_action_pressed("attack_mouse"):
		request_attack_state()
#endregion

#region Public
func get_move_input() -> Vector2:
	if is_controls_locked() or is_dashing:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_run_requested() -> bool:
	return Input.is_action_pressed("move_run")


func move_character(input_vector_: Vector2, speed_: float) -> void:
	var runtime_speed_multiplier_: float = 1.0
	if equipped_weapon != null:
		runtime_speed_multiplier_ += equipped_weapon.get_total_stat_modifier(&"move_speed_bonus_pct")

	_update_facing(input_vector_)
	velocity = input_vector_ * speed_ * maxf(runtime_speed_multiplier_, 0.1)
	move_and_slide()


func play_idle_animation() -> void:
	animation_time = 0.0
	sprite.frame = 0


func play_move_animation(delta_: float, animation_fps_: float) -> void:
	animation_time += delta_ * animation_fps_
	sprite.frame = int(animation_time) % sprite.hframes


func play_weapon_attack_animation(_animation_name_: String) -> void:
	# Placeholder hook until dedicated player attack clips are authored.
	animation_time = 0.0


func play_dash_animation(delta_: float) -> void:
	play_move_animation(delta_, run_animation_fps * 1.5)


func set_controls_locked(value_: bool) -> void:
	controls_locked = value_


func is_controls_locked() -> bool:
	return controls_locked or transient_lock_time_remaining > 0.0 or inventory_ui_open


func lock_controls_for(duration_: float) -> void:
	transient_lock_time_remaining = maxf(duration_, 0.0)


func get_current_state_name() -> StringName:
	if state_machine == null or state_machine.current_state == null:
		return &""
	return state_machine.current_state.name


func get_health_component() -> HealthComponent:
	return health_component


func get_temporary_hp() -> float:
	if health_component == null:
		return 0.0
	return health_component.temporary_hp


func get_inventory() -> InventoryNode:
	return inventory


func use_consumable(item_data_: ItemDataResource, source_inventory_: InventoryNode = null) -> Dictionary:
	var preview_result_: Dictionary = _preview_consumable_use(item_data_)
	if not bool(preview_result_.get("success", false)):
		return preview_result_

	var inventory_to_consume_from_: InventoryNode = source_inventory_
	if inventory_to_consume_from_ == null:
		inventory_to_consume_from_ = inventory
	if inventory_to_consume_from_ == null:
		return _build_consumable_use_result(false, &"missing_inventory")

	var removed_amount_: int = inventory_to_consume_from_.remove_item(item_data_, 1)
	if removed_amount_ <= 0:
		return _build_consumable_use_result(false, &"remove_failed")

	var apply_result_: Dictionary = _apply_consumable_effect(item_data_)
	if bool(apply_result_.get("success", false)):
		return apply_result_

	var refunded_amount_: int = inventory_to_consume_from_.add_item(item_data_, 1)
	if refunded_amount_ > 0:
		push_warning("[PlayerController] Failed to refund consumable after effect application failure: %s" % item_data_.display_name)

	return apply_result_


func get_equipped_weapon() -> WeaponInstance:
	if equipment != null:
		return equipment.equipped_weapon
	return equipped_weapon


func get_equipped_in_slot(slot_: EquipmentNode.EquipmentSlot) -> Variant:
	if equipment == null:
		return null
	return equipment.get_equipped_in_slot(slot_)


func get_equipped_weapon_controller() -> WeaponController:
	return equipped_weapon_controller


func get_equipped_weapon_id() -> StringName:
	assert(equipped_weapon != null, "PlayerController equipped_weapon must be initialized")
	return equipped_weapon.weapon_id


func get_equipped_weapon_display_name() -> String:
	if equipped_weapon_data == null:
		return "N/A"
	return equipped_weapon_data.display_name


func get_recent_pickup_summary() -> String:
	return recent_pickup_summary


func get_gold() -> int:
	return gold


func set_gold(amount_: int) -> void:
	var previous_gold_: int = gold
	gold = maxi(0, amount_)
	var delta_: int = gold - previous_gold_
	if delta_ != 0:
		gold_changed.emit(gold, delta_)


func add_gold(amount_: int) -> void:
	if amount_ == 0:
		return
	set_gold(gold + amount_)


func can_spend_gold(amount_: int) -> bool:
	return gold >= maxi(amount_, 0)


func spend_gold(amount_: int) -> bool:
	var safe_amount_: int = maxi(amount_, 0)
	if not can_spend_gold(safe_amount_):
		return false

	set_gold(gold - safe_amount_)
	return true


func get_inventory_usage_summary() -> String:
	if inventory == null:
		return "N/A"
	return "%d / %d" % [inventory.get_used_slot_count(), inventory.max_slots]


func get_current_attack_phase() -> StringName:
	if equipped_weapon_controller == null:
		return &"idle"
	return equipped_weapon_controller.get_current_phase()


func set_inventory_ui_open(value_: bool) -> void:
	inventory_ui_open = value_


func is_inventory_ui_open() -> bool:
	return inventory_ui_open


func get_debug_runtime_snapshot() -> Dictionary:
	return {
		"controls_locked": controls_locked,
		"transient_lock_time_remaining": transient_lock_time_remaining,
		"inventory_ui_open": inventory_ui_open,
		"is_dashing": is_dashing,
		"is_respawning": is_respawning,
		"state": String(get_current_state_name()),
		"velocity": {
			"x": snappedf(velocity.x, 0.001),
			"y": snappedf(velocity.y, 0.001)
		},
		"global_position": {
			"x": snappedf(global_position.x, 0.001),
			"y": snappedf(global_position.y, 0.001)
		}
	}


func reset_runtime_state_for_load() -> void:
	if equipped_weapon_controller != null and equipped_weapon_controller.has_method("cancel_attack"):
		equipped_weapon_controller.cancel_attack()

	if state_machine != null and state_machine.current_state != null and state_machine.current_state.name != &"Idle":
		state_machine.transition_to(&"Idle")

	transient_lock_time_remaining = 0.0
	inventory_ui_open = false
	is_respawning = false
	set_controls_locked(false)

	is_dashing = false
	dash_timer = 0.0
	dash_direction = Vector2.ZERO
	dash_cooldown_timer = 0.0
	can_dash = true
	velocity = Vector2.ZERO

	enable_dash_ghost(false)
	set_invincible(false)
	sprite.modulate = Color.WHITE
	play_idle_animation()


func can_current_weapon_combo() -> bool:
	if equipped_weapon_controller == null:
		return false
	return equipped_weapon_controller.can_combo()


func is_attack_combo_queued() -> bool:
	if state_machine == null or state_machine.current_state == null:
		return false
	if not state_machine.current_state.has_method("is_combo_queued"):
		return false
	return bool(state_machine.current_state.call("is_combo_queued"))


func is_facing_left() -> bool:
	return facing_left


func get_attack_direction() -> Vector2:
	return Vector2.LEFT if facing_left else Vector2.RIGHT


func request_attack_state() -> void:
	if state_machine == null:
		return
	if get_current_state_name() == &"Attack" or get_current_state_name() == &"Dash" or is_dashing:
		return

	state_machine.transition_to(&"Attack")


func resolve_locomotion_state_name() -> StringName:
	var input_vector_ := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector_ == Vector2.ZERO:
		return &"Idle"
	if is_run_requested():
		return &"Run"
	return &"Walk"


func equip_weapon_data(weapon_data_: WeaponData) -> void:
	assert(weapon_data_ != null, "PlayerController cannot equip null WeaponData")
	assert(weapon_data_.weapon_scene != null, "PlayerController requires WeaponData.weapon_scene")

	equip_weapon_instance(WeaponInstanceResource.create_from_data(weapon_data_))


func equip_weapon_instance(weapon_instance_: WeaponInstanceResource) -> void:
	assert(weapon_instance_ != null, "PlayerController cannot equip null WeaponInstance")
	assert(weapon_instance_.weapon_data != null, "PlayerController requires WeaponInstance.weapon_data")
	assert(weapon_instance_.weapon_data.weapon_scene != null, "PlayerController requires WeaponData.weapon_scene")

	if equipment != null and equipment.equipped_weapon != weapon_instance_:
		equipment.equip_weapon(weapon_instance_)

	_apply_equipped_weapon_instance(weapon_instance_)


func try_equip_from_inventory(slot_index_: int) -> bool:
	if inventory == null or equipment == null:
		return false

	var slot_: InventorySlot = inventory.get_slot(slot_index_)
	if slot_ == null:
		return false

	match slot_.get_content_type():
		&"weapon":
			var weapon_instance_: WeaponInstanceResource = slot_.weapon_instance
			if weapon_instance_ == null:
				return false

			var current_weapon_: WeaponInstanceResource = equipment.get_equipped_in_slot(EquipmentNode.EquipmentSlot.WEAPON_MAIN) as WeaponInstanceResource
			if current_weapon_ == weapon_instance_:
				if not inventory.remove_weapon(weapon_instance_):
					return false
				_apply_equipped_weapon_instance(weapon_instance_)
				return true

			if not inventory.remove_weapon(weapon_instance_):
				return false

			var old_weapon_ := equipment.equip_weapon(weapon_instance_)
			if old_weapon_ != null and not inventory.add_weapon(old_weapon_):
				_rollback_weapon_inventory_equip(weapon_instance_, old_weapon_)
				return false

			_apply_equipped_weapon_instance(weapon_instance_)
			return true
		&"gear":
			var gear_instance_: GearInstanceResource = slot_.gear_instance
			if gear_instance_ == null:
				return false

			var target_slot_: int = _get_equipment_slot_for_gear(gear_instance_)
			if target_slot_ == -1:
				return false

			var current_gear_: GearInstanceResource = equipment.get_equipped_in_slot(target_slot_) as GearInstanceResource
			if current_gear_ == gear_instance_:
				return inventory.remove_gear(gear_instance_)

			if not inventory.remove_gear(gear_instance_):
				return false

			var old_gear_ := equipment.equip_gear(gear_instance_)
			if old_gear_ != null and not inventory.add_gear(old_gear_):
				_rollback_gear_inventory_equip(gear_instance_, old_gear_)
				return false

			return true
		_:
			return false


func try_unequip_to_inventory(slot_: EquipmentNode.EquipmentSlot) -> bool:
	if inventory == null or equipment == null:
		return false

	var equipped_instance_ = equipment.get_equipped_in_slot(slot_)
	if equipped_instance_ == null:
		return false

	if slot_ == EquipmentNode.EquipmentSlot.WEAPON_MAIN:
		var weapon_instance_: WeaponInstanceResource = equipped_instance_ as WeaponInstanceResource
		if weapon_instance_ == null or not inventory.add_weapon(weapon_instance_):
			return false

		var unequipped_weapon_: WeaponInstanceResource = equipment.unequip_slot(slot_) as WeaponInstanceResource
		if unequipped_weapon_ == null:
			inventory.remove_weapon(weapon_instance_)
			return false

		_apply_equipped_weapon_instance(equipment.equipped_weapon)
		return true

	var gear_instance_: GearInstanceResource = equipped_instance_ as GearInstanceResource
	if gear_instance_ == null or not inventory.add_gear(gear_instance_):
		return false

	var unequipped_gear_: GearInstanceResource = equipment.unequip_slot(slot_) as GearInstanceResource
	if unequipped_gear_ == null:
		inventory.remove_gear(gear_instance_)
		return false

	return true


func quick_move_from_inventory(from_inventory_: InventoryNode, slot_index_: int, target_inventory_: InventoryNode = null) -> bool:
	if from_inventory_ == null:
		return false

	if target_inventory_ == null:
		if from_inventory_ != inventory:
			return false

		var slot_: InventorySlot = from_inventory_.get_slot(slot_index_)
		if slot_ == null:
			return false

		match slot_.get_content_type():
			&"weapon", &"gear":
				return try_equip_from_inventory(slot_index_)
			&"item":
				return from_inventory_.split_stack(slot_index_) != -1
			_:
				return false

	return from_inventory_.quick_move_slot_to_inventory(slot_index_, target_inventory_)


func to_save_dict() -> Dictionary:
	var current_weapon_: WeaponInstance = get_equipped_weapon()
	var equipped_weapon_uid_: String = current_weapon_.instance_uid if current_weapon_ != null else ""
	var equipped_weapon_id_: String = String(current_weapon_.weapon_id) if current_weapon_ != null else ""
	var equipped_weapon_enhance_: int = current_weapon_.enhance_level if current_weapon_ != null else 0

	return {
		"current_hp": health_component.current_hp,
		"temporary_hp": health_component.temporary_hp,
		"gold": gold,
		"global_position": {
			"x": global_position.x,
			"y": global_position.y
		},
		"_deprecated_equipped_weapon_fields": true,
		"equipped_weapon_uid": equipped_weapon_uid_,
		"equipped_weapon_id": equipped_weapon_id_,
		"equipped_weapon_enhance_level": equipped_weapon_enhance_,
		"equipped_weapon_star_level": current_weapon_.star_level if current_weapon_ != null else 0,
		"equipped_weapon_temporary_enchants": current_weapon_.temporary_enchants.map(func(value_: StringName) -> String: return String(value_)) if current_weapon_ != null else [],
		"equipped_weapon_socketed_gems": current_weapon_.socketed_gems.map(func(value_: StringName) -> String: return String(value_)) if current_weapon_ != null else [],
		"equipped_weapon_affixes": current_weapon_.affixes.map(func(value_) -> Dictionary: return value_.to_save_dict()) if current_weapon_ != null else [],
		"equipped_weapon_runes": current_weapon_.get_equipped_rune_ids().map(func(value_: StringName) -> String: return String(value_)) if current_weapon_ != null else [],
		"equipment": equipment.to_save_dict() if equipment != null else {}
	}


func from_save_dict(data_: Dictionary) -> Dictionary:
	var load_report_ := {
		"equipment_attempted": false,
		"equipment_loaded": false
	}

	var current_hp_: float = float(data_.get("current_hp", health_component.max_hp))
	health_component.current_hp = clampf(current_hp_, 0.0, health_component.max_hp)
	health_component.set_temporary_hp(float(data_.get("temporary_hp", 0.0)))
	health_component.health_changed.emit(health_component.current_hp, health_component.max_hp)
	set_gold(int(data_.get("gold", 0)))

	var position_data_ = data_.get("global_position", {})
	if typeof(position_data_) == TYPE_DICTIONARY:
		global_position = Vector2(
			float(position_data_.get("x", global_position.x)),
			float(position_data_.get("y", global_position.y))
		)

	var equipment_data_ = data_.get("equipment", {})
	if equipment != null and typeof(equipment_data_) == TYPE_DICTIONARY and not equipment_data_.is_empty():
		load_report_["equipment_attempted"] = true
		load_report_["equipment_loaded"] = equipment.from_save_dict(equipment_data_)
		_apply_equipped_weapon_instance(equipment.equipped_weapon)

	return load_report_


func restore_equipped_weapon_from_save(data_: Dictionary) -> bool:
	var weapon_id_: StringName = StringName(String(data_.get("equipped_weapon_id", "")))
	if weapon_id_.is_empty():
		return false

	var save_manager_: Node = _get_save_manager()
	if save_manager_ == null:
		return false

	var weapon_data_: WeaponData = save_manager_.resolve_weapon_data(weapon_id_) as WeaponData
	if weapon_data_ == null:
		return false

	var weapon_save_data_ := {
		"instance_uid": String(data_.get("equipped_weapon_uid", "")),
		"weapon_id": String(weapon_id_),
		"enhance_level": int(data_.get("equipped_weapon_enhance_level", 0)),
		"star_level": int(data_.get("equipped_weapon_star_level", 0)),
		"temporary_enchants": data_.get("equipped_weapon_temporary_enchants", []),
		"socketed_gems": data_.get("equipped_weapon_socketed_gems", []),
		"affixes": data_.get("equipped_weapon_affixes", []),
		"runes": data_.get("equipped_weapon_runes", [])
	}
	equip_weapon_instance(WeaponInstanceResource.create_from_save_dict(weapon_data_, weapon_save_data_))
	return true


#endregion

#region Dash
func start_dash() -> void:
	assert(dash_duration > 0.0, "PlayerController dash_duration must be greater than 0 before dash")

	var input_direction_: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction_ != Vector2.ZERO:
		dash_direction = input_direction_.normalized()
	else:
		dash_direction = Vector2.LEFT if facing_left else Vector2.RIGHT

	is_dashing = true
	can_dash = false
	dash_timer = 0.0
	set_controls_locked(true)
	_update_facing(dash_direction)


func perform_dash_movement(delta_: float) -> void:
	if not is_dashing:
		return

	var dash_speed_: float = dash_distance / dash_duration
	velocity = dash_direction * dash_speed_
	move_and_slide()
	dash_timer += delta_


func end_dash() -> void:
	is_dashing = false
	dash_timer = 0.0
	velocity = Vector2.ZERO
	set_controls_locked(false)


func start_dash_cooldown() -> void:
	dash_cooldown_timer = dash_cooldown
	if dash_cooldown_timer <= 0.0:
		can_dash = true


func set_invincible(invincible_: bool) -> void:
	assert(hurtbox != null, "PlayerController requires Hurtbox before toggling invincibility")

	hurtbox.monitoring = false if invincible_ else hurtbox_monitoring_default
	hurtbox.monitorable = false if invincible_ else hurtbox_monitorable_default


func enable_dash_ghost(enabled_: bool) -> void:
	dash_ghost_enabled = enabled_
	ghost_timer = 0.0

	if enabled_:
		return

	for ghost_ in ghost_sprites:
		if is_instance_valid(ghost_):
			ghost_.queue_free()
	ghost_sprites.clear()


func can_perform_dash() -> bool:
	return can_dash and dash_cooldown_timer <= 0.0 and not is_dashing and not controls_locked
#endregion

#region Helpers
func _instantiate_weapon_controller(weapon_data_: WeaponData) -> WeaponController:
	var weapon_controller_: WeaponController = weapon_data_.weapon_scene.instantiate() as WeaponController
	assert(weapon_controller_ != null, "WeaponData.weapon_scene must instantiate WeaponController")

	weapon_pivot.add_child(weapon_controller_)
	return weapon_controller_


func _clear_equipped_weapon_controller() -> void:
	if equipped_weapon_controller == null:
		return

	var weapon_controller_parent_: Node = equipped_weapon_controller.get_parent()
	if weapon_controller_parent_ != null:
		weapon_controller_parent_.remove_child(equipped_weapon_controller)

	equipped_weapon_controller.on_unequipped()
	equipped_weapon_controller.queue_free()
	equipped_weapon_controller = null


func _apply_equipped_weapon_instance(weapon_instance_: WeaponInstanceResource) -> void:
	var interrupted_attack_ := get_current_state_name() == &"Attack"
	_clear_equipped_weapon_controller()

	equipped_weapon = weapon_instance_
	equipped_weapon_data = weapon_instance_.weapon_data if weapon_instance_ != null else null

	if weapon_instance_ != null:
		equipped_weapon_controller = _instantiate_weapon_controller(weapon_instance_.weapon_data)
		equipped_weapon_controller.setup(self, equipped_weapon)
		equipped_weapon_controller.on_equipped()

	if interrupted_attack_ and state_machine != null and get_current_state_name() == &"Attack":
		state_machine.transition_to(resolve_locomotion_state_name())


func _rollback_weapon_inventory_equip(new_weapon_: WeaponInstanceResource, old_weapon_: WeaponInstanceResource) -> void:
	var reverted_weapon_ := equipment.equip_weapon(old_weapon_) if equipment != null else null
	if reverted_weapon_ != null and reverted_weapon_ != new_weapon_:
		push_warning("[PlayerController] Unexpected weapon rollback state during equip")

	if inventory != null and not inventory.add_weapon(new_weapon_):
		push_warning("[PlayerController] Failed to restore weapon to inventory after rollback")

	_apply_equipped_weapon_instance(old_weapon_)


func _rollback_gear_inventory_equip(new_gear_: GearInstanceResource, old_gear_: GearInstanceResource) -> void:
	var reverted_gear_ := equipment.equip_gear(old_gear_) if equipment != null else null
	if reverted_gear_ != null and reverted_gear_ != new_gear_:
		push_warning("[PlayerController] Unexpected gear rollback state during equip")

	if inventory != null and not inventory.add_gear(new_gear_):
		push_warning("[PlayerController] Failed to restore gear to inventory after rollback")


func _build_consumable_use_result(success_: bool, reason_: StringName, effect_: StringName = &"none", applied_value_: float = 0.0) -> Dictionary:
	return {
		"success": success_,
		"reason": reason_,
		"effect": effect_,
		"applied_value": applied_value_
	}


func _preview_consumable_use(item_data_: ItemDataResource) -> Dictionary:
	if item_data_ == null:
		return _build_consumable_use_result(false, &"missing_item_data")

	if not item_data_.is_consumable_item():
		return _build_consumable_use_result(false, &"not_consumable")

	match item_data_.consumable_effect:
		ItemData.ConsumableEffect.HEAL:
			if item_data_.consumable_heal_amount <= 0.0:
				return _build_consumable_use_result(false, &"invalid_heal_amount")
			if health_component == null:
				return _build_consumable_use_result(false, &"missing_health_component")
			if health_component.current_hp >= health_component.max_hp:
				return _build_consumable_use_result(false, &"already_full_hp")
			var restorable_hp_: float = minf(item_data_.consumable_heal_amount, health_component.max_hp - health_component.current_hp)
			return _build_consumable_use_result(true, &"ok", &"heal", restorable_hp_)
		_:
			return _build_consumable_use_result(false, &"unsupported_effect")


func _apply_consumable_effect(item_data_: ItemDataResource) -> Dictionary:
	if item_data_ == null:
		return _build_consumable_use_result(false, &"missing_item_data")

	match item_data_.consumable_effect:
		ItemData.ConsumableEffect.HEAL:
			if health_component == null:
				return _build_consumable_use_result(false, &"missing_health_component")
			var restored_hp_: float = health_component.heal(item_data_.consumable_heal_amount)
			if restored_hp_ <= 0.0:
				return _build_consumable_use_result(false, &"heal_not_applied")
			return _build_consumable_use_result(true, &"ok", &"heal", restored_hp_)
		_:
			return _build_consumable_use_result(false, &"unsupported_effect")


func _get_equipment_slot_for_gear(gear_instance_: GearInstanceResource) -> int:
	if gear_instance_ == null or gear_instance_.gear_data == null:
		return -1

	match gear_instance_.gear_data.get_equipment_slot_id():
		&"helmet":
			return EquipmentNode.EquipmentSlot.HELMET
		&"chestplate":
			return EquipmentNode.EquipmentSlot.CHESTPLATE
		&"leggings":
			return EquipmentNode.EquipmentSlot.LEGGINGS
		&"boots":
			return EquipmentNode.EquipmentSlot.BOOTS
		_:
			return -1


func _try_handle_debug_weapon_switch(event_: InputEvent) -> bool:
	if not enable_debug_weapon_switching:
		return false

	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return false

	if event_.is_action_pressed("debug_equip_1"):
		_debug_equip_weapon(debug_equip_slot_1)
		return true

	if event_.is_action_pressed("debug_equip_2"):
		_debug_equip_weapon(debug_equip_slot_2)
		return true

	if event_.is_action_pressed("debug_equip_3"):
		_debug_equip_weapon(debug_equip_slot_3)
		return true

	if event_.is_action_pressed("debug_equip_4"):
		_debug_equip_weapon(debug_equip_slot_4)
		return true

	if event_.is_action_pressed("debug_equip_5"):
		_debug_equip_weapon(debug_equip_slot_5)
		return true

	return false


func _try_handle_debug_save_load(event_: InputEvent) -> bool:
	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ == null or not key_event_.pressed or key_event_.echo:
		return false

	var save_manager_: Node = _get_save_manager()
	if save_manager_ == null:
		return false

	if key_event_.physical_keycode == KEY_F5:
		save_manager_.save_game()
		return true

	if key_event_.physical_keycode == KEY_F10:
		save_manager_.load_game()
		return true

	return false


func _debug_equip_weapon(weapon_data_: WeaponData) -> void:
	if weapon_data_ == null:
		push_warning("[Debug] Missing weapon data for debug equip")
		return

	equip_weapon_data(weapon_data_)
	print("[Debug] Equipped: %s" % get_equipped_weapon_display_name())


func _try_handle_debug_inventory(event_: InputEvent) -> bool:
	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return false

	if event_.is_action_pressed("debug_add_herb"):
		_debug_add_inventory_item(debug_inventory_herb_data, 5)
		return true

	if event_.is_action_pressed("debug_add_potion"):
		_debug_add_inventory_item(debug_inventory_potion_data, 3)
		return true

	if event_.is_action_pressed("debug_add_runes"):
		_debug_add_all_runes()
		return true

	if event_.is_action_pressed("debug_print_inventory"):
		_debug_print_inventory()
		return true

	if event_.is_action_pressed("debug_add_upgrade_materials"):
		_debug_add_upgrade_materials()
		return true

	if event_.is_action_pressed("debug_add_gold"):
		add_gold(1000)
		record_recent_pickup("金幣", 1000)
		print("[Debug][Gold] Added 1000 gold (current=%d)" % gold)
		return true

	return false


func _debug_add_inventory_item(item_data_: ItemDataResource, amount_: int) -> void:
	if inventory == null:
		push_warning("[Debug][Inventory] Inventory node is missing")
		return

	if item_data_ == null:
		push_warning("[Debug][Inventory] Missing item data")
		return

	var remaining_amount_: int = inventory.add_item(item_data_, amount_)
	var added_amount_: int = amount_ - remaining_amount_
	print("[Debug][Inventory] Added %d x %s" % [added_amount_, item_data_.display_name])

	if remaining_amount_ > 0:
		print("[Debug][Inventory] Inventory full, %d item(s) could not be added" % remaining_amount_)


func record_recent_pickup(display_name_: String, amount_: int) -> void:
	var safe_amount_: int = maxi(amount_, 1)
	recent_pickup_summary = "%s x%d" % [display_name_, safe_amount_]


func _debug_print_inventory() -> void:
	if inventory == null:
		push_warning("[Debug][Inventory] Inventory node is missing")
		return

	inventory.debug_print_contents()


func _debug_add_upgrade_materials() -> void:
	_debug_add_inventory_item(debug_inventory_iron_ore_data, 40)
	_debug_add_inventory_item(debug_inventory_soul_shard_data, 20)
	_debug_add_inventory_item(debug_inventory_crystal_data, 15)
	_debug_add_inventory_item(debug_inventory_steel_ingot_data, 20)
	_debug_add_inventory_item(debug_inventory_essence_data, 10)


func _debug_add_all_runes() -> void:
	if inventory == null:
		push_warning("[Debug][Runes] Inventory node is missing")
		return

	var rune_manager_: Node = _get_rune_manager()
	if rune_manager_ == null:
		push_warning("[Debug][Runes] RuneManager is unavailable")
		return

	for rune_data_ in rune_manager_.available_runes:
		var remaining_amount_: int = inventory.add_item(rune_data_, 2)
		assert(remaining_amount_ == 0, "Debug rune grant should fit inside the test inventory")

	print("[Debug][Runes] Added all rune stones x2")


func _update_facing(input_vector_: Vector2) -> void:
	if input_vector_.x < 0.0:
		_set_facing_left()
	elif input_vector_.x > 0.0:
		_set_facing_right()


func _update_attack_facing_from_mouse() -> void:
	var attack_direction_: Vector2 = get_global_mouse_position() - global_position
	if attack_direction_ == Vector2.ZERO:
		return

	_set_facing_by_direction(attack_direction_)


func _set_facing_by_direction(direction_: Vector2) -> void:
	if direction_.x < -0.1:
		_set_facing_left()
	elif direction_.x > 0.1:
		_set_facing_right()


func _set_facing_left() -> void:
	facing_left = true
	sprite.flip_h = true

	var weapon_scale_: Vector2 = weapon_pivot.scale
	weapon_scale_.x = -absf(weapon_scale_.x)
	weapon_pivot.scale = weapon_scale_


func _try_handle_hotbar_input(event_: InputEvent) -> bool:
	var hotbar_index_: int = -1
	if event_.is_action_pressed("hotbar_use_1"):
		hotbar_index_ = 0
	elif event_.is_action_pressed("hotbar_use_2"):
		hotbar_index_ = 1
	elif event_.is_action_pressed("hotbar_use_3"):
		hotbar_index_ = 2
	elif event_.is_action_pressed("hotbar_use_4"):
		hotbar_index_ = 3
	elif event_.is_action_pressed("hotbar_use_5"):
		hotbar_index_ = 4

	if hotbar_index_ == -1 or is_controls_locked() or is_dashing:
		return false

	var hotbar_manager_: Node = _get_hotbar_manager()
	if hotbar_manager_ != null and hotbar_manager_.use_hotbar_slot(self, hotbar_index_):
		return true

	return false


func _toggle_inventory_ui() -> void:
	var inventory_ui_: Node = _get_inventory_ui()
	if inventory_ui_ == null:
		return

	var next_open_: bool = not bool(inventory_ui_.call("is_open"))
	inventory_ui_.call("set_inventory_open", next_open_)


func _set_facing_right() -> void:
	facing_left = false
	sprite.flip_h = false

	var weapon_scale_: Vector2 = weapon_pivot.scale
	weapon_scale_.x = absf(weapon_scale_.x)
	weapon_pivot.scale = weapon_scale_


func _update_dash_ghosts(delta_: float) -> void:
	if not is_dashing:
		return

	ghost_timer += delta_
	if ghost_timer < dash_ghost_interval:
		return

	ghost_timer = 0.0
	_create_ghost()


func _create_ghost() -> void:
	if dash_ghost_count <= 0:
		return

	var parent_node_: Node = get_parent()
	if parent_node_ == null:
		return

	var ghost_: Sprite2D = Sprite2D.new()
	ghost_.texture = sprite.texture
	ghost_.hframes = sprite.hframes
	ghost_.vframes = sprite.vframes
	ghost_.frame = sprite.frame
	ghost_.frame_coords = sprite.frame_coords
	ghost_.flip_h = sprite.flip_h
	ghost_.centered = sprite.centered
	ghost_.offset = sprite.offset
	ghost_.global_position = sprite.global_position
	ghost_.modulate = Color(1.0, 1.0, 1.0, 0.45)
	parent_node_.add_child(ghost_)
	ghost_sprites.append(ghost_)

	while ghost_sprites.size() > dash_ghost_count:
		var oldest_ghost_: Sprite2D = ghost_sprites.pop_front()
		if is_instance_valid(oldest_ghost_):
			oldest_ghost_.queue_free()

	var tween_: Tween = create_tween()
	tween_.tween_property(ghost_, "modulate:a", 0.0, 0.2)
	tween_.tween_callback(Callable(ghost_, "queue_free"))


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")


func _get_rune_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("RuneManager")


func _get_hotbar_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("HotbarRuntime")


func _get_inventory_ui() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null:
		return null

	var inventory_ui_nodes_: Array[Node] = tree_.get_nodes_in_group("inventory_ui")
	if inventory_ui_nodes_.is_empty():
		return null

	return inventory_ui_nodes_[0]


func _on_health_depleted() -> void:
	if is_respawning:
		return

	is_respawning = true
	set_controls_locked(true)
	velocity = Vector2.ZERO
	sprite.modulate = Color(1.0, 0.72, 0.72, 0.8)

	await get_tree().create_timer(0.35).timeout

	_respawn_at_checkpoint()
	sprite.modulate = Color.WHITE
	set_controls_locked(false)
	is_respawning = false

	if state_machine != null and state_machine.has_method("transition_to"):
		state_machine.transition_to(&"Idle")


func _respawn_at_checkpoint() -> void:
	var scene_transition_manager_: Node = _get_scene_transition_manager()
	var respawn_point_: Dictionary = {}
	var has_respawn_position_: bool = false
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("get_respawn_point"):
		respawn_point_ = scene_transition_manager_.get_respawn_point()

	var respawn_position_: Vector2 = Vector2.ZERO
	if not respawn_point_.is_empty():
		respawn_position_ = respawn_point_.get("position", Vector2.ZERO)
		has_respawn_position_ = respawn_point_.has("position")
	elif scene_transition_manager_ != null and scene_transition_manager_.has_method("get_spawn_position"):
		respawn_position_ = scene_transition_manager_.get_spawn_position(&"Spawn_default")
		has_respawn_position_ = true

	health_component.current_hp = health_component.max_hp
	health_component.set_temporary_hp(0.0)

	if has_respawn_position_:
		global_position = respawn_position_

	velocity = Vector2.ZERO


func _get_scene_transition_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SceneTransitionManager")
#endregion
