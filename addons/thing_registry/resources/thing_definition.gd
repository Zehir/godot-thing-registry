@tool
class_name ThingDefinition
extends Resource

## Path of an other ThingDefinition
@export_file("*.tres") var parent: String

## Reference to ThingDefinitionModules scripts that could add properties
@export var modules: Array[ThingDefinitionModule] = []

@export_storage var properties: Dictionary[StringName, Variant] = {}




func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if is_instance_valid(modules):
		for module: ThingDefinitionModule in modules:
			properties.append_array(module.get_thing_property_list())
	return properties
