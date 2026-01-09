@tool
class_name ThingItem
extends ThingDefinition

@export var name: String

var foo: int

#
#
#func _get_property_list() -> Array[Dictionary]:
	#prints("_get_property_list", "ThingItem")
	#return []
#
#
#func _validate_property(property: Dictionary) -> void:
	#prints("_validate_property", property)
