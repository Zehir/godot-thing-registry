@tool
class_name ThingModuleItem
extends ThingModule

@export var test_property: String

const PROPERTY_NAME = &"name"
const PROPERTY_ICON = &"icon"

func _get_display_name() -> String:
	return "Item"


func _get_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("ItemList", "EditorIcons")


func _get_description() -> String:
	return "Properties for inventory system."


func _get_thing_property_list() -> Array[Dictionary]:
	return [
		make_property(PROPERTY_NAME, TYPE_STRING),
		make_resource_property(PROPERTY_ICON, "Texture2D")
	]


func _thing_property_get_revert(property: StringName, _thing: Thing) -> Variant:
	if property == PROPERTY_NAME:
		return ""
	return null
