@tool
class_name ThingModulePrice
extends ThingModule

@export var currency: Thing:
	set(value):
		currency = value
		notify_property_list_changed()


func _get_display_name() -> String:
	if is_instance_valid(currency):
		return "Price (%s)" % currency.get_display_name()
	return "Price"


func _get_icon() -> Texture2D:
	if is_instance_valid(currency):
		var icon: Texture2D = currency.get("item:icon")
		if is_instance_valid(icon):
			return icon
	return EditorInterface.get_editor_theme().get_icon("ItemList", "EditorIcons")


func _get_description() -> String:
	return "Properties for inventory system."


func _allow_duplicate() -> bool:
	return true


func _get_instance_name() -> StringName:
	if is_instance_valid(currency):
		return "price_%s" % ResourceUID.path_to_uid(currency.resource_path).trim_prefix("uid://")
	return &"price"


func _get_thing_property_list() -> Array[Dictionary]:
	return [make_property(&"value", TYPE_FLOAT)]


func _thing_property_get_revert(_property: StringName) -> Variant:
	return 0.0
