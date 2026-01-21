@tool
@abstract
class_name ThingModule
extends Resource


@abstract
func _get_module_name() -> StringName


func get_module_name() -> StringName:
	return _get_module_name()


func _allow_duplicate() -> bool:
	return false


func _get_instance_name() -> String:
	return "default"


@abstract
func _get_module_icon() -> Texture2D


func get_module_icon() -> Texture2D:
	return _get_module_icon()


@abstract
func _get_module_description() -> String


func get_module_description() -> String:
	return _get_module_description()


@abstract
func _get_thing_property_list() -> Array[Dictionary]


func get_thing_property_list() -> Array[Dictionary]:
	return _get_thing_property_list()


func make_property(name: StringName, type: Variant.Type, hint: PropertyHint = PROPERTY_HINT_NONE, hint_string: String = "", usage: PropertyUsageFlags = 6 as PropertyUsageFlags) -> Dictionary:

	if _allow_duplicate():
		name = &"%s/%s" % [_get_instance_name(), name]
	# TODO change usage to editor for property name serialization
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
	if not thing.parent is Thing:
		return _thing_property_get_revert(property, thing)

	var full_name: StringName = StringName(get_module_name() + "/" + property)
	if thing.parent.properties.has(full_name):
		return thing.parent.properties.get(full_name)

	return thing_property_get_revert(property, thing.parent)



@warning_ignore("unused_parameter")
func _thing_property_can_revert(property: StringName) -> bool:
	return false


@warning_ignore("unused_parameter")
func _thing_property_get_revert(property: StringName, thing: Thing) -> Variant:
	return null
