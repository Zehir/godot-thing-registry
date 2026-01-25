@tool
class_name TreeValueAdapterAttributeString
extends TreeValueAdapterAttribute


func update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	if not thing.properties.has(property):
		#TODO fix, need to check if there is the module instead
		tree_item.set_custom_bg_color(column_index, Color.DIM_GRAY)
		return

	var value: String = thing.get(property)
	tree_item.set_text(column_index, value)
	tree_item.set_text_alignment(column_index, HORIZONTAL_ALIGNMENT_LEFT)
	tree_item.set_editable(column_index, true)

##
	##if _thing.property_can_revert(property):
		##add_button(
			##index,
			##EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons"),
			##Buttons.REVERT,
			##false,
			##"Revert value"
		##)
##
