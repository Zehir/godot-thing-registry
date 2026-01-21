@tool
class_name ThingModulePrice
extends ThingModule

@export var currency: Thing:
	set(value):
		currency = value
		notify_property_list_changed()


func _get_module_name() -> StringName:
	return &"price"


func _allow_duplicate() -> bool:
	return true


func _get_instance_name() -> String:
	if is_instance_valid(currency) and currency.has_module(&"item"):
		#TODO use UID here and display the name in the editor
		return currency.get("item/name").to_snake_case()
	return super()


func _get_module_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("ItemList", "EditorIcons")


func _get_module_description() -> String:
	return "Properties for inventory system."


func _get_thing_property_list() -> Array[Dictionary]:
	return [make_property(&"value", TYPE_FLOAT)]


func _thing_property_can_revert(_property: StringName) -> bool:
	return true


func _thing_property_get_revert(_property: StringName, _thing: Thing) -> Variant:
	return 0.0
