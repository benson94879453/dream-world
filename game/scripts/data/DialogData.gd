class_name DialogData
extends Resource

const DialogNodeDataResource = preload("res://game/scripts/data/DialogNodeData.gd")

enum NodeType {
	TEXT,
	CHOICE,
	END
}

@export var dialog_id: StringName = &""
@export var nodes: Array[DialogNodeDataResource] = []
@export var start_node_id: StringName = &""

#region Public
func get_node(node_id_: StringName) -> DialogNodeDataResource:
	for node_ in nodes:
		if node_.node_id == node_id_:
			return node_
	return null
#endregion
