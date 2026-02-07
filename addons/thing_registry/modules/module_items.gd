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
	var list: Array[Dictionary] = [
		make_property(PROPERTY_NAME, TYPE_STRING),
		make_property("bool", TYPE_BOOL),
		make_property("color", TYPE_COLOR),
		make_resource_property(PROPERTY_ICON, "Texture2D"),
		make_resource_property("Resource", "Resource"),
		make_resource_property("ThingModule", "ThingModule"),
	]
	#for i in range(TYPE_MAX):
		#if i in INVALID_TYPES or i == TYPE_OBJECT:
			#continue
		#list.append(make_property(type_string(i), i))
	return list



func _thing_property_get_revert(property: StringName) -> Variant:
	if property == PROPERTY_NAME:
		return ""
	return null
