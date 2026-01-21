@tool
class_name ThingTreeHeaderAttribute
extends Button

enum SortMethod {
	NONE,
	DESCENDING,
	ASCENDING,
}


var _property_path: StringName = &""
var property_path: StringName: get = get_property_path, set = set_property_path

var sort: SortMethod = SortMethod.NONE



func _init(property: StringName) -> void:
	set_property_path(property)
	custom_minimum_size.x = 200.0


func get_property_path() -> StringName:
	return _property_path


func set_property_path(property: StringName) -> void:
	text = property.capitalize()
	_property_path = property
