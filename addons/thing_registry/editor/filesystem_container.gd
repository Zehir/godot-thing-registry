@tool
extends VBoxContainer

const Menu = preload("uid://dsju3xwf6tler")

@export var search: LineEdit
@export var tree: Tree
@onready var file_dialog: FileDialog = $FileDialog

var edited_registrys: Array[EditedThingRegistry]
var _current_saving_registry: ThingRegistry = null


#region Opening
func open_file(registry: ThingRegistry) -> void:
	if not is_instance_valid(registry):
		return
	prints("open", registry)
#endregion

#region Closing
func close_file(registry: ThingRegistry) -> void:
	prints("close", registry)


func close_all() -> void:
	pass


func close_others(registry: ThingRegistry) -> void:
	for edited_registry: EditedThingRegistry in edited_registrys.duplicate():
		var file := edited_registry.get_registry()
		if file == edited_registry:
			continue

		close_file(file)
#endregion


#region Saving
func _start_save_as(file: ThingRegistry) -> void:
	file_dialog.title = "Save ThingRegistry As..."
	var path: String = "res://"
	if not file.is_built_in() and not file.resource_path.is_empty():
		path = file.resource_path

	file_dialog.current_path = path
	file_dialog.popup_centered()

	_current_saving_registry = file


func _start_new_graph_creation() -> void:
	file_dialog.title = "New Thing Registry..."
	if file_dialog.current_path.get_extension() != "tres":
		file_dialog.current_path = "%s/new_graph.tres" % file_dialog.current_path.get_base_dir()
	file_dialog.popup_centered()


func _on_file_saved(file: ThingRegistry) -> void:
	var idx: int = edited_registrys.find_custom(EditedThingRegistry.is_registry.bind(file))
	if idx == -1:
		return

	edited_registrys[idx].set_dirty(false)


func _on_unsaved_file_found(file: ThingRegistry) -> void:
	var idx: int = edited_registrys.find_custom(EditedThingRegistry.is_registry.bind(file))
	if idx == -1:
		return

	#file_list.set_item_text(idx, "[unsaved]")
	#file_list.set_item_tooltip(idx, "[unsaved]")
	_start_save_as(file)
#endregion


#region Signals
func _on_menu_action_pressed(action: Menu.Action) -> void:
	match action:
		Menu.Action.FILE_NEW_REGISTRY:
			print("foo")
			pass
	pass # Replace with function body.


func _on_tree_item_selected() -> void:
	pass # Replace with function body.


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	pass # Replace with function body.


func _on_file_dialog_file_selected(path: String) -> void:
	var extension: String = path.get_extension()
	if extension.is_empty():
		if not path.ends_with("."):
			path += "."
		path += "tres"
	elif extension != "tres":
		push_error("Invalid extension for a Thing registry file.")
		return

	var new_registry: ThingRegistry

	if is_instance_valid(_current_saving_registry):
		close_file(_current_saving_registry)
		new_registry = _current_saving_registry
	else:
		new_registry = ThingRegistry.new()

	new_registry.take_over_path(path)
	ResourceSaver.save(new_registry, path)
	open_file(load(path))
	_current_saving_registry = null


func _on_file_dialog_canceled() -> void:
	_current_saving_registry = null


func _on_edited_registry_dirty_changed(new_value: bool, edited_registry: ThingRegistry) -> void:
	var idx := edited_registrys.find(edited_registry)
	if idx == -1:
		return

	#var text := file_list.get_item_text(idx)
	#text = text.trim_suffix("(*)")
	#if new_value == true:
	#	text += "(*)"
	#file_list.set_item_text(idx, text)
#endregion

#region EditedThingRegistry
class EditedThingRegistry extends RefCounted:
	signal dirty_changed(new_value: bool)

	var _registry: ThingRegistry : get = get_registry
	var _dirty: bool = false : set = set_dirty, get = is_unsaved

	static func is_registry(edited_registry: EditedThingRegistry, registry: ThingRegistry) -> bool:
		return edited_registry.get_registry() == registry


	func _init(registry: ThingRegistry) -> void:
		_registry = registry
		_registry.changed.connect(set_dirty.bind(true))


	func set_dirty(value: bool) -> void:
		var prev_value: bool = _dirty
		_dirty = value
		if prev_value != _dirty:
			dirty_changed.emit(_dirty)


	func is_unsaved() -> bool:
		return _dirty


	func get_registry() -> ThingRegistry:
		return _registry
#endregion
