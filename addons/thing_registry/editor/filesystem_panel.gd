@tool
extends VBoxContainer


signal registry_selected(registry: EditedThingRegistry)
signal thing_class_selected(script: GDScript)


const Menu = preload("uid://dsju3xwf6tler")

@export var search: LineEdit
@export var tree: Tree
@onready var file_dialog: FileDialog = $FileDialog

var _current_saving_registry: ThingRegistry = null
var _root_item: TreeItem


## Tree columns indexes
enum TC {
	NAME = 0
}


#region Virtual methods
func _enter_tree() -> void:
	if is_part_of_edited_scene():
		return

	search.right_icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")
	_root_item = tree.create_item()

	open_file.call_deferred(load("uid://d16rn65mugjfk"))
#endregion


#region Signals
func _on_menu_action_pressed(action: Menu.Action) -> void:
	match action:
		Menu.Action.FILE_NEW_THING:
			pass
		Menu.Action.FILE_NEW_REGISTRY:
			_start_new_registry_creation()
		Menu.Action.FILE_OPEN:
			EditorInterface.popup_quick_open(open_file_from_path, ["ThingRegistry"])
		Menu.Action.FILE_RELOAD:
			for child: TreeItem in _root_item.get_children():
				var metadata = child.get_metadata(TC.NAME)
				if metadata is EditedThingRegistry:
					var registry = metadata.get_registry()
					close_file(registry)
					open_file(registry)
		Menu.Action.FILE_SAVE:
			var selected_registry: EditedThingRegistry = get_selected_registry()
			if is_instance_valid(selected_registry):
				ResourceSaver.save(selected_registry.get_registry())
				_on_file_saved(selected_registry.get_registry())
			EditorInterface.save_all_scenes()
		Menu.Action.FILE_SAVE_ALL:
			EditorInterface.save_all_scenes()
		Menu.Action.FILE_SHOW_IN_FILESYSTEM:
			var selected_registry: EditedThingRegistry = get_selected_registry()
			if is_instance_valid(selected_registry):
				EditorInterface.get_file_system_dock().navigate_to_path(selected_registry.get_registry().resource_path)
		Menu.Action.FILE_CLOSE:
			var selected_registry: EditedThingRegistry = get_selected_registry()
			if is_instance_valid(selected_registry):
				close_file(selected_registry.get_registry())
		Menu.Action.FILE_CLOSE_ALL:
			close_all()
		Menu.Action.FILE_CLOSE_OTHER:
			var selected_registry: EditedThingRegistry = get_selected_registry()
			if is_instance_valid(selected_registry):
				close_others(selected_registry.get_registry())


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var item: TreeItem = tree.get_item_at_position(mouse_position)
	var metadata = item.get_metadata(TC.NAME)
	if metadata is EditedThingRegistry:
		registry_selected.emit(metadata)
	elif metadata is GDScript and Thing.is_valid_child_class(metadata):
		thing_class_selected.emit(metadata)


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


func _on_edited_registry_dirty_changed(new_value: bool, edited: EditedThingRegistry) -> void:
	var root_node : TreeItem = edited.get_tree_node()
	var text := root_node.get_text(TC.NAME)
	text = text.trim_suffix("(*)")
	if new_value == true:
		text += "(*)"
	root_node.set_text(TC.NAME, text)
#endregion


#region Opening
func open_file_from_path(path: String) -> void:
	open_file(ResourceLoader.load(path))


func open_file(registry: ThingRegistry) -> void:
	if not is_instance_valid(registry):
		return

	var edited_registry: EditedThingRegistry = get_opened_edited_registry(registry)
	if is_instance_valid(edited_registry):
		tree.deselect_all()
		tree.set_selected(edited_registry.get_tree_node(), TC.NAME)
		return

	edited_registry = EditedThingRegistry.new(registry, _root_item)
	edited_registry.dirty_changed.connect(_on_edited_registry_dirty_changed.bind(weakref(edited_registry)))
	tree.deselect_all()
	tree.set_selected(edited_registry.get_tree_node(), TC.NAME)
#endregion

#region Closing
func close_file(registry: ThingRegistry) -> void:
	var edited_registry: EditedThingRegistry = get_opened_edited_registry(registry)
	if is_instance_valid(edited_registry):
		close_edited_file(edited_registry)


func close_edited_file(edited_registry: EditedThingRegistry) -> void:
	# TODO check if the registry is dirty
	edited_registry.get_tree_node().free()


func close_all() -> void:
	for tree_item: TreeItem in _root_item.get_children():
		var metadata = tree_item.get_metadata(TC.NAME)
		if metadata is EditedThingRegistry:
			close_edited_file(metadata)


func close_others(registry: ThingRegistry) -> void:
	for tree_item: TreeItem in _root_item.get_children():
		var metadata = tree_item.get_metadata(TC.NAME)
		if metadata is EditedThingRegistry and not EditedThingRegistry.is_registry(metadata, registry):
			close_edited_file(metadata)
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


func _start_new_registry_creation() -> void:
	file_dialog.title = "New Thing Registry..."
	if file_dialog.current_path.get_extension() != "tres":
		file_dialog.current_path = "%s/new_thing_registry.tres" % file_dialog.current_path.get_base_dir()
	file_dialog.popup_centered()


func _on_file_saved(file: ThingRegistry) -> void:
	var edited: EditedThingRegistry = get_opened_edited_registry(file)
	if edited == null or not is_instance_valid(edited):
		return
	edited.set_dirty(false)


func _on_unsaved_file_found(file: ThingRegistry) -> void:
	var edited: EditedThingRegistry = get_opened_edited_registry(file)
	if edited == null or not is_instance_valid(edited):
		return

	edited.get_tree_node().set_text(TC.NAME, "[unsaved]")
	_start_save_as(file)
#endregion


#region EditedThingRegistry
func get_opened_edited_registry(regitry: ThingRegistry) -> EditedThingRegistry:
	for tree_item in _root_item.get_children():
		var metadata = tree_item.get_metadata(TC.NAME)
		if EditedThingRegistry.is_registry(metadata, regitry):
			return metadata
	return null


func get_selected_registry() -> EditedThingRegistry:
	var current_item: TreeItem = tree.get_selected()
	while true:
		if current_item == null:
			return null
		if current_item == _root_item:
			push_error("You should not be able to select the root node. There is something wrong in the get_selected_registry() method.")
			return null
		var metadata = current_item.get_metadata(TC.NAME)
		if is_instance_valid(metadata) and metadata is EditedThingRegistry:
			return metadata
		current_item = current_item.get_parent()
	return null



class EditedThingRegistry extends RefCounted:
	var _registry: ThingRegistry : get = get_registry
	var _tree_node: TreeItem : get = get_tree_node
	var _dirty: bool = false : set = set_dirty, get = is_unsaved
	var _tree_script_map: Dictionary[GDScript, TreeItem] = {}

	signal dirty_changed(new_value: bool)

	func _init(registry: ThingRegistry, root_item: TreeItem) -> void:
		_registry = registry
		_populate(root_item)


	func get_registry() -> ThingRegistry:
		return _registry


	func get_tree_node() -> TreeItem:
		return _tree_node


	static func is_registry(edited_registry: EditedThingRegistry, registry: ThingRegistry) -> bool:
		if not edited_registry is EditedThingRegistry:
			return false
		return edited_registry.get_registry() == registry


	func _populate(root: TreeItem) -> void:
		_tree_node = root.get_tree().create_item(root)
		_tree_node.set_metadata(TC.NAME, self)
		_tree_node.set_icon(TC.NAME, EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"))
		if _registry.resource_name.length() > 0:
			_tree_node.set_text(TC.NAME, _registry.resource_name)
		else:
			_tree_node.set_text(TC.NAME, _registry.resource_path.get_file())

		_tree_script_map.set(Thing, _tree_node)
		_populate_directory(_registry.base_directory)
		_connect_signals()


	func _populate_directory(path: String = "") -> void:
		var directory: DirAccess = DirAccess.open(path)

		if not directory:
			push_error("Could not open directory %s" % path)
			return

		for file_name in directory.get_files():
			if not file_name.ends_with(".gd"):
				continue

			var resource = ResourceLoader.load("%s/%s" % [path, file_name])
			if resource is GDScript and Thing.is_valid_child_class(resource, true):
				_add_script_in_tree(resource)

		for sub_directory in directory.get_directories():
			_populate_directory("%s/%s" % [path, sub_directory])


	func _add_script_in_tree(script: GDScript) -> void:
		if _tree_script_map.has(script):
			return
		var base_script = script.get_base_script()
		if not _tree_script_map.has(base_script):
			_add_script_in_tree(base_script)
		var root: TreeItem = _tree_script_map.get(base_script)
		# TODO sort class by names
		var new_item: TreeItem = root.create_child()

		var display_name = script.resource_name
		if display_name.is_empty():
			display_name = script.get_global_name()
		if display_name.is_empty():
			display_name = script.resource_path.get_file().trim_suffix(".gd").capitalize()
		display_name = display_name.trim_prefix("Thing")
		new_item.set_text(TC.NAME, display_name)
		new_item.set_metadata(TC.NAME, script)
		_tree_script_map.set(script, new_item)


	func unpopulate() -> void:
		if _tree_script_map.has(Thing):
			_tree_script_map.get(Thing).free()
		_tree_script_map.clear()
		_disconnect_signals()
		pass


	func _connect_signals():
		_registry.changed.connect(set_dirty.bind(true))


	func _disconnect_signals():
		# TODO Vérifier si ca marche bien et qu'il ne faut pas le bind(true)
		_registry.changed.disconnect(set_dirty)


	func set_dirty(value: bool) -> void:
		var prev_value: bool = _dirty
		_dirty = value
		if prev_value != _dirty:
			dirty_changed.emit(_dirty)


	func is_unsaved() -> bool:
		return _dirty


#endregion
