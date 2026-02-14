@tool
@abstract
class_name ThingModule
extends Resource

signal thing_property_list_changed

const INVALID_TYPES: Array[Variant.Type] = [
	TYPE_NIL,
	TYPE_NODE_PATH,
	TYPE_RID,
	TYPE_CALLABLE,
	TYPE_SIGNAL,
]

#TODO remove _thing_property_list_invalid ?
var _thing_property_list_invalid: bool = true
var _thing_property_list: Array[Dictionary] = []


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


#region Properties helper
func make_property(name: StringName, type: Variant.Type, hint: PropertyHint = PROPERTY_HINT_NONE, hint_string: String = "", usage: PropertyUsageFlags = PROPERTY_USAGE_DEFAULT, extra_properties: Dictionary[String, Variant] = {}) -> Dictionary:
	if type in INVALID_TYPES:
		push_error("Invalid type '%s' provided for property '%s', switching type to string." % [type_string(type), name])
		type = TYPE_STRING
	var property: Dictionary = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
		"usage": usage
	}
	for property_name: String in extra_properties.keys():
		property.set(property_name, extra_properties.get(property_name))
	return property


func make_resource_property(name: StringName, resource_type: String = "Resource", usage: PropertyUsageFlags = PROPERTY_USAGE_DEFAULT) -> Dictionary:
	return make_property(name, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, resource_type, usage)
#endregion


#region Properties
func notify_thing_property_list_changed() -> void:
	thing_property_list_changed.emit()
	_thing_property_list_invalid = true


@abstract
func _get_thing_property_list() -> Array[Dictionary]


## Do not edit the returned array, if you need to please make a duplicate_deep call on it
func get_thing_property_list() -> Array[Dictionary]:
	if _thing_property_list_invalid:
		_thing_property_list = _get_thing_property_list()
		_thing_property_list_invalid = false
	return _thing_property_list


func has_thing_property(property: StringName) -> bool:
	for thing_property in get_thing_property_list():
		if thing_property.name == property:
			return true
	return false


func get_property_full_name(property: StringName) -> StringName:
	return StringName("".join([_get_instance_name(), Thing.SEPERATOR, property]))


func thing_property_get_revert(property: StringName) -> Variant:
	return _thing_property_get_revert(property)


@warning_ignore("unused_parameter")
func _thing_property_get_revert(property: StringName) -> Variant:
	return null
#endregion
