@tool
@abstract
class_name TreeValueAdapter
extends RefCounted

var _header: ThingTreeColumn


func _init(header: ThingTreeColumn) -> void:
	_header = header
	_header.custom_minimum_size.x = 200.0


func tree_item_callv(method: StringName, tree_item: ThingTreeItem, args: Array = []) -> Variant:
	if has_method(method):
		return (get(method) as Callable).bindv(args).call(tree_item)
	return null

@abstract
func update_column(tree_item: ThingTreeItem, column_index: int) -> void


func notify_edited(tree_item: ThingTreeItem, index: int) -> void:
	_on_edited(tree_item, index)


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
