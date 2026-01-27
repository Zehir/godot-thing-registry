@tool
@abstract
class_name TreeValueAdapter
extends RefCounted

var _header: ThingTreeColumn


func _init(header: ThingTreeColumn) -> void:
	_header = header


func tree_item_callv(method: StringName, tree_item: ThingTreeItem, args: Array = []) -> Variant:
	if has_method(method):
		return (get(method) as Callable).bindv(args).call(tree_item)
	return null


func set_disabled(tree_item: ThingTreeItem, column_index: int) -> void:
	tree_item.set_custom_bg_color(column_index, Color.DIM_GRAY)
	tree_item.set_editable(column_index, false)
	tree_item.set_text(column_index, "")


@abstract
func _update_column(tree_item: ThingTreeItem, column_index: int) -> void


func update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	_update_column(tree_item, column_index)


func notify_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	_on_edited(tree_item, column_index)
	_update_column(tree_item, column_index)
	tree_item.get_thing().emit_changed()


@warning_ignore("unused_parameter")
func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	pass


func notify_button_clicked(tree_item: ThingTreeItem, column_index: int, id: int, mouse_button_index: int):
	_on_button_clicked(tree_item, column_index, id, mouse_button_index)


@warning_ignore("unused_parameter")
func _on_button_clicked(tree_item: ThingTreeItem, column_index: int, id: int, mouse_button_index: int):
	pass


func get_drag_data(tree_item: ThingTreeItem, column_index: int) -> Variant:
	return _get_drag_data(tree_item, column_index)


@warning_ignore("unused_parameter")
func _get_drag_data(tree_item: ThingTreeItem, column_index: int) -> Variant:
	return null


func can_drop_data(tree_item: ThingTreeItem, column_index: int, data: Variant) -> bool:
	return _can_drop_data(tree_item, column_index, data)


@warning_ignore("unused_parameter")
func _can_drop_data(tree_item: ThingTreeItem, column_index: int, data: Variant) -> bool:
	return false


func notify_drop_data(tree_item: ThingTreeItem, column_index: int, section: int, data: Variant):
	_on_drop_data(tree_item, column_index, section, data)


@warning_ignore("unused_parameter")
func _on_drop_data(tree_item: ThingTreeItem, column_index: int, section: int, data: Variant) -> void:
	pass
