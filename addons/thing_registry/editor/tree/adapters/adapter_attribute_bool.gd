@tool
class_name TreeValueAdapterAttributeBool
extends TreeValueAdapterAttribute


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	tree_item.set_editable(column_index, true)
	tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_CHECK)
	var value: Variant = tree_item.get_thing().get_self(get_property_path())
	if value is bool:
		tree_item.set_checked(column_index, tree_item.get_thing().get_self(get_property_path()))
	else:
		tree_item.set_checked(column_index, false)


func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	tree_item.get_thing().set(get_property_path(), tree_item.is_checked(column_index))
