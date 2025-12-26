@tool
extends VBoxContainer

const Menu = preload("uid://dsju3xwf6tler")

@export var search: LineEdit
@export var tree: Tree
@onready var file_dialog: FileDialog = $FileDialog

var _current_saving_registry: ThingRegistry = null
var _root_item: TreeItem


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


func _on_tree_item_selected() -> void:
	print("selected")
	pass # Replace with function body.


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var item: TreeItem = tree.get_item_at_position(mouse_position)
	var metadata = item.get_metadata(0)
	if metadata is EditedThingRegistry:
		EditorInterface.inspect_object(metadata.get_registry())


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
	var text := root_node.get_text(0)
	text = text.trim_suffix("(*)")
	if new_value == true:
		text += "(*)"
	root_node.set_text(0, text)
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
		tree.set_selected(edited_registry.get_tree_node(), 0)
		return

	edited_registry = EditedThingRegistry.new(registry, _root_item)
	edited_registry.dirty_changed.connect(_on_edited_registry_dirty_changed.bind(weakref(edited_registry)))
	tree.deselect_all()
	tree.set_selected(edited_registry.get_tree_node(), 0)
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
		var metadata = tree_item.get_metadata(0)
		if metadata is EditedThingRegistry:
			close_edited_file(metadata)


func close_others(registry: ThingRegistry) -> void:
	for tree_item: TreeItem in _root_item.get_children():
		var metadata = tree_item.get_metadata(0)
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

	edited.get_tree_node().set_text(0, "[unsaved]")
	_start_save_as(file)
#endregion


#region EditedThingRegistry
func get_opened_edited_registry(regitry: ThingRegistry) -> EditedThingRegistry:
	for tree_item in _root_item.get_children():
		var metadata = tree_item.get_metadata(0)
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
		var metadata = current_item.get_metadata(0)
		if is_instance_valid(metadata) and metadata is EditedThingRegistry:
			return metadata
		current_item = current_item.get_parent()
	return null



@abstract
class EditedThing extends RefCounted:
	var _registry: ThingRegistry : get = get_registry
	var _tree_node: TreeItem : get = get_tree_node


	func _init(registry: ThingRegistry, root_item: TreeItem) -> void:
		_registry = registry
		_populate(root_item)
		_connect_signals()


	func get_registry() -> ThingRegistry:
		return _registry


	func get_tree_node() -> TreeItem:
		return _tree_node


	@abstract
	func _populate(root_item: TreeItem) -> void


	@abstract
	func _connect_signals() -> void



class EditedThingRegistry extends EditedThing:
	signal dirty_changed(new_value: bool)

	var _dirty: bool = false : set = set_dirty, get = is_unsaved
	var _thing_nodes: Dictionary[int, EditedThingDefinition] = {}

	static func is_registry(edited_registry: EditedThingRegistry, registry: ThingRegistry) -> bool:
		if not edited_registry is EditedThingRegistry:
			return false
		return edited_registry.get_registry() == registry


	func _populate(root: TreeItem) -> void:
		_tree_node = root.get_tree().create_item(root)
		_tree_node.set_metadata(0, self)
		_tree_node.set_icon(0, EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"))
		if _registry.resource_name.length() > 0:
			_tree_node.set_text(0, _registry.resource_name)
		else:
			_tree_node.set_text(0, _registry.resource_path.get_file())

		populate_things()


	func populate_things(parent_uid: int = 0, parent_node: TreeItem = _tree_node) -> void:
		var thing_definitions: Dictionary[int, ThingDefinition] = _registry.get_thing_definitions()
		for uid in thing_definitions.keys():
			var definition: ThingDefinition = thing_definitions.get(uid)
			if definition.parent_uid == parent_uid:
				var edited = EditedThingDefinition.new(_registry, parent_node, self, definition)
				_thing_nodes.set(uid, edited)


	func _connect_signals():
		_registry.changed.connect(set_dirty.bind(true))
		_registry.thing_added.connect(_on_added_thing)
		_registry.thing_removed.connect(_on_removed_thing)


	func set_dirty(value: bool) -> void:
		var prev_value: bool = _dirty
		_dirty = value
		if prev_value != _dirty:
			dirty_changed.emit(_dirty)


	func is_unsaved() -> bool:
		return _dirty


	func _on_added_thing(uid: int) -> void:
		pass

	func _on_removed_thing(uid: int) -> void:
		pass


	func unpopulate() -> void:
		pass

#endregion


#region EditedThingDefinition
class EditedThingDefinition extends EditedThing:
	var _thing: ThingDefinition : get = get_thing
	var _edited_registry: EditedThingRegistry


	func _init(registry: ThingRegistry, root_item: TreeItem, edited_registry: EditedThingRegistry, thing: ThingDefinition) -> void:
		assert(registry.get_thing_definitions().has(thing.uid), "Could not find thing with uid %s in registry %s" % [thing.uid, registry.resource_path])
		_thing = thing
		_edited_registry = edited_registry
		super(registry, root_item)


	func get_thing() -> ThingDefinition:
		return _thing


	func _populate(root: TreeItem) -> void:
		_tree_node = root.get_tree().create_item(root)
		_tree_node.set_metadata(0, self)
		_tree_node.set_icon(0, EditorInterface.get_editor_theme().get_icon("Object", "EditorIcons"))
		if _thing.resource_name.length() > 0:
			_tree_node.set_text(0, _thing.resource_name)
		else:
			_tree_node.set_text(0, _thing.resource_path.get_file())

		_edited_registry.populate_things(_thing.uid, _tree_node)


	func _connect_signals():
		pass

#endregion
