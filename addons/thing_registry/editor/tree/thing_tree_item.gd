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
	_thing.changed.connect(_on_thing_changed)
	var tree: ThingTree = get_tree()

	for module in _thing.modules:
		tree.open_module(module)

	for child: String in _thing.get_childs_paths():
		var loaded: Thing = Thing.load(child)
		if loaded != null:
			create_thing_child().populate(loaded)

func call_adapter(column: ThingTreeColumn, method: StringName, args: Array = []) -> Variant:
	return column.adapter.tree_item_callv(method, self, args)


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


func update_attribute_column(index: int, header: ThingTreeColumnAttribute, properties: Array[StringName]) -> void:
	var property: StringName = header.get_property_path()

	if not properties.has(property):
		set_custom_bg_color(index, Color.DIM_GRAY)
		return

	var value: Variant = _thing.get(property)
	@warning_ignore("int_as_enum_without_cast")
	#var type: Variant.Type = typeof(value)
	if value == null:
		set_text(index, "")
	else:
		set_text(index, var_to_str(value))
	set_text_alignment(index, HORIZONTAL_ALIGNMENT_LEFT)
	set_editable(index, false)
#
	#if _thing.property_can_revert(property):
		#add_button(
			#index,
			#EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons"),
			#Buttons.REVERT,
			#false,
			#"Revert value"
		#)
#


func _on_thing_changed() -> void:
	var tree: ThingTree = get_tree()
	for colum: ThingTreeColumn in tree.tree_columns.values():
		call_adapter.call_deferred(colum, &"update_column", [colum.get_index()])


func set_dirty(value: bool) -> void:
	var prev_value: bool = _dirty
	_dirty = value
	if prev_value != _dirty:
		dirty_changed.emit(_dirty)


func is_unsaved() -> bool:
	return _dirty
##endregion


func set_drag_preview(text: String, icon: Texture2D = null) -> void:
	var preview: HBoxContainer = HBoxContainer.new()
	if is_instance_valid(icon):
		var icon_rect: TextureRect = TextureRect.new()
		var icon_size: int = EditorInterface.get_editor_theme().get_constant("class_icon_size", "Editor")
		icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.texture = icon
		preview.add_child(icon_rect)
	var label: Label = Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	preview.add_child(label)
	get_tree().set_drag_preview(preview)
