@tool
class_name TreeValueAdapterMissing
extends TreeValueAdapter


func _init(header: ThingTreeColumn) -> void:
	super(header)

	_header.custom_minimum_size.x = 50.0
	_header.text = "Missing Adapter"
	_header.icon = EditorInterface.get_editor_theme().get_icon("StatusError", "EditorIcons")


@warning_ignore("unused_parameter")
func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	pass
