@tool
@abstract
class_name ThingDefinitionModule
extends Resource


@abstract
func get_thing_property_list() -> Array[Dictionary]


func make_property(name: StringName, type: Variant.Type, hint: PropertyHint = PROPERTY_HINT_NONE, hint_string: String = "", usage: PropertyUsageFlags = 6) -> Dictionary:
	return { "name": name, "type": type, "hint": hint, "hint_string": hint_string, "usage": usage }


func make_resource_property(name: StringName, resource_type: String) -> Dictionary:
	return make_property(name, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, resource_type)
