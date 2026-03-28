class_name PlayerController
extends CharacterBody2D

const InventoryNode = preload("res://game/scripts/inventory/Inventory.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

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
var dash_ghost_enabled: bool = false
var ghost_timer: float = 0.0
var ghost_sprites: Array[Sprite2D] = []
var hurtbox_monitoring_default: bool = true
var hurtbox_monitorable_default: bool = true

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory: InventoryNode = $Inventory

#region Core Lifecycle
func _ready() -> void:
	assert(sprite != null, "PlayerController requires Sprite2D")
	assert(state_machine != null, "PlayerController requires StateMachine")
	assert(weapon_pivot != null, "PlayerController requires WeaponPivot")
	assert(hurtbox != null, "PlayerController requires Hurtbox")
	assert(health_component != null, "PlayerController requires HealthComponent")
	assert(inventory != null, "PlayerController requires Inventory")
	assert(equipped_weapon_data != null, "PlayerController requires equipped_weapon_data")
	assert(dash_duration > 0.0, "PlayerController dash_duration must be greater than 0")
	assert(dash_distance >= 0.0, "PlayerController dash_distance must be non-negative")
	assert(dash_cooldown >= 0.0, "PlayerController dash_cooldown must be non-negative")
	assert(dash_ghost_count >= 0, "PlayerController dash_ghost_count must be non-negative")
	assert(dash_ghost_interval >= 0.0, "PlayerController dash_ghost_interval must be non-negative")

	hurtbox_monitoring_default = hurtbox.monitoring
	hurtbox_monitorable_default = hurtbox.monitorable
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

	if _try_handle_debug_weapon_switch(event_):
		return

	if _try_handle_debug_inventory(event_):
		return

	state_machine.handle_input(event_)

	if is_controls_locked() or is_dashing:
		return

	if event_.is_action_pressed("attack"):
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
	_update_facing(input_vector_)
	velocity = input_vector_ * speed_
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
	return controls_locked or transient_lock_time_remaining > 0.0


func lock_controls_for(duration_: float) -> void:
	transient_lock_time_remaining = maxf(duration_, 0.0)


func get_current_state_name() -> StringName:
	if state_machine == null or state_machine.current_state == null:
		return &""
	return state_machine.current_state.name


func get_health_component() -> HealthComponent:
	return health_component


func get_inventory() -> InventoryNode:
	return inventory


func get_equipped_weapon() -> WeaponInstance:
	return equipped_weapon


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


func get_inventory_usage_summary() -> String:
	if inventory == null:
		return "N/A"
	return "%d / %d" % [inventory.get_used_slot_count(), inventory.max_slots]


func get_current_attack_phase() -> StringName:
	if equipped_weapon_controller == null:
		return &"idle"
	return equipped_weapon_controller.get_current_phase()


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

	var interrupted_attack_ := get_current_state_name() == &"Attack"
	_clear_equipped_weapon_controller()

	equipped_weapon = weapon_instance_
	equipped_weapon_data = weapon_instance_.weapon_data
	equipped_weapon_controller = _instantiate_weapon_controller(weapon_instance_.weapon_data)
	equipped_weapon_controller.setup(self, equipped_weapon)
	equipped_weapon_controller.on_equipped()

	if interrupted_attack_ and state_machine != null and get_current_state_name() == &"Attack":
		state_machine.transition_to(resolve_locomotion_state_name())


func to_save_dict() -> Dictionary:
	var equipped_weapon_uid_ := inventory.get_equipped_weapon_uid() if inventory != null else ""
	var equipped_weapon_id_ := String(equipped_weapon.weapon_id) if equipped_weapon != null else ""
	var equipped_weapon_enhance_ := equipped_weapon.enhance_level if equipped_weapon != null else 0

	return {
		"current_hp": health_component.current_hp,
		"global_position": {
			"x": global_position.x,
			"y": global_position.y
		},
		"equipped_weapon_uid": equipped_weapon_uid_,
		"equipped_weapon_id": equipped_weapon_id_,
		"equipped_weapon_enhance_level": equipped_weapon_enhance_,
		"equipped_weapon_temporary_enchants": equipped_weapon.temporary_enchants.map(func(value_: StringName) -> String: return String(value_)) if equipped_weapon != null else [],
		"equipped_weapon_socketed_gems": equipped_weapon.socketed_gems.map(func(value_: StringName) -> String: return String(value_)) if equipped_weapon != null else []
	}


func from_save_dict(data_: Dictionary) -> void:
	var current_hp_ := float(data_.get("current_hp", health_component.max_hp))
	health_component.current_hp = clampf(current_hp_, 0.0, health_component.max_hp)
	health_component.health_changed.emit(health_component.current_hp, health_component.max_hp)

	var position_data_ = data_.get("global_position", {})
	if typeof(position_data_) == TYPE_DICTIONARY:
		global_position = Vector2(
			float(position_data_.get("x", global_position.x)),
			float(position_data_.get("y", global_position.y))
		)


func restore_equipped_weapon_from_save(data_: Dictionary) -> bool:
	var weapon_id_ := StringName(String(data_.get("equipped_weapon_id", "")))
	if weapon_id_.is_empty():
		return false

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		return false

	var weapon_data_ = save_manager_.resolve_weapon_data(weapon_id_) as WeaponData
	if weapon_data_ == null:
		return false

	var weapon_save_data_ := {
		"instance_uid": String(data_.get("equipped_weapon_uid", "")),
		"weapon_id": String(weapon_id_),
		"enhance_level": int(data_.get("equipped_weapon_enhance_level", 0)),
		"temporary_enchants": data_.get("equipped_weapon_temporary_enchants", []),
		"socketed_gems": data_.get("equipped_weapon_socketed_gems", [])
	}
	equip_weapon_instance(WeaponInstanceResource.create_from_save_dict(weapon_data_, weapon_save_data_))
	return true


#region Dash Functions
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
#endregion

#region Helpers
func _instantiate_weapon_controller(weapon_data_: WeaponData) -> WeaponController:
	var weapon_controller_ := weapon_data_.weapon_scene.instantiate() as WeaponController
	assert(weapon_controller_ != null, "WeaponData.weapon_scene must instantiate WeaponController")

	weapon_pivot.add_child(weapon_controller_)
	return weapon_controller_


func _clear_equipped_weapon_controller() -> void:
	if equipped_weapon_controller == null:
		return

	var weapon_controller_parent_ := equipped_weapon_controller.get_parent()
	if weapon_controller_parent_ != null:
		weapon_controller_parent_.remove_child(equipped_weapon_controller)

	equipped_weapon_controller.on_unequipped()
	equipped_weapon_controller.queue_free()
	equipped_weapon_controller = null


func _try_handle_debug_weapon_switch(event_: InputEvent) -> bool:
	if not enable_debug_weapon_switching:
		return false

	var key_event_ := event_ as InputEventKey
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
	var key_event_ := event_ as InputEventKey
	if key_event_ == null or not key_event_.pressed or key_event_.echo:
		return false

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		return false

	if key_event_.physical_keycode == KEY_F5:
		save_manager_.save_game()
		return true

	if key_event_.physical_keycode == KEY_F9:
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
	var key_event_ := event_ as InputEventKey
	if key_event_ == null or not key_event_.pressed or key_event_.echo:
		return false

	if key_event_.physical_keycode == KEY_H:
		_debug_add_inventory_item(debug_inventory_herb_data, 5)
		return true

	if key_event_.physical_keycode == KEY_J:
		_debug_add_inventory_item(debug_inventory_potion_data, 3)
		return true

	if key_event_.physical_keycode == KEY_K:
		_debug_print_inventory()
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
	var safe_amount_ := maxi(amount_, 1)
	recent_pickup_summary = "%s x%d" % [display_name_, safe_amount_]


func _debug_print_inventory() -> void:
	if inventory == null:
		push_warning("[Debug][Inventory] Inventory node is missing")
		return

	inventory.debug_print_contents()


func _update_facing(input_vector_: Vector2) -> void:
	if input_vector_.x < 0.0:
		facing_left = true
	elif input_vector_.x > 0.0:
		facing_left = false
	# Keep the previous facing when input_vector_.x = 0.0

	sprite.flip_h = facing_left
	weapon_pivot.scale.x = -1.0 if facing_left else 1.0


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

	var parent_node_ := get_parent()
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

	var tween_ := create_tween()
	tween_.tween_property(ghost_, "modulate:a", 0.0, 0.2)
	tween_.tween_callback(Callable(ghost_, "queue_free"))


func _get_save_manager():
	var tree_ := get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")
#endregion
