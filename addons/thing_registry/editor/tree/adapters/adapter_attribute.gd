@tool
@abstract
class_name TreeValueAdapterAttribute
extends TreeValueAdapter


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)

	_header.custom_minimum_size.x = 200.0
	var property: Dictionary = _header.get_property()
	_header.icon = _get_icon(property)
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


func _can_drop_data(tree_item: ThingTreeItem, _column_index: int, data: Variant) -> bool:
	var tree: ThingTree = tree_item.get_tree()
	tree.drop_mode_flags = Tree.DROP_MODE_ON_ITEM
	return is_valid_typed_value(_header.get_property(), _get_dropped_value(data))


func _on_drop_data(tree_item: ThingTreeItem, _column_index: int, _section: int, data: Variant) -> void:
	var value: Variant = _get_dropped_value(data)
	if is_valid_typed_value(_header.get_property(), value):
		tree_item.get_thing().set(get_property_path(), value)


func _get_drag_data(tree_item: ThingTreeItem, column_index: int) -> Variant:
	var value: Variant = tree_item.get_thing().get(get_property_path())
	if value == null:
		return null

	var text: String = tree_item.get_text(column_index)
	if text.is_empty():
		if value is Resource:
			text = value.resource_name
			if text.is_empty():
				text = value.resource_path
	if text.is_empty():
		return null

	var icon: Texture2D = tree_item.get_icon(column_index)
	if not is_instance_valid(icon):
		icon = EditorInterface.get_editor_theme().get_icon(type_string(typeof(value)), "EditorIcons")
	if not is_instance_valid(icon):
		icon = _header.icon

	tree_item.set_drag_preview(
		text,
		icon,
	)

	return {
		"type": "thing_property",
		"value": value,
		"from_tree_item": tree_item,
		"from_column": column_index,
	}


func _get_dropped_value(data: Variant) -> Variant:
	if data is Dictionary:
		match data.get("type"):
			"files":
				if typeof(data.get("files")) != TYPE_PACKED_STRING_ARRAY:
					return
				var files: PackedStringArray = data.get("files")
				if files.size() != 1:
					return
				if not ResourceLoader.exists(files[0], "Resource"):
					return
				return load(files[0])
			"thing_property":
				return data.get("value")
	return data
