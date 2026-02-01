@tool
class_name TreeValueAdapterResource
extends TreeValueAdapter


func _init(header: ThingTreeColumn) -> void:
	super(header)

	_header.custom_minimum_size.x = 200.0
	_header.text = "Resource"
	_header.icon = EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons")


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	tree_item.set_icon(column_index, EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"))
	tree_item.set_text(column_index, tree_item.get_thing().get_display_name())
	tree_item.set_editable(column_index, false)


func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	ThingUtils.rename(tree_item.get_thing(), tree_item.get_text(column_index))
	update_column(tree_item, column_index)


func _get_drag_data(tree_item: ThingTreeItem, column_index: int) -> Variant:
	var thing: Thing = tree_item.get_thing()
	var preview: HBoxContainer = HBoxContainer.new()
	var icon: TextureRect = TextureRect.new()
	var icon_size: int = EditorInterface.get_editor_theme().get_constant("class_icon_size", "Editor")
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = tree_item.get_icon(column_index)
	preview.add_child(icon)
	var label: Label = Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = thing.resource_path.get_file()
	preview.add_child(label)
	tree_item.get_tree().set_drag_preview(preview)
	return {"type": "thing", "from": self, "things": [thing]}


func _can_drop_data(tree_item: ThingTreeItem, _column_index: int, data: Variant) -> bool:
	var tree: ThingTree = tree_item.get_tree()
	tree.drop_mode_flags = Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN
	if not _is_valid_thing_drop_data(data):
		return false
	var thing: Thing = tree_item.get_thing()
	for droped_thing in data.get("things"):
		if thing == droped_thing:
			return false
	return true


func _on_drop_data(tree_item: ThingTreeItem, _column_index: int, section: int, data: Variant) -> void:
	# To be safe but probably need needed because it's already checked in _can_drop_data.
	if not _is_valid_thing_drop_data(data):
		return

	var thing: Thing = tree_item.get_thing()

	match section:
		-1: # Before mean parent of dropped is the same as current
			for dropped: Thing in data.get("things"):
				ThingUtils.set_parent(dropped, thing.parent)
		0, 1: # On it or below bean as child of current
			for dropped: Thing in data.get("things"):
				ThingUtils.set_parent(dropped, thing)

	#TODO not rebuild the tree on thing dropped
	(tree_item.get_tree() as ThingTree).rebuild_tree.call_deferred()


func _is_valid_thing_drop_data(data: Variant) -> bool:
	return (data is Dictionary
		and data.get("type") == "thing"
		and data.get("from") == self
		and typeof(data.get("things")) == TYPE_ARRAY
	)
