@tool
class_name TreeValueAdapterAttributeResource
extends TreeValueAdapterAttribute


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_header.custom_minimum_size.x = 64.0
	#var property: Dictionary = header.get_property()

	#var picker := EditorResourcePicker.new()
	#picker.base_type = property.hint_string
	#prints("test", picker.get_allowed_types(), picker.edited_resource)
	#_header.add_child(picker)



func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	var resource: Resource = thing.get_inherited(property)

	tree_item.set_editable(column_index, true)
	tree_item.set_selectable(column_index, true)
	tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_CUSTOM)
	tree_item.set_custom_draw_callback(column_index, _custom_draw.bind(column_index))

	if resource is Resource:
		var editor_resource_preview: EditorResourcePreview = EditorInterface.get_resource_previewer()
		editor_resource_preview.queue_edited_resource_preview(resource, self, &"receive_preview", [tree_item, column_index])


	#var value: Variant = thing.get_direct(property, null)
	#if value is Texture2D:
		#tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_ICON)
		#tree_item.set_icon(column_index, value)
		#tree_item.set_icon_max_width(column_index, 16)
	#else:
		#tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_STRING)
		#tree_item.set_text(column_index, "")

#
#func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	#var thing: Thing = tree_item.get_thing()
	#var property: StringName = get_property_path()
	#thing.set(property, tree_item.get_text(column_index))


func receive_preview(_path: String, preview: Texture2D, thumbnail_preview: Texture2D, usedata: Array) -> void:
	var tree_item: ThingTreeItem = usedata[0]
	var column_index: int = usedata[1]
	var metadata: ResourceMetadata = tree_item.get_metadata(column_index)
	if not is_instance_valid(metadata):
		metadata = ResourceMetadata.new()

	if is_instance_valid(preview):
		metadata.update_preview(preview, thumbnail_preview)
		tree_item.set_metadata(column_index, metadata)
	else:
		tree_item.set_metadata(column_index, null)



func _custom_draw(tree_item: ThingTreeItem, rect: Rect2, column_index: int) -> void:
	var metadata: ResourceMetadata = tree_item.get_metadata(column_index)

	if not is_instance_valid(metadata):
		return

	# Réduire la largeur pour la place du dropdown

	rect.size.x -= 20

	tree_item.custom_minimum_height = 32 + 5

	# Obtenir la taille de la texture
	var texture_size = metadata.preview.get_size()
	#prints("texture_size", texture_size, "rect", rect)

	# Dessiner la texture avec filtrage nearest pour éviter le flou
	var tree: ThingTree = tree_item.get_tree()
	var target_rect: Rect2 = Rect2(rect.position, Vector2(32,32))

	# Sauvegarder et changer le filtre de la texture pour éviter le flou
	#tree.draw_texture_rect(metadata.preview, target_rect, false)
	RenderingServer.canvas_item_add_texture_rect(tree.get_custom_canvas_item(), target_rect, metadata.preview.get_rid())


class ResourceMetadata:
	var preview: Texture2D
	var thumbnail_preview: Texture2D


	func update_preview(p_preview: Texture2D, p_thumbnail_preview: Texture2D) -> void:
		preview = p_preview
		thumbnail_preview = p_thumbnail_preview
