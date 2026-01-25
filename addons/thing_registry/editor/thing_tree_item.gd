@tool
class_name ThingTreeItem
extends TreeItem

enum Buttons {
	REVERT
}


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

	for module in _thing.modules:
		var tree: Tree = get_tree()
		if tree is ThingTree:
			tree.open_module(module)

	for child: String in _thing.get_childs_paths():
		var loaded: Thing = Thing.load_thing_at(child)
		if loaded != null:
			create_thing_child().populate(loaded)


func update_columns() -> void:
	if not is_instance_valid(_thing):
		return

	clear_buttons()
	var tree: ThingTree = get_tree()

	var properties: Array[StringName] = []
	for property in _thing.get_property_list():
		properties.append(property.name)

	for header: Control in tree.headers.values():
		var index: int = header.get_index()
		if header is ThingTreeHeaderAttribute:
			update_attribute_column(index, header, properties)
		elif header is ThingTreeHeaderModule:
			update_module_column(index, header)
		elif header is ThingTreeHeaderResource:
			update_resource_column(index)


func notify_button_clicked(column: int, id: int, mouse_button_index: int) -> void:
	_on_button_clicked(column, id, mouse_button_index)


func _on_button_clicked(column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MouseButton.MOUSE_BUTTON_LEFT:
		return

	var tree: ThingTree = get_tree()
	var property = tree.get_property_by_index(column)
	if property == &"resource":
		return

	if id == Buttons.REVERT and _thing.property_can_revert(property):
		set_text(column, _thing.property_get_revert(property))
		_thing.set(property, _thing.property_get_revert(property))


func notify_edited() -> void:
	_on_edited()


func _on_edited() -> void:
	var tree: ThingTree = get_tree()
	for header: Control in tree.headers.values():
		var index: int = header.get_index()
		if header is ThingTreeHeaderResource:
			_on_resource_edited(index)
		if header is ThingTreeHeaderAttribute:
			var property: StringName = header.get_property_path()
			if is_editable(index):
				_thing.set(property, get_text(index))


func update_resource_column(index: int) -> void:
	set_icon(index, EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"))
	set_text(index, _thing.get_display_name())
	set_editable(index, true)


func update_module_column(index: int, header: ThingTreeHeaderModule) -> void:
	var module: ThingModule = header.get_module()
	if _thing.modules.has(module):
		set_icon(index, module.get_icon())
		set_text(index, "D")
		set_tooltip_text(index, "This module is Defined on this Thing.")
	elif _thing.has_module(module.get_instance_name()):
		set_icon(index, module.get_icon())
		set_text(index, "H")
		set_tooltip_text(index, "This module is Herited from a parent Thing.")


func update_attribute_column(index: int, header: ThingTreeHeaderAttribute, properties: Array[StringName]) -> void:
	var property: StringName = header.get_property_path()

	if not properties.has(property):
		set_custom_bg_color(index, Color.DIM_GRAY)
		return

	var value: Variant = _thing.get(property)
	if value == null:
		set_text(index, "")
	else:
		set_text(index, value)
	set_text_alignment(index, HORIZONTAL_ALIGNMENT_LEFT)
	set_editable(index, true)

	if _thing.property_can_revert(property):
		add_button(
			index,
			EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons"),
			Buttons.REVERT,
			false,
			"Revert value"
		)




func _on_resource_edited(index: int) -> void:
	ThingUtils.rename(_thing, get_text(index))
	update_resource_column(index)


func unpopulate() -> void:
	_disconnect_signals()


func _connect_signals():
	_thing.changed.connect(set_dirty.bind(true))


func _disconnect_signals():
	# TODO Vérifier si ca marche bien et qu'il ne faut pas le bind(true)
	if _thing.changed.is_connected(set_dirty):
		_thing.changed.disconnect(set_dirty)


func set_dirty(value: bool) -> void:
	var prev_value: bool = _dirty
	_dirty = value
	if prev_value != _dirty:
		dirty_changed.emit(_dirty)


func is_unsaved() -> bool:
	return _dirty
##endregion
