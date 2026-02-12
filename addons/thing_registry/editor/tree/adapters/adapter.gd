@tool
@abstract
class_name TreeValueAdapter
extends RefCounted

var _header: ThingTreeColumn


func _init(header: ThingTreeColumn) -> void:
	_header = header



func tree_item_callv(method: StringName, tree_item: ThingTreeItem, args: Array = []) -> Variant:
	if has_method(method):
		return (get(method) as Callable).bindv(args).call(tree_item)
	return null


func set_disabled(tree_item: ThingTreeItem, column_index: int) -> void:
	tree_item.set_custom_bg_color(column_index, Color.DIM_GRAY)
	tree_item.set_editable(column_index, false)
	tree_item.set_text(column_index, "")


@abstract
func _update_column(tree_item: ThingTreeItem, column_index: int) -> void


func update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	_update_column(tree_item, column_index)


func notify_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	_on_edited(tree_item, column_index)
	update_column(tree_item, column_index)


@warning_ignore("unused_parameter")
func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	pass


func notify_button_clicked(tree_item: ThingTreeItem, column_index: int, id: int, mouse_button_index: int):
	_on_button_clicked(tree_item, column_index, id, mouse_button_index)


@warning_ignore("unused_parameter")
func _on_button_clicked(tree_item: ThingTreeItem, column_index: int, id: int, mouse_button_index: int):
	pass


#region Drag and drop
func get_drag_data(tree_item: ThingTreeItem, column_index: int) -> Variant:
	return _get_drag_data(tree_item, column_index)


@warning_ignore("unused_parameter")
func _get_drag_data(tree_item: ThingTreeItem, column_index: int) -> Variant:
	return null


func can_drop_data(tree_item: ThingTreeItem, column_index: int, data: Variant) -> bool:
	return _can_drop_data(tree_item, column_index, data)


@warning_ignore("unused_parameter")
func _can_drop_data(tree_item: ThingTreeItem, column_index: int, data: Variant) -> bool:
	return false


func notify_drop_data(tree_item: ThingTreeItem, column_index: int, section: int, data: Variant):
	_on_drop_data(tree_item, column_index, section, data)


@warning_ignore("unused_parameter")
func _on_drop_data(tree_item: ThingTreeItem, column_index: int, section: int, data: Variant) -> void:
	pass
#endregion

#region Icon finder
func _get_icon(property: Dictionary) -> Texture2D:
	if property.type < TYPE_MAX:
		if property.type == TYPE_OBJECT:
			return _get_class_icon(property.hint_string)
		var theme : Theme = EditorInterface.get_editor_theme()
		return theme.get_icon(type_string(property.type), &"EditorIcons")
	return _get_class_icon(&"Object")


func _get_class_icon(name: StringName) -> Texture2D:
	if ClassDB.class_exists(name):
		var theme: Theme = EditorInterface.get_editor_theme()
		if theme.has_icon(name, &"EditorIcons"):
			return theme.get_icon(name, &"EditorIcons")
		return _get_class_icon(ClassDB.get_parent_class(name))

	if Engine.is_editor_hint():
		for script: Dictionary in ProjectSettings.get_global_class_list():
			if script.class != name:
				continue
			if not script.icon.is_empty() and ResourceLoader.exists(script.icon):
				return load(script.icon)
			return _get_class_icon(script.base)
	return _get_class_icon(&"Object")


func is_valid_typed_value(property: Dictionary, value: Variant) -> bool:
	# Null or Unknown type, we guess it's valid
	if value == null or property.type >= TYPE_MAX:
		return true
	if property.type == TYPE_OBJECT:
		return _is_valid_resource_type(property.hint_string, value)
	return typeof(value) == property.type


func _is_valid_resource_type(expected_type: StringName, value: Variant) -> bool:
	if value == null:
		return true

	if not value is Resource:
		return false

	var resource: Resource = value as Resource
	var script: Variant = resource.get_script()
	if script is GDScript:
		return is_class_is_subclass_of(script.get_global_name(), expected_type)
	return is_class_is_subclass_of(resource.get_class(), expected_type)


func is_class_is_subclass_of(name: StringName, parent_class: StringName) -> bool:
	if name == parent_class:
		return true

	if ClassDB.class_exists(name):
		var parent: StringName = ClassDB.get_parent_class(name)
		if not parent.is_empty():
			return is_class_is_subclass_of(parent, parent_class)

	for script: Dictionary in ProjectSettings.get_global_class_list():
		if script.class != name:
			continue
		if not script.base.is_empty():
			return is_class_is_subclass_of(script.base, parent_class)

	return false
#endregion
