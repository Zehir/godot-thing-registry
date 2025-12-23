@tool
extends EditorPlugin

const MAIN_PANEL = preload("uid://bybjt46vqisvu")

var main_panel_instance


func _enter_tree() -> void:
	main_panel_instance = MAIN_PANEL.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)


func _exit_tree() -> void:
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return "Things"


func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return EditorInterface.get_editor_theme().get_icon("Object", "EditorIcons")
