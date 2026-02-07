@tool
class_name ThingTree
extends Tree

@warning_ignore("unused_signal")
signal thing_selected(thing: Thing)

const Menu = preload("uid://dsju3xwf6tler")

@export var search: LineEdit
@export var file_dialog: FileDialog
@export var tree_columns_container: HSplitContainer
@export var expand_control: Control
@export var tree_container: VBoxContainer

var _root_item: ThingTreeItem

var tree_columns: Dictionary[StringName, ThingTreeColumn] = {}

var tree_clicked: bool = false
var pending_click_select: ThingTreeItem
var ignore_selection_signal: bool = false


#region Virtual methods
func _enter_tree() -> void:
	if is_part_of_edited_scene():
		return

#
#
	#RenderingServer.canvas_item_set_default_texture_filter(get_custom_canvas_item(), RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST_WITH_MIPMAPS)

	search.right_icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")

	var root_item: TreeItem = create_item()
	root_item.set_script(ThingTreeItem)
	_root_item = root_item

	_add_header(&"resource", ThingTreeColumnResource.new())

	rebuild_tree()


#endregion


#region Header buttons
func open_module(module: ThingModule) -> void:
	var module_path: StringName = StringName("module::%s" % module.resource_path)
	if tree_columns.has(module_path):
		#push_error("Was trying to open an already opened module.")
		return

	_add_header(module_path, ThingTreeColumnModule.new(module))

	for property in module.get_thing_property_list():
		open_property(module, property)


func open_property(module: ThingModule, property: Dictionary, after: StringName = &"") -> void:
	var fullname: StringName = module.get_property_full_name(property.name)
	if tree_columns.has(fullname):
		return
	_add_header(fullname, ThingTreeColumnAttribute.new(module, property), after)


func _add_header(key: StringName, control: Control, after: StringName = &"") -> void:
	if not after.is_empty() and tree_columns.has(after):
		tree_columns[after].add_sibling(control)
	else:
		tree_columns_container.add_child(control)
	expand_control.move_to_front()
	control.resized.connect(_on_header_resized.bind(control))
	tree_columns.set(key, control)
	columns = tree_columns.size()
	set_column_expand(tree_columns.size() - 1, false)
	_on_header_resized.bind(control).call_deferred()


func close_property(property: StringName) -> void:
	pass
	#if not headers.has(property):
		#return
	#if property == &"resource_path":
		#push_error("Can't close the property %s" % property)
		#return
#
	#headers[property].queue_free()
	#headers.erase(property)
	#columns = headers.size()


#func get_property_index(property: StringName) -> int:
	#if headers.has(property):
		#return headers[property].get_index()
	#return -1


func get_property_by_index(index: int) -> StringName:
	var child = tree_columns_container.get_child(index)
	if child is ThingTreeColumnAttribute:
		return child.property_path
	return &""


func _on_header_resized(button: Control) -> void:
	custom_minimum_size.x = tree_columns_container.size.x - expand_control.size.x
	var index: int = button.get_index()
	# Not sure why theses magic offset are needed but that works.
	if index == 0:
		set_column_custom_minimum_width(index, roundi(button.size.x) - 1)
	else:
		set_column_custom_minimum_width(index, roundi(button.size.x) + 2)
#endregion


#region Signals
func _on_menu_action_pressed(action: Menu.Action) -> void:
	match action:
		Menu.Action.FILE_NEW_THING:
			pass
		Menu.Action.FILE_OPEN:
			EditorInterface.popup_quick_open(open_root_file_from_path, ["Thing"])
		Menu.Action.FILE_RELOAD:
			pass
			#for child: TreeItem in _root_item.get_children():
				#var metadata = child.get_metadata(0)
				#if metadata is EditedThing:
					#var thing = metadata.get_thing()
					#close_file(thing)
					#open_root_file(thing)
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
			pass
			#var selected_thing: EditedThing = get_selected_thing()
			#if is_instance_valid(selected_thing):
				#close_file(selected_thing.get_thing())
		Menu.Action.FILE_CLOSE_ALL:
			close_all()
		Menu.Action.FILE_CLOSE_OTHER:
			pass
			#var selected_thing: EditedThing = get_selected_thing()
			#if is_instance_valid(selected_thing):
				#close_others(selected_thing.get_thing())



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
	#open_root_file(load(path))
	#_current_saving_thing = null



#endregion


#region Opening
func open_root_file_from_path(path: String) -> void:
	open_root_file(Thing.load_thing_at(path))


func open_root_file(thing: Thing) -> void:
	assert(is_instance_valid(thing), "Can't open a root file if nothing is provided.")
	assert(not is_instance_valid(thing.parent), "Can't open a root file if he have a parent.")
	var edited_thing: ThingTreeItem = get_root_thing_item(thing)
	if is_instance_valid(edited_thing):
		deselect_all()
		set_selected(edited_thing, 0)
		return

	edited_thing = _root_item.create_thing_child()
	edited_thing.populate(thing)
	# TODO Fix
	#edited_thing.dirty_changed.connect(_on_edited_thing_dirty_changed.bind(weakref(edited_thing)))
	deselect_all()
	set_selected(edited_thing, 0)


func get_root_thing(thing: Thing) -> Thing:
	while is_instance_valid(thing.parent):
		thing = thing.parent
	return thing


func get_root_thing_item(thing: Thing) -> ThingTreeItem:
	assert(not is_instance_valid(thing.parent), "Can't get opened root thing item if the provided thing have a parent.")
	for tree_item: ThingTreeItem in _root_item.get_children():
		if tree_item.get_thing() == thing:
			return tree_item
	return null
#endregion

#region Closing
func close_file(thing: Thing) -> void:
	var edited_thing: ThingTreeItem = get_root_thing_item(thing)
	if is_instance_valid(edited_thing):
		close_root_file(edited_thing)


func close_root_file(tree_item: ThingTreeItem) -> void:
	## TODO check if the thing is dirty
	## TODO save childs too
	ResourceSaver.save(tree_item.get_thing())
	tree_item.free()


func close_all() -> void:
	for tree_item: ThingTreeItem in _root_item.get_children():
		close_root_file(tree_item)


func close_others(thing: Thing) -> void:
	for tree_item: ThingTreeItem in _root_item.get_children():
		if tree_item.get_thing() != thing:
			close_root_file(tree_item)
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


@warning_ignore("unused_parameter")
func _on_file_saved(file: Variant) -> void:
	#var edited: EditedThing = get_opened_edited_thing(file)
	#if edited == null or not is_instance_valid(edited):
		#return
	#edited.set_dirty(false)
	pass


@warning_ignore("unused_parameter")
func _on_unsaved_file_found(file: Variant) -> void:
	pass

	#edited.get_tree_node().set_text(get_property_index(&"resource_path, "[unsaved]")
	#_start_save_as(file)


func _on_edited_thing_dirty_changed(new_value: bool, edited: Variant) -> void:
	var root_node : TreeItem = edited.get_tree_node()
	var text := root_node.get_text(0)
	text = text.trim_suffix("(*)")
	if new_value == true:
		text += "(*)"
	root_node.set_text(0, text)


func _on_file_dialog_canceled() -> void:
	pass # Replace with function body.
#endregion


func rebuild_tree() -> void:
	close_all()

	for tree_column_name: StringName in tree_columns.keys():
		var tree_column: ThingTreeColumn = tree_columns.get(tree_column_name)
		if not tree_column is ThingTreeColumnResource:
			tree_column.free()
			tree_columns.erase(tree_column_name)
	columns = 1

	var root = DirAccess.open("res://thing_root/")
	for file in root.get_files():
		if not file.ends_with(".tres"):
			continue
		var loaded: Thing = Thing.load_thing_at(root.get_current_dir().path_join(file))
		if loaded != null:
			open_root_file(loaded)

	for tree_column: ThingTreeColumn in tree_columns.values():
		var index: int = tree_column.get_index()
		for item: ThingTreeItem in _root_item.get_children():
			item.call_recursive(&"call_adapter", tree_column, &"update_column", [index])



#region Adapter calls
func _get_drag_data(at_position: Vector2) -> Variant:
	pending_click_select = null
	var column_index: int = get_column_at_position(at_position)
	if column_index == -1:
		return null

	for tree_column: ThingTreeColumn in tree_columns.values():
		if column_index == tree_column.get_index():
			return get_item_at_position(at_position).call_adapter(tree_column, &"get_drag_data", [column_index])
	return null


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var column_index: int = get_column_at_position(at_position)
	for tree_column: ThingTreeColumn in tree_columns.values():
		if column_index == tree_column.get_index():
			return get_item_at_position(at_position).call_adapter(tree_column, &"can_drop_data", [column_index, data])
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: ThingTreeItem = get_item_at_position(at_position)
	var section = get_drop_section_at_position(at_position)
	var column_index = get_column_at_position(at_position)
	for tree_column: ThingTreeColumn in tree_columns.values():
		if column_index == tree_column.get_index():
			item.call_adapter(tree_column, &"notify_drop_data", [column_index, section, data])
			return


func _on_item_edited() -> void:
	var edited: ThingTreeItem = get_edited()
	for tree_column: ThingTreeColumn in tree_columns.values():
		var column_index: int = tree_column.get_index()
		edited.call_adapter(tree_column, &"notify_edited", [column_index])


func _on_button_clicked(item: ThingTreeItem, column_index: int, id: int, mouse_button_index: int) -> void:
	for tree_column: ThingTreeColumn in tree_columns.values():
		if column_index == tree_column.get_index():
			item.call_adapter(tree_column, &"notify_button_clicked", [column_index, id, mouse_button_index])
			return
#endregion


func _on_debug_button_pressed() -> void:
	rebuild_tree()


func _on_item_mouse_selected(mouse_position: Vector2, _mouse_button_index: int) -> void:
	if tree_clicked:
		pending_click_select = get_item_at_position(mouse_position)
	else:
		EditorInterface.get_inspector().edit(get_item_at_position(mouse_position).get_thing())


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event.is_echo():
		return

	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.shift_pressed:
				_handle_shift_selection(event)
			if get_rect().has_point(get_local_mouse_position()):
				tree_clicked = true
		else:
			tree_clicked = false
			if is_instance_valid(pending_click_select):
				EditorInterface.get_inspector().edit(pending_click_select.get_thing())
				pending_click_select = null


func _handle_shift_selection(event: InputEventMouseButton) -> void:
	if true:
		return
	# TODO do we want custom beavior to allow shift selection ?
	accept_event()
	var cursor_item: ThingTreeItem = get_selected()
	var cursor_column: int = get_selected_column()


	var target_item: ThingTreeItem = get_item_at_position(event.position)
	if not is_instance_valid(target_item):
		return
	var target_column: int = get_column_at_position(event.position)


	prints("cursor", cursor_item.get_thing().get_display_name(), cursor_column)
	prints("target", target_item.get_thing().get_display_name(), target_column)



func _on_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	pass
	#if ignore_selection_signal:
		#return
	#ignore_selection_signal = true
	#deselect_all()
	#if selected:
		#set_selected(item, column)
	#ignore_selection_signal = false
