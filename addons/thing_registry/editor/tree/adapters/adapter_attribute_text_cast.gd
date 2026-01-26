@tool
class_name TreeValueAdapterAttributeTextCast
extends TreeValueAdapterAttribute

var _expected_type: Variant.Type

func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_expected_type = header.get_property().type


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	tree_item.set_editable(column_index, true)
	tree_item.set_text_alignment(column_index, HORIZONTAL_ALIGNMENT_LEFT)
	var value: Variant = thing.get_direct(property)
	if value != null:
		tree_item.set_text(column_index, var_to_str(thing.get_direct(property)))
	else:
		tree_item.set_text(column_index, "")


func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	var value: Variant = str_to_var(tree_item.get_text(column_index))
	var value_type: int = typeof(value)
	if value_type == _expected_type:
		thing.set(property, value)
	elif value_type == TYPE_NIL:
		thing.set(property, null)
	else:
		tree_item.set_text(column_index, var_to_str(thing.get_direct(property)))
