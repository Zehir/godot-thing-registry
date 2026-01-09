@tool
class_name ThingResource
extends ThingItem


@export var type: String

var stack_count: int

@export var number_count = 3:
	set(value):
		number_count = value
		notify_property_list_changed()


func _get_property_list() -> Array:
	var properties = []

	for i in range(number_count):
		properties.append({
			"name": "number_%d" % i,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "ZERO,ONE,TWO,THREE,FOUR,FIVE",
			"usage": PROPERTY_USAGE_NONE,
		})

	return properties


func is_property_external(property: StringName) -> bool:
	return (property.begins_with("number_") and property != &"number_count") or property == "stack_count"


func _property_can_revert(property: StringName) -> bool:
	return property.begins_with("number_")


func _property_get_revert(_property: StringName) -> Variant:
	return 0
