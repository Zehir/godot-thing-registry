@tool
class_name ThingTreeColumnAttribute
extends Button

enum SortMethod {
	NONE,
	DESCENDING,
	ASCENDING,
}


var sort: SortMethod = SortMethod.NONE

var _module: ThingModule
# The same as _get_property_list()
var _property: Dictionary

func _init(module: ThingModule, property: Dictionary) -> void:
	_module = module
	_property = property

	custom_minimum_size.x = 200.0
	icon = EditorInterface.get_editor_theme().get_icon(type_string(_property.type), "EditorIcons")
	text = _property.name.capitalize()


func get_property_path() -> StringName:
	return _module.get_property_fullname(_property.name)
