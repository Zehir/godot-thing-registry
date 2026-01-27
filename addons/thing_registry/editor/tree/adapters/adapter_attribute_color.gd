@tool
class_name TreeValueAdapterAttributeColor
extends TreeValueAdapterAttribute

static var base_stylebox: StyleBoxFlat
static var color_picker_popup: PopupPanel
static var color_picker: ColorPicker


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_header.custom_minimum_size.x = 5.0

	if not is_instance_valid(base_stylebox):
		base_stylebox = StyleBoxFlat.new()
		base_stylebox.set_border_width_all(2)
		base_stylebox.set_corner_radius_all(8)

	if not is_instance_valid(color_picker_popup):
		color_picker_popup = PopupPanel.new()
		color_picker_popup.exclusive = true

		color_picker = ColorPicker.new()
		color_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
		color_picker_popup.add_child(color_picker)

		_header.add_child(color_picker_popup)


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var stylebox: StyleBoxFlat = base_stylebox.duplicate()
	var value: Variant = tree_item.get_thing().get_direct(get_property_path())
	if not value is Color:
		value = Color.BLACK
	stylebox.bg_color = value
	stylebox.border_color = stylebox.bg_color
	stylebox.border_color.a = 0.0
	tree_item.set_custom_stylebox(column_index, stylebox)
	if tree_item.get_button_count(column_index) == 0:
		var picker_icon: Texture2D = EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons")
		tree_item.add_button(column_index, picker_icon, 0, false, "Pick a new color")


func _on_button_clicked(tree_item: ThingTreeItem, column_index: int, _id: int, mouse_button_index: int):
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	color_picker.color = tree_item.get_thing().get_direct(get_property_path(), Color.BLACK)
	color_picker_popup.close_requested.connect(_on_popup_closed.bind(tree_item, column_index), CONNECT_ONE_SHOT)
	color_picker_popup.position = DisplayServer.mouse_get_position()
	color_picker_popup.popup()


func _on_popup_closed(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	thing.set(property, color_picker.color)
	update_column(tree_item, column_index)
