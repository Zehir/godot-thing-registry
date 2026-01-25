@tool
@abstract
class_name TreeValueAdapterAttribute
extends TreeValueAdapter


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)

	_header.custom_minimum_size.x = 200.0
	var property: Dictionary = _header.get_property()
	_header.icon = EditorInterface.get_editor_theme().get_icon(type_string(property.type), "EditorIcons")
	_header.text = property.name.capitalize()


func get_property_path() -> StringName:
	return _header.get_module().get_property_fullname(_header.get_property().name)
