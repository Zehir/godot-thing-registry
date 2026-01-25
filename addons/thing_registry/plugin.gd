@tool
extends EditorPlugin

var things_editor: CanvasItem

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	# Main panel
	things_editor = load("uid://bybjt46vqisvu").instantiate()
	EditorInterface.get_editor_main_screen().add_child(things_editor)
	tree_exiting.connect(things_editor.queue_free, CONNECT_ONE_SHOT)
	things_editor.hide()

	# Inspector plugin
	var inspector_plugin = load("uid://cekcax7tk6g3n").new()
	add_inspector_plugin(inspector_plugin)
	tree_exiting.connect(remove_inspector_plugin.bind(inspector_plugin), CONNECT_ONE_SHOT)


func _has_main_screen():
	return true


func _make_visible(visible):
	if is_instance_valid(things_editor):
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
