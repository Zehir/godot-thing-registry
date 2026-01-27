@tool
class_name TreeValueAdapterAttributeTexture2D
extends TreeValueAdapterAttribute


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_header.custom_minimum_size.x = 20.0


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	tree_item.set_editable(column_index, false)

	var value: Variant = thing.get_direct(property, null)
	if value is Texture2D:
		tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_ICON)
		tree_item.set_icon(column_index, value)
		tree_item.set_icon_max_width(column_index, 16)
	else:
		tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_STRING)
		tree_item.set_text(column_index, "")

#
#func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	#var thing: Thing = tree_item.get_thing()
	#var property: StringName = get_property_path()
	#thing.set(property, tree_item.get_text(column_index))
