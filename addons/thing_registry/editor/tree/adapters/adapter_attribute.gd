@tool
@abstract
class_name TreeValueAdapterAttribute
extends TreeValueAdapter


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)

	_header.custom_minimum_size.x = 200.0
	var property: Dictionary = _header.get_property()
	_header.text = property.name.capitalize()


func update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	if not has_module(tree_item):
		set_disabled(tree_item, column_index)
		return
	super(tree_item, column_index)


func has_module(tree_item: ThingTreeItem) -> bool:
	return tree_item.get_thing().has_module(_header.get_module().get_instance_name())


func get_property_path() -> StringName:
	return _header.get_module().get_property_full_name(_header.get_property().name)
