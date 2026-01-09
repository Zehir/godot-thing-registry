@tool
class_name ThingDefinitionModuleItem
extends ThingDefinitionModule


func get_thing_property_list() -> Array[Dictionary]:
	return [
		make_property(&"name", TYPE_STRING),
		make_resource_property(&"icon", "Texture2D")
	]
