@tool
extends EditorPlugin

const ThingsEditor = preload("uid://cbgf26fkyrq4a")

var things_editor: ThingsEditor

var cleanup_callables: Array[Callable] = []

func _enter_tree() -> void:
	things_editor = ThingsEditor.get_scene().instantiate()
	EditorInterface.get_editor_main_screen().add_child(things_editor)
	_make_visible(false)


func _exit_tree() -> void:
	cleanup_callables.reverse()
	for callable in cleanup_callables:
		if is_instance_valid(callable) and callable.is_valid():
			callable.call()
	cleanup_callables.clear()

	if things_editor:
		things_editor.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if things_editor:
		things_editor.visible = visible


func _get_plugin_name():
	return "Things"


func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons")


func _handles(object: Object) -> bool:
	return false
	#return object is ThingRegistry


#func _edit(object: Object) -> void:
	#if object is ThingRegistry:
		#things_editor.filesystem_panel.open_file(object)
