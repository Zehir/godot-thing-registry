@tool
class_name TreeValueAdapterAttributeResource
extends TreeValueAdapterAttribute


func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_header.custom_minimum_size.x = 200.0
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
	tree_item.set_text_alignment(column_index, HORIZONTAL_ALIGNMENT_CENTER)

	var metadata: Metadata = Metadata.new()
	tree_item.set_metadata(column_index, metadata)

	if resource is Resource:
		var script: Variant = resource.get_script()
		var hint_string: String = script.get_global_name() if script is GDScript else resource.get_class()
		metadata.icon = _get_icon({
			"type": TYPE_OBJECT,
			"hint_string": hint_string
		})
		metadata.fallback = resource.resource_name
		if metadata.fallback.is_empty():
			metadata.fallback = hint_string

		var editor_resource_preview: EditorResourcePreview = EditorInterface.get_resource_previewer()
		editor_resource_preview.queue_edited_resource_preview(resource, self, &"receive_preview", [tree_item, column_index])


func receive_preview(_path: String, _preview: Texture2D, thumbnail_preview: Texture2D, usedata: Array) -> void:
	var tree_item: ThingTreeItem = usedata[0]
	var column_index: int = usedata[1]
	var metadata: Metadata = tree_item.get_metadata(column_index)
	if not is_instance_valid(metadata):
		return

	metadata.preview = thumbnail_preview
	tree_item.set_text(column_index, "" if is_instance_valid(thumbnail_preview) else metadata.fallback)


func _custom_draw(tree_item: ThingTreeItem, rect: Rect2, column_index: int) -> void:
	var metadata: Metadata = tree_item.get_metadata(column_index)

	if not is_instance_valid(metadata):
		return

	var tree: ThingTree = tree_item.get_tree()
	var canvas: RID = tree.get_custom_canvas_item()

	rect.size.x -= 20.0 # Space for right dropdown button

	if is_instance_valid(metadata.icon):
		var size: Vector2 = metadata.icon.get_size()
		RenderingServer.canvas_item_add_texture_rect(
			canvas,
			Rect2(rect.position, size),
			metadata.icon.get_rid()
		)
		var offset: float = size.x + 5.0
		rect.position.x += offset
		rect.size.x -= offset


	#RenderingServer.canvas_item_add_rect(canvas, rect, Color.WHITE)

	if metadata.has_texture():
		# Obtenir la taille de la texture
		var texture_size := metadata.preview.get_size()
		#prints("texture_size", texture_size, "rect", rect)

		var scale: float = 1.0
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			scale = min(1.0, rect.size.y / max(texture_size.x, texture_size.y))
		var draw_size := texture_size * scale

		var draw_pos := rect.position + Vector2((rect.size.x - draw_size.x) * 0.5, 0.0)

		RenderingServer.canvas_item_add_texture_rect(canvas, Rect2(draw_pos, draw_size), metadata.preview.get_rid())


class Metadata:
	var _preview: CanvasTexture
	var preview: Texture2D:
		set(value):
			_preview.diffuse_texture = value
		get():
			return _preview

	var icon: Texture2D
	var fallback: String

	func _init() -> void:
		_preview = CanvasTexture.new()
		_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS


	func has_texture() -> bool:
		return is_instance_valid(_preview.diffuse_texture)
