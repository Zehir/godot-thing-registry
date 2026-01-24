@tool
class_name ThingTreeHeaderResource
extends Button

func _init() -> void:
	custom_minimum_size.x = 200.0
	text = "Resource"
	icon = EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons")
