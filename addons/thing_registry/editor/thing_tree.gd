@tool
class_name ThingTree
extends Tree



signal thing_selected(thing: Thing)

## Tree columns indexes
enum Column {
	RESOURCE,
}


const Menu = preload("uid://dsju3xwf6tler")


@export var search: LineEdit
@export var file_dialog: FileDialog


var _root_item: TreeItem


#region Virtual methods
func _enter_tree() -> void:
	if not is_part_of_edited_scene():
		search.right_icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")


	_root_item = create_item()

	set_column_custom_minimum_width(Column.RESOURCE, 200)


	open_file(load("uid://dvmq80fff46c7"))
	open_file(load("uid://djoqnndd4i3hr"))
	open_file(load("uid://c4j3dxma82626"))
	open_file(load("uid://dd6uaa4frttpn"))

#endregion


#region Signals
func _on_menu_action_pressed(action: Menu.Action) -> void:
	match action:
		Menu.Action.FILE_NEW_THING:
			pass
		Menu.Action.FILE_OPEN:
			EditorInterface.popup_quick_open(open_file_from_path, ["Thing"])
		Menu.Action.FILE_RELOAD:
			for child: TreeItem in _root_item.get_children():
				var metadata = child.get_metadata(ThingTree.Column.RESOURCE)
				if metadata is EditedThing:
					var thing = metadata.get_thing()
					close_file(thing)
					open_file(thing)
		#Menu.Action.FILE_SAVE:
			#var selected_thing: EditedThing = get_selected_thing()
			##if is_instance_valid(selected_thing):
				##ResourceSaver.save(selected_thing.get_thing())
				##_on_file_saved(selected_thing.get_thing())
			#EditorInterface.save_all_scenes()
		#Menu.Action.FILE_SAVE_ALL:
			#EditorInterface.save_all_scenes()
		#Menu.Action.FILE_SHOW_IN_FILESYSTEM:
			#var selected_thing: EditedThing = get_selected_thing()
			#if is_instance_valid(selected_thing):
				#EditorInterface.get_file_system_dock().navigate_to_path(selected_thing.get_thing().resource_path)
		Menu.Action.FILE_CLOSE:
			var selected_thing: EditedThing = get_selected_thing()
			if is_instance_valid(selected_thing):
				close_file(selected_thing.get_thing())
		Menu.Action.FILE_CLOSE_ALL:
			close_all()
		Menu.Action.FILE_CLOSE_OTHER:
			var selected_thing: EditedThing = get_selected_thing()
			if is_instance_valid(selected_thing):
				close_others(selected_thing.get_thing())



func _on_file_dialog_file_selected(path: String) -> void:
	var extension: String = path.get_extension()
	if extension.is_empty():
		if not path.ends_with("."):
			path += "."
		path += "tres"
	elif extension != "tres":
		push_error("Invalid extension for a Thing thing file.")
		return
#
	#var new_thing: Thing
#
	#if is_instance_valid(_current_saving_thing):
		#close_file(_current_saving_thing)
		#new_thing = _current_saving_thing
	#else:
		#new_thing = Thing.new()
#
	#new_thing.take_over_path(path)
	#ResourceSaver.save(new_thing, path)
	#open_file(load(path))
	#_current_saving_thing = null



#endregion


#region Opening
func open_file_from_path(path: String) -> void:
	open_file(ResourceLoader.load(path))


func open_file(thing: Thing) -> void:
	if not is_instance_valid(thing):
		return

	while is_instance_valid(thing.parent):
		thing = thing.parent

	var edited_thing: EditedThing = get_opened_edited_thing(thing)
	if is_instance_valid(edited_thing):
		deselect_all()
		set_selected(edited_thing.get_tree_node(), Column.RESOURCE)
		return

	edited_thing = EditedThing.new(thing, _root_item)
	edited_thing.dirty_changed.connect(_on_edited_thing_dirty_changed.bind(weakref(edited_thing)))
	deselect_all()
	set_selected(edited_thing.get_tree_node(), Column.RESOURCE)
#endregion

#region Closing
func close_file(thing: Thing) -> void:
	var edited_thing: EditedThing = get_opened_edited_thing(thing)
	if is_instance_valid(edited_thing):
		close_edited_file(edited_thing)


func close_edited_file(edited_thing: EditedThing) -> void:
	# TODO check if the thing is dirty
	ResourceSaver.save(edited_thing.get_thing())
	edited_thing.get_tree_node().free()


func close_all() -> void:
	for tree_item: TreeItem in _root_item.get_children():
		var metadata = tree_item.get_metadata(Column.RESOURCE)
		if metadata is EditedThing:
			close_edited_file(metadata)


func close_others(thing: Thing) -> void:
	for tree_item: TreeItem in _root_item.get_children():
		var metadata = tree_item.get_metadata(Column.RESOURCE)
		if metadata is EditedThing and not EditedThing.is_thing(metadata, thing):
			close_edited_file(metadata)
#endregion

#region Saving
func _start_save_as(file: Thing) -> void:
	file_dialog.title = "Save Thing As..."
	var path: String = "res://"
	if not file.is_built_in() and not file.resource_path.is_empty():
		path = file.resource_path

	file_dialog.current_path = path
	file_dialog.popup_centered()


func _start_new_thing_creation() -> void:
	file_dialog.title = "New Thing..."
	if file_dialog.current_path.get_extension() != "tres":
		file_dialog.current_path = "%s/new_thing.tres" % file_dialog.current_path.get_base_dir()
	file_dialog.popup_centered()


func _on_file_saved(file: Variant) -> void:
	var edited: EditedThing = get_opened_edited_thing(file)
	if edited == null or not is_instance_valid(edited):
		return
	edited.set_dirty(false)


func _on_unsaved_file_found(file: Variant) -> void:
	pass

	#edited.get_tree_node().set_text(Column.RESOURCE, "[unsaved]")
	#_start_save_as(file)
#endregion


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	return _is_valid_thing_drop_data(data) and is_instance_valid(get_item_at_position(at_position))


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: TreeItem  = get_item_at_position(at_position)
	# To be safe but probably need needed because it's already checked in _can_drop_data.
	if not _is_valid_thing_drop_data(data) or not is_instance_valid(item):
		return

	var section = get_drop_section_at_position(at_position)
	var metadata: EditedThing = item.get_metadata(Column.RESOURCE)
	var thing: Thing = metadata.get_thing()

	match section:
		-1: # Before mean parent of dropped is the same as current
			for dropped: Thing in data.get("things"):
				dropped.parent = thing.parent
		0, 1: # On it or below bean as child of current
			for dropped: Thing in data.get("things"):
				dropped.parent = thing

	#TODO not rebuild the tree on thing dropped
	rebuild_tree.call_deferred()


func _is_valid_thing_drop_data(data: Variant) -> bool:
	return (data is Dictionary
		and data.get("type") == "thing"
		and data.get("from") == self
		and typeof(data.get("things")) == TYPE_ARRAY
	)


func _get_drag_data(at_position: Vector2) -> Variant:
	if get_column_at_position(at_position) != Column.RESOURCE:
		return

	var item: TreeItem  = get_item_at_position(at_position)
	var metadata: EditedThing = item.get_metadata(Column.RESOURCE)
	var thing: Thing = metadata.get_thing()

	var preview: HBoxContainer = HBoxContainer.new()
	var icon: TextureRect = TextureRect.new()
	var icon_size: int = EditorInterface.get_editor_theme().get_constant("class_icon_size", "Editor")
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = item.get_icon(Column.RESOURCE)
	preview.add_child(icon)
	var label: Label = Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = thing.resource_path.get_file()
	preview.add_child(label)

	set_drag_preview(preview)

	return {"type": "thing", "from": self, "things": [thing]}


func _on_item_mouse_selected(mouse_position: Vector2, _mouse_button_index: int) -> void:
	var item: TreeItem = get_item_at_position(mouse_position)
	var metadata: EditedThing = item.get_metadata(Column.RESOURCE)
	EditorInterface.get_inspector().edit(metadata.get_thing())


func _on_edited_thing_dirty_changed(new_value: bool, edited: EditedThing) -> void:
	var root_node : TreeItem = edited.get_tree_node()
	var text := root_node.get_text(Column.RESOURCE)
	text = text.trim_suffix("(*)")
	if new_value == true:
		text += "(*)"
	root_node.set_text(Column.RESOURCE, text)


func _on_file_dialog_canceled() -> void:
	pass # Replace with function body.


func rebuild_tree() -> void:
	var opened_list: Array[String] = []
	for children: TreeItem in _root_item.get_children():
		var metadata: EditedThing = children.get_metadata(Column.RESOURCE)
		opened_list.append(metadata.get_thing().resource_path)
	close_all()
	await get_tree().create_timer(0.1).timeout
	for opened in opened_list:
		open_file(load(opened))

	open_file(load("uid://dvmq80fff46c7"))
	open_file(load("uid://djoqnndd4i3hr"))
	open_file(load("uid://c4j3dxma82626"))
	open_file(load("uid://dd6uaa4frttpn"))


#region EditedThing
func get_opened_edited_thing(thing: Thing) -> EditedThing:
	while is_instance_valid(thing.parent):
		thing = thing.parent

	for tree_item in _root_item.get_children():
		var metadata = tree_item.get_metadata(Column.RESOURCE)
		if EditedThing.is_thing(metadata, thing):
			return metadata
	return null


func get_selected_thing() -> EditedThing:
	var current_item: TreeItem = get_selected()
	while true:
		if current_item == null:
			return null
		if current_item == _root_item:
			push_error("You should not be able to select the root node. There is something wrong in the get_selected_thing() method.")
			return null
		var metadata = current_item.get_metadata(Column.RESOURCE)
		if is_instance_valid(metadata) and metadata is EditedThing:
			return metadata
		current_item = current_item.get_parent()
	return null



class EditedThing extends RefCounted:
	var _thing: Thing : get = get_thing
	var _tree_node: TreeItem : get = get_tree_node
	var _dirty: bool = false : set = set_dirty, get = is_unsaved

	signal dirty_changed(new_value: bool)

	func _init(thing: Thing, root_item: TreeItem) -> void:
		_thing = thing
		_populate(root_item)


	func get_thing() -> Thing:
		return _thing


	func get_tree_node() -> TreeItem:
		return _tree_node


	static func is_thing(edited_thing: EditedThing, thing: Thing) -> bool:
		if not edited_thing is EditedThing:
			return false
		return edited_thing.get_thing() == thing


	func _populate(root: TreeItem) -> void:
		_tree_node = root.create_child()
		_tree_node.set_metadata(Column.RESOURCE, self)

		_tree_node.set_icon(Column.RESOURCE, EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"))
		if _thing.resource_name.length() > 0:
			_tree_node.set_text(Column.RESOURCE, _thing.resource_name)
		else:
			_tree_node.set_text(Column.RESOURCE, _thing.resource_path.get_file())

		_connect_signals()

		for child in _thing.get_childs_paths():
			EditedThing.new(load(child), _tree_node)



	#func _populate_thing_tree(root: TreeItem) -> void:
		#var edited_root: EditedThing = _tree_node.get_metadata(Column.RESOURCE)
		#var directory: DirAccess = DirAccess.open(path)

		#if not directory:
			#push_error("Could not open directory %s" % path)
			#return

		#for file_name in directory.get_files():
			#if not file_name.ends_with(".gd"):
				#continue

			#var resource = ResourceLoader.load("%s/%s" % [path, file_name])
			#if resource is GDScript and Thing.is_valid_child_class(resource, true):
				#_add_script_in_tree(resource)

		#for sub_directory in directory.get_directories():
			#_populate_thing_tree("%s/%s" % [path, sub_directory])


	#func _add_script_in_tree(script: GDScript) -> void:
		#if _tree_script_map.has(script):
			#return
		#var base_script = script.get_base_script()
		#if not _tree_script_map.has(base_script):
			#_add_script_in_tree(base_script)
		#var root: TreeItem = _tree_script_map.get(base_script)
		## TODO sort class by names
		#var new_item: TreeItem = root.create_child()

		#var display_name = script.resource_name
		#if display_name.is_empty():
			#display_name = script.get_global_name()
		#if display_name.is_empty():
			#display_name = script.resource_path.get_file().trim_suffix(".gd").capitalize()
		#display_name = display_name.trim_prefix("Thing")
		#new_item.set_text(Column.RESOURCE, display_name)
		#new_item.set_metadata(Column.RESOURCE, script)
		#_tree_script_map.set(script, new_item)


	func unpopulate() -> void:
		_disconnect_signals()


	func _connect_signals():
		_thing.changed.connect(set_dirty.bind(true))


	func _disconnect_signals():
		# TODO Vérifier si ca marche bien et qu'il ne faut pas le bind(true)
		_thing.changed.disconnect(set_dirty)


	func set_dirty(value: bool) -> void:
		var prev_value: bool = _dirty
		_dirty = value
		if prev_value != _dirty:
			dirty_changed.emit(_dirty)


	func is_unsaved() -> bool:
		return _dirty
##endregion
