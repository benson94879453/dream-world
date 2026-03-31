extends Node

signal test_mode_changed(enabled_: bool)
signal test_results_updated()

const DEFAULT_SAMPLE_COUNT: int = 100

var test_mode_enabled: bool = false
var probability_sample_count: int = DEFAULT_SAMPLE_COUNT
var test_stats: Dictionary = {}
var elemental_result: Dictionary = {}
var shield_result: Dictionary = {}

func _ready() -> void:
	reset_all_results()


func set_test_mode(enabled_: bool) -> void:
	if test_mode_enabled == enabled_:
		return

	test_mode_enabled = enabled_
	if test_mode_enabled:
		reset_all_results()
	test_mode_changed.emit(test_mode_enabled)


func is_test_mode_enabled() -> bool:
	return test_mode_enabled


func reset_all_results() -> void:
	reset_stats()
	clear_elemental_result()
	clear_shield_result()
	test_results_updated.emit()


func record_endless_blade_result(triggered_: bool) -> void:
	if not test_mode_enabled:
		return

	if triggered_:
		test_stats["endless_blade"]["triggers"] += 1
	test_stats["endless_blade"]["total"] += 1
	test_results_updated.emit()


func record_double_strike_result(triggered_: bool) -> void:
	if not test_mode_enabled:
		return

	if triggered_:
		test_stats["double_strike"]["triggers"] += 1
	test_stats["double_strike"]["total"] += 1
	test_results_updated.emit()


func simulate_probability_test(endless_chance_: float, double_strike_chance_: float, sample_count_: int = DEFAULT_SAMPLE_COUNT) -> void:
	if not test_mode_enabled:
		return

	reset_stats()
	probability_sample_count = maxi(sample_count_, 1)

	var rng_: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_.randomize()
	for _sample_index in range(probability_sample_count):
		record_endless_blade_result(rng_.randf() <= minf(maxf(endless_chance_, 0.0), 1.0))
		record_double_strike_result(rng_.randf() <= minf(maxf(double_strike_chance_, 0.0), 1.0))


func set_elemental_result(base_damage_: float, elemental_damage_: float, resonance_damage_: float) -> void:
	elemental_result = {
		"base_damage": base_damage_,
		"elemental_damage": elemental_damage_,
		"resonance_damage": resonance_damage_,
		"elemental_bonus_pct": _calculate_bonus_pct(base_damage_, elemental_damage_),
		"resonance_bonus_pct": _calculate_bonus_pct(elemental_damage_, resonance_damage_)
	}
	test_results_updated.emit()


func clear_elemental_result() -> void:
	elemental_result = {
		"base_damage": 0.0,
		"elemental_damage": 0.0,
		"resonance_damage": 0.0,
		"elemental_bonus_pct": 0.0,
		"resonance_bonus_pct": 0.0
	}


func set_shield_result(
	initial_shield_: float,
	initial_hp_: float,
	first_hit_shield_: float,
	first_hit_hp_: float,
	final_shield_: float,
	final_hp_: float,
	hit_damage_: float,
	passed_: bool
) -> void:
	shield_result = {
		"initial_shield": initial_shield_,
		"initial_hp": initial_hp_,
		"first_hit_shield": first_hit_shield_,
		"first_hit_hp": first_hit_hp_,
		"final_shield": final_shield_,
		"final_hp": final_hp_,
		"hit_damage": hit_damage_,
		"passed": passed_
	}
	test_results_updated.emit()


func clear_shield_result() -> void:
	shield_result = {
		"initial_shield": 0.0,
		"initial_hp": 0.0,
		"first_hit_shield": 0.0,
		"first_hit_hp": 0.0,
		"final_shield": 0.0,
		"final_hp": 0.0,
		"hit_damage": 0.0,
		"passed": false
	}


func reset_stats() -> void:
	test_stats = {
		"endless_blade": {"triggers": 0, "total": 0},
		"double_strike": {"triggers": 0, "total": 0}
	}


func get_endless_blade_rate() -> float:
	return _get_trigger_rate("endless_blade")


func get_double_strike_rate() -> float:
	return _get_trigger_rate("double_strike")


func get_stat_entry(stat_key_: String) -> Dictionary:
	return test_stats.get(stat_key_, {"triggers": 0, "total": 0})


func _get_trigger_rate(stat_key_: String) -> float:
	var stat_entry_: Dictionary = get_stat_entry(stat_key_)
	var total_: int = int(stat_entry_.get("total", 0))
	if total_ <= 0:
		return 0.0
	return float(stat_entry_.get("triggers", 0)) / float(total_)


func _calculate_bonus_pct(base_value_: float, boosted_value_: float) -> float:
	if is_zero_approx(base_value_):
		return 0.0
	return (boosted_value_ / base_value_) - 1.0
