@tool
class_name ThingModuleItem
extends ThingModule

@export var test_property: String


func _get_module_instance_id():
	return &"item"


func _get_module_name() -> StringName:
	return &"item"


func _get_module_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("ItemList", "EditorIcons")


func _get_module_description() -> String:
	return "Properties for inventory system."


func _get_thing_property_list() -> Array[Dictionary]:
	return [
		make_property(&"name", TYPE_STRING),
		make_resource_property(&"icon", "Texture2D")
	]


func _thing_property_can_revert(property: StringName) -> bool:
	return property == &"name"


func _thing_property_get_revert(property: StringName, _thing: Thing) -> Variant:
	if property == &"name":
		return ""
	return null
