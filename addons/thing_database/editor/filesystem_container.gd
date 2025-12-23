@tool
extends VBoxContainer

const Menu = preload("uid://dsju3xwf6tler")

@export var search: LineEdit
@export var tree: Tree
@onready var file_dialog: FileDialog = $FileDialog

var edited_databases: Array[EditedThingDatabase]
var _current_saving_database: ThingDatabase = null


#region Opening
func open_file(database: ThingDatabase) -> void:
	if not is_instance_valid(database):
		return
	prints("open", database)
#endregion

#region Closing
func close_file(database: ThingDatabase) -> void:
	prints("close", database)


func close_all() -> void:
	pass


func close_others(database: ThingDatabase) -> void:
	for edited_database: EditedThingDatabase in edited_databases.duplicate():
		var file := edited_database.get_database()
		if file == edited_database:
			continue

		close_file(file)
#endregion


#region Saving
func _start_save_as(file: ThingDatabase) -> void:
	file_dialog.title = "Save ThingDatabase As..."
	var path: String = "res://"
	if not file.is_built_in() and not file.resource_path.is_empty():
		path = file.resource_path

	file_dialog.current_path = path
	file_dialog.popup_centered()

	_current_saving_database = file


func _start_new_graph_creation() -> void:
	file_dialog.title = "New Thing Database..."
	if file_dialog.current_path.get_extension() != "tres":
		file_dialog.current_path = "%s/new_graph.tres" % file_dialog.current_path.get_base_dir()
	file_dialog.popup_centered()


func _on_file_saved(file: ThingDatabase) -> void:
	var idx: int = edited_databases.find_custom(EditedThingDatabase.is_database.bind(file))
	if idx == -1:
		return

	edited_databases[idx].set_dirty(false)


func _on_unsaved_file_found(file: ThingDatabase) -> void:
	var idx: int = edited_databases.find_custom(EditedThingDatabase.is_database.bind(file))
	if idx == -1:
		return

	#file_list.set_item_text(idx, "[unsaved]")
	#file_list.set_item_tooltip(idx, "[unsaved]")
	_start_save_as(file)
#endregion


#region Signals
func _on_menu_action_pressed(action: Menu.Action) -> void:
	match action:
		Menu.Action.FILE_NEW_DATABASE:
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
		push_error("Invalid extension for a Thing database file.")
		return

	var new_database: ThingDatabase

	if is_instance_valid(_current_saving_database):
		close_file(_current_saving_database)
		new_database = _current_saving_database
	else:
		new_database = ThingDatabase.new()

	new_database.take_over_path(path)
	ResourceSaver.save(new_database, path)
	open_file(load(path))
	_current_saving_database = null


func _on_file_dialog_canceled() -> void:
	_current_saving_database = null


func _on_edited_database_dirty_changed(new_value: bool, edited_database: ThingDatabase) -> void:
	var idx := edited_databases.find(edited_database)
	if idx == -1:
		return

	#var text := file_list.get_item_text(idx)
	#text = text.trim_suffix("(*)")
	#if new_value == true:
	#	text += "(*)"
	#file_list.set_item_text(idx, text)
#endregion

#region EditedThingDatabase
class EditedThingDatabase extends RefCounted:
	signal dirty_changed(new_value: bool)

	var _database: ThingDatabase : get = get_database
	var _dirty: bool = false : set = set_dirty, get = is_unsaved

	static func is_database(edited_database: EditedThingDatabase, database: ThingDatabase) -> bool:
		return edited_database.get_database() == database


	func _init(database: ThingDatabase) -> void:
		_database = database
		_database.changed.connect(set_dirty.bind(true))


	func set_dirty(value: bool) -> void:
		var prev_value: bool = _dirty
		_dirty = value
		if prev_value != _dirty:
			dirty_changed.emit(_dirty)


	func is_unsaved() -> bool:
		return _dirty


	func get_database() -> ThingDatabase:
		return _database
#endregion
