@tool
class_name TreeValueAdapterAttributeString
extends TreeValueAdapterAttribute


func update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	if not has_module(tree_item):
		set_disabled(tree_item, column_index)
		return

	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()

	tree_item.set_editable(column_index, true)
	tree_item.set_text_alignment(column_index, HORIZONTAL_ALIGNMENT_LEFT)
	tree_item.set_text(column_index, thing.get_direct(property, ""))


func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	thing.set(property, tree_item.get_text(column_index))
