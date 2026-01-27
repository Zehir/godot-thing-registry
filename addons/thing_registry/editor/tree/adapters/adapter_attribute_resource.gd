@tool
class_name TreeValueAdapterAttributeResource
extends TreeValueAdapterAttribute

static var known_icons: Dictionary[StringName, Texture2D] = {}



func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_header.custom_minimum_size.x = 20.0

	var property: Dictionary = header.get_property()
	prints("property", property.type, property)


	if not known_icons.has(property.name):
		known_icons.set(property.name, _get_icon())
	_header.icon = known_icons.get(property.name)


	#var picker := EditorResourcePicker.new()
	#picker.base_type = property.hint_string
	#prints("test", picker.get_allowed_types(), picker.edited_resource)
	#_header.add_child(picker)


	var fake_script: GDScript = GDScript.new()
	fake_script.source_code = "@tool\n@abstract\nextends %s" % property.hint_string
	if fake_script.reload() == OK:

		prints(fake_script.can_instantiate(), fake_script.is_tool(), fake_script.get_base_script().resource_path)

	#TODO remove icon system and use this to get icons for custom resources
	prints(ProjectSettings.get_global_class_list())


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	tree_item.set_editable(column_index, false)

	#var value: Variant = thing.get_direct(property, null)
	#if value is Texture2D:
		#tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_ICON)
		#tree_item.set_icon(column_index, value)
		#tree_item.set_icon_max_width(column_index, 16)
	#else:
		#tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_STRING)
		#tree_item.set_text(column_index, "")

#
#func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	#var thing: Thing = tree_item.get_thing()
	#var property: StringName = get_property_path()
	#thing.set(property, tree_item.get_text(column_index))



#region Icon finder
# This is a complex function just to get the icon but sadly the ClassDB does not support GDScript classes
# See:
func _get_icon() -> Texture2D:
	var property: Dictionary = _header.get_property()
	if ClassDB.class_exists(property.hint_string):
		return _get_class_icon(property.hint_string)
	elif property.has("script"):
		var script: Variant = property.get("script")
		if script is Script:
			while is_instance_valid(script):
				var icon_path = _extract_icon_path(script.source_code)
				if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
					return load(icon_path)
				script = script.get_base_script()
			return _get_class_icon(property.get("script").get_instance_base_type())
	return _get_class_icon(&"Object")


func _get_class_icon(name: StringName) -> Texture2D:
	var theme: Theme = EditorInterface.get_editor_theme()
	while not name.is_empty():
		if theme.has_icon(name, &"EditorIcons"):
			return theme.get_icon(name, &"EditorIcons")
		name = ClassDB.get_parent_class(name)
	return theme.get_icon(&"Object", &"EditorIcons")


func _extract_icon_path(script_source: String) -> String:
	var regex = RegEx.create_from_string(r'^\s*.*?@icon\("([^"]+)"\)')
	for line in script_source.split("\n"):
		var match = regex.search(line)
		if match:
			return match.get_string(1)
	return ""
#endregion
