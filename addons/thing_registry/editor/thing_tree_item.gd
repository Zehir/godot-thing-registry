@tool
class_name ThingTreeItem
extends TreeItem


var _thing: Thing : get = get_thing
var _dirty: bool = false : set = set_dirty, get = is_unsaved

signal dirty_changed(new_value: bool)


func create_thing_child(index: int = -1) -> ThingTreeItem:
	var child: TreeItem = create_child(index)
	child.set_script(ThingTreeItem)
	return child


func get_thing() -> Thing:
	return _thing


func populate(thing: Thing) -> void:
	_thing = thing
	_connect_signals()

	for child in _thing.get_childs_paths():
		var child_thing_item: ThingTreeItem = create_thing_child()
		child_thing_item.populate(load(child))


func update_columns() -> void:
	if not is_instance_valid(_thing):
		return

	var tree: ThingTree = get_tree()
	for header: ThingTreeHeaderButton in tree.headers.values():
		var property: StringName = header.get_property_path()
		var index: int = header.get_index()
		var value: Variant = _thing.get(property)

		if property == &"resource_path" and value is String:
			set_icon(index, EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"))
			set_text(index, value.get_file())
			set_editable(index, false)
			continue

		set_text(index, value)
		set_editable(index, true)


func notify_edited() -> void:
	_on_edited()


func _on_edited() -> void:
	var tree: ThingTree = get_tree()
	for header: ThingTreeHeaderButton in tree.headers.values():
		var property: StringName = header.get_property_path()
		var index: int = header.get_index()
		if is_editable(index):
			_thing.set(property, get_text(index))


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
