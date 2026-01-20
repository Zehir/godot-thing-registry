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

var headers: Dictionary[StringName, ThingTreeHeaderButton] = {}


#region Virtual methods
func _enter_tree() -> void:
	if is_part_of_edited_scene():
		return

	search.right_icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")

	var root_item: TreeItem = create_item()
	root_item.set_script(ThingTreeItem)
	_root_item = root_item

	open_property(&"resource")
	open_property(&"item/name1")
	open_property(&"item/name2")
	open_property(&"item/name3")
	open_property(&"item/name4")
	open_property(&"item/name5")

	rebuild_tree()
#endregion


#region Header buttons
func open_property(property: StringName, after: StringName = &"") -> void:
	if headers.has(property):
		return
	var button: ThingTreeHeaderButton = ThingTreeHeaderButton.new(property)
	if not after.is_empty() and headers.has(after):
		headers[after].add_sibling(button)
	else:
		tree_columns_container.add_child(button)
	expand_control.move_to_front()
	button.resized.connect(_on_header_button_resized.bind(button))
	headers.set(property, button)
	columns = headers.size()
	set_column_expand(headers.size() - 1, false)


func close_property(property: StringName) -> void:
	if not headers.has(property):
		return
	if property == &"resource_path":
		push_error("Can't close the property %s" % property)
		return

	headers[property].queue_free()
	headers.erase(property)
	columns = headers.size()


func get_property_index(property: StringName) -> int:
	if headers.has(property):
		return headers[property].get_index()
	return -1


func get_property_by_index(index: int) -> StringName:
	var child = tree_columns_container.get_child(index)
	if child is ThingTreeHeaderButton:
		return child.property_path
	return &""


func _on_header_button_resized(button: ThingTreeHeaderButton) -> void:
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
	open_root_file(ResourceLoader.load(path))


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
#endregion


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	if not _is_valid_thing_drop_data(data):
		return false
	var column: int = get_column_at_position(at_position)
	if column != 0:
		return false
	var item: ThingTreeItem = get_item_at_position(at_position)
	if not is_instance_valid(item):
		return false
	var thing: Thing = item.get_thing()
	for droped_thing in data.get("things"):
		if thing == droped_thing:
			return false
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: ThingTreeItem = get_item_at_position(at_position)
	# To be safe but probably need needed because it's already checked in _can_drop_data.
	if not _is_valid_thing_drop_data(data) or not is_instance_valid(item):
		return

	var section = get_drop_section_at_position(at_position)
	var thing: Thing = item.get_thing()

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
	if get_column_at_position(at_position) != 0:
		return

	var item: ThingTreeItem = get_item_at_position(at_position)
	var thing: Thing = item.get_thing()

	var preview: HBoxContainer = HBoxContainer.new()
	var icon: TextureRect = TextureRect.new()
	var icon_size: int = EditorInterface.get_editor_theme().get_constant("class_icon_size", "Editor")
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = item.get_icon(0)
	preview.add_child(icon)
	var label: Label = Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = thing.resource_path.get_file()
	preview.add_child(label)

	set_drag_preview(preview)

	return {"type": "thing", "from": self, "things": [thing]}


func _on_item_mouse_selected(mouse_position: Vector2, _mouse_button_index: int) -> void:
	var item: ThingTreeItem = get_item_at_position(mouse_position)
	EditorInterface.get_inspector().edit(item.get_thing())


func _on_edited_thing_dirty_changed(new_value: bool, edited: Variant) -> void:
	var root_node : TreeItem = edited.get_tree_node()
	var text := root_node.get_text(0)
	text = text.trim_suffix("(*)")
	if new_value == true:
		text += "(*)"
	root_node.set_text(0, text)


func _on_file_dialog_canceled() -> void:
	pass # Replace with function body.


func rebuild_tree() -> void:
	close_all()
	var root = DirAccess.open("res://thing_root/")
	for file in root.get_files():
		if not file.ends_with(".tres"):
			continue
		var loaded: Resource = load(root.get_current_dir().path_join(file))
		if loaded is Thing:
			open_root_file(loaded)

	_root_item.call_recursive(&"update_columns")


func _on_item_edited() -> void:
	get_edited().notify_edited()


func _on_button_clicked(item: ThingTreeItem, column: int, id: int, mouse_button_index: int) -> void:
	item.notify_button_clicked(column, id, mouse_button_index)


func _on_debug_button_pressed() -> void:
	rebuild_tree()
