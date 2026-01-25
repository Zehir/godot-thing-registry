@tool
@abstract
class_name ThingModule
extends Resource

#region Module info
@abstract
func _get_display_name() -> String


func get_display_name() -> String:
	return _get_display_name()


@abstract
func _get_icon() -> Texture2D


func get_icon() -> Texture2D:
	return _get_icon()


@abstract
func _get_description() -> String


func get_description() -> String:
	return _get_description()
#endregion


#region Duplicate module
func _allow_duplicate() -> bool:
	return false


func _get_instance_name() -> StringName:
	return StringName(_get_display_name().to_snake_case())


func get_instance_name() -> StringName:
	return _get_instance_name()
#endregion


#region Properties
@abstract
func _get_thing_property_list() -> Array[Dictionary]


func get_thing_property_list() -> Array[Dictionary]:
	return _get_thing_property_list()


func get_property_fullname(property: StringName) -> StringName:
	return StringName("%s:%s" % [_get_instance_name(), property])


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


func thing_property_get_revert(property: StringName, thing: Thing) -> Variant:
	if not thing.parent is Thing:
		return _thing_property_get_revert(property, thing)

	var full_name: StringName = get_property_fullname(property)
	if thing.parent.properties.has(full_name):
		return thing.parent.properties.get(full_name)

	return thing_property_get_revert(property, thing.parent)


@warning_ignore("unused_parameter")
func _thing_property_get_revert(property: StringName, thing: Thing) -> Variant:
	return null
#endregion
