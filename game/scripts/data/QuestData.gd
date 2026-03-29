class_name QuestData
extends Resource

enum QuestType {
	KILL,
	COLLECT,
	TALK,
	DELIVER
}

enum QuestStatus {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	TURNED_IN
}

@export var quest_id: StringName = &""
@export var quest_name: String = ""
@export_multiline var quest_description: String = ""
@export var quest_type: QuestType = QuestType.KILL

@export var target_enemy_id: StringName = &""
@export var target_item_id: StringName = &""
@export var target_npc_id: StringName = &""
@export var target_amount: int = 1

@export var reward_gold: int = 0
@export var reward_item_id: StringName = &""
@export var reward_item_amount: int = 0
@export var reward_weapon_id: StringName = &""

@export var prerequisite_quest_id: StringName = &""
@export var minimum_level: int = 1
