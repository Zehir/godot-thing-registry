@tool
class_name TreeValueAdapterModule
extends TreeValueAdapter


func _init(header: ThingTreeColumnModule) -> void:
	super(header)

	_header.custom_minimum_size.x = 50.0
	var module: ThingModule = header.get_module()
	_header.text = module.get_display_name()
	_header.icon = module.get_icon()


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var module: ThingModule = _header.get_module()
	var thing = tree_item.get_thing()
	if thing.modules.has(module):
		tree_item.set_icon(column_index, module.get_icon())
		tree_item.set_text(column_index, "D")
		tree_item.set_tooltip_text(column_index, "This module is Defined on this Thing.")
	elif thing.has_module(module.get_instance_name()):
		tree_item.set_icon(column_index, module.get_icon())
		tree_item.set_text(column_index, "H")
		tree_item.set_tooltip_text(column_index, "This module is Herited from a parent Thing.")
