class_name DialogNodeData
extends Resource

const DialogChoiceDataResource = preload("res://game/scripts/data/DialogChoiceData.gd")

@export var node_id: StringName = &""
@export_enum("Text", "Choice", "End") var node_type: int = 0
@export var speaker_name: String = ""
@export var text: String = ""
@export var next_node_id: StringName = &""
@export var choices: Array[DialogChoiceDataResource] = []
@export var set_flags: Array[StringName] = []
@export var require_flags: Array[StringName] = []
