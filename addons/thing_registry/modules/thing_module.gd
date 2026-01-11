@tool
@abstract
class_name ThingModule
extends Resource

@abstract
func get_module_name() -> StringName


@abstract
func get_thing_property_list() -> Array[Dictionary]



func make_property(name: StringName, type: Variant.Type, hint: PropertyHint = PROPERTY_HINT_NONE, hint_string: String = "", usage: PropertyUsageFlags = 6 as PropertyUsageFlags) -> Dictionary:
	return {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
		"usage": usage
	}


func make_resource_property(name: StringName, resource_type: String) -> Dictionary:
	return make_property(name, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, resource_type)



func thing_property_can_revert(property: StringName, _thing: Thing) -> bool:
	return _thing_property_can_revert(property)


func thing_property_get_revert(property: StringName, thing: Thing) -> Variant:
	if not thing._parent is Thing:
		return _thing_property_get_revert(property, thing)

	var full_name: StringName = StringName(get_module_name() + "/" + property)
	if thing._parent.properties.has(full_name):
		return thing._parent.properties.get(full_name)

	return thing_property_get_revert(property, thing._parent)



@warning_ignore("unused_parameter")
func _thing_property_can_revert(property: StringName) -> bool:
	return false


@warning_ignore("unused_parameter")
func _thing_property_get_revert(property: StringName, thing: Thing) -> Variant:
	return null
