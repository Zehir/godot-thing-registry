@tool
class_name Thing
#extends RefCounted
extends Resource


var external_properties: Dictionary[StringName, Variant] = {}




#var foo: int

@export var _definition: ThingDefinition:
	set(value):
		_definition = value
		if is_instance_valid(_definition):
			_definition.property_list_changed.connect(notify_property_list_changed)
		notify_property_list_changed()


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if is_instance_valid(_definition):
		for property in _definition.get_property_list():
			if not _definition.is_property_external(property.name):
				continue
			var cloned: Dictionary = property.duplicate()
			cloned.usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR #  | PROPERTY_USAGE_SCRIPT_VARIABLE
			properties.append(cloned)

	return properties


func is_property_external(property: StringName) -> bool:
	return is_instance_valid(_definition) and _definition.is_property_external(property)


func _get(property):
	if is_property_external(property):
		return external_properties.get(property)


func _set(property: StringName, value: Variant) -> bool:
	if is_property_external(property):
		external_properties.set(property, value)
		return true
	return false


func _property_can_revert(property: StringName) -> bool:
	if is_property_external(property):
		return _definition.property_can_revert(property)
	return false


func _property_get_revert(property: StringName) -> Variant:
	if is_property_external(property):
		return _definition.property_get_revert(property)
	return null


func _validate_property(property: Dictionary) -> void:
	if is_property_external(property.name):
		if property_can_revert(property.name) and property_get_revert(property.name) == get(property.name):
			property.usage = PROPERTY_USAGE_NONE
