@tool
class_name ThingModuleItem
extends ThingModule

@export var test_property: String

func get_module_name() -> StringName:
	return &"item"


func get_thing_property_list() -> Array[Dictionary]:
	return [
		make_property(&"name", TYPE_STRING),
		make_resource_property(&"icon", "Texture2D")
	]



func _thing_property_can_revert(property: StringName) -> bool:
	return property == &"name"



func _thing_property_get_revert(property: StringName, _thing: Thing) -> Variant:
	match property:
		&"name":
			return ""
	return null
